// gateway.ts — the single mandatory chokepoint for ALL outbound LLM text.
// ----------------------------------------------------------------------------
// Every function that sends user/case text to an external LLM (Anthropic,
// OpenAI, embeddings, Haiku-scrub, …) MUST run its payload through
// prepareEgress() first. This is the one place that:
//   1. pseudonymizes PII into reversible PERSON_N / EMAIL_N / … tokens,
//   2. optionally escalates name-coverage to a Haiku pass,
//   3. VALIDATES the result and FAILS CLOSED for special-category (Art. 9)
//      data if a structured identifier survived,
//   4. returns the scrubbed text + reversible map + an audit manifest
//      (no real values) for the access ledger.
//
// Why a prepare-step and not a full proxy: the ~30 call sites keep their own
// provider/transport logic (streaming, tools, embeddings shapes differ wildly)
// — forcing them all through one transport would be a massive, risky rewrite
// mid-freeze. A mandatory prepare-step gives us the security guarantee (no raw
// PII leaves) with a minimal, incremental wiring surface, and a CI guard
// (see ci_guard) enforces that no site calls an LLM host without it.
//
// Sensitivity tiers (caller declares):
//   "special"  — Art. 9 case data (names, police/Migri/court facts). Validator
//                failure => THROW (block the call). Names => Haiku pass on.
//   "standard" — generic legal Q&A with possible incidental PII. Validator
//                failure => still scrub best-effort but LOG loudly; does not
//                throw (avoids breaking generic chat on a false-positive).
//   "corpus"   — public statute/citation text, no user PII expected. Scrub is
//                a cheap no-op floor; never throws.
// ----------------------------------------------------------------------------

import { pseudonymize, rehydrate } from "./pseudonymizer.ts";
import { haikuScrub } from "../pii_scrubber.ts";
import { validateNoPii } from "./validator.ts";

export type Sensitivity = "special" | "standard" | "corpus";

export class EgressPiiLeakError extends Error {
  readonly leaks: Record<string, number>;
  constructor(leaks: Record<string, number>) {
    super(
      `egress blocked: structured PII survived scrub for special-category ` +
        `data (${Object.keys(leaks).join(", ")})`
    );
    this.name = "EgressPiiLeakError";
    this.leaks = leaks;
  }
}

export interface PrepareEgressOpts {
  text: string;
  sensitivity: Sensitivity;
  /** Destination, for the manifest (e.g. "anthropic:claude-proxy"). */
  destination: string;
  /** Anthropic key to enable the Haiku name-pass. Omit => regex-only floor. */
  anthropicApiKey?: string;
  /** Force the Haiku name pass on/off. Default: on for "special". */
  haikuPass?: boolean;
  fetcher?: typeof fetch;
}

export interface EgressManifest {
  destination: string;
  sensitivity: Sensitivity;
  /** tag -> count of tokens emitted (NO real values). */
  redactions: Record<string, number>;
  haiku_pass: boolean;
  validated_clean: boolean;
  /** SHA-256 of the scrubbed payload — proves what left, leaks nothing. */
  payload_sha256: string;
}

export interface PrepareEgressResult {
  /** PII-scrubbed text safe to send to the external LLM. */
  text: string;
  /** token -> real value; use rehydrateOutput() on the LLM response. */
  map: Record<string, string>;
  manifest: EgressManifest;
}

async function sha256Hex(s: string): Promise<string> {
  const data = new TextEncoder().encode(s);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * Prepare a payload for an external LLM. Returns scrubbed text + reversible
 * map + manifest. Throws EgressPiiLeakError for "special" data that still
 * contains structured PII after scrubbing (fail-closed).
 */
export async function prepareEgress(
  opts: PrepareEgressOpts
): Promise<PrepareEgressResult> {
  const { text, sensitivity, destination } = opts;

  // 1. Deterministic reversible pseudonymization (the floor).
  const pseudo = pseudonymize(text);
  let scrubbed = pseudo.text;

  // 2. Optional Haiku name-pass. On by default for special-category data,
  //    where free-form names the regex missed are the main residual risk.
  const wantHaiku = opts.haikuPass ?? sensitivity === "special";
  let haikuRan = false;
  if (wantHaiku && opts.anthropicApiKey) {
    const afterHaiku = await haikuScrub({
      text: scrubbed,
      anthropicApiKey: opts.anthropicApiKey,
      fetcher: opts.fetcher,
    });
    // haikuScrub is fail-open by design (returns input on error). We treat a
    // no-op result as "haiku did not run" so the validator decides the gate.
    haikuRan = afterHaiku !== scrubbed;
    scrubbed = afterHaiku;
  }

  // 3. Deterministic validation. Fail CLOSED for special-category data.
  const v = validateNoPii(scrubbed);
  if (!v.clean && sensitivity === "special") {
    // Do NOT let raw Art. 9 identifiers reach the LLM.
    throw new EgressPiiLeakError(v.leaks);
  }
  if (!v.clean && sensitivity === "standard") {
    console.warn(
      `[egress] residual PII after scrub (standard tier, not blocked): ` +
        `${Object.keys(v.leaks).join(", ")} -> ${destination}`
    );
  }

  const manifest: EgressManifest = {
    destination,
    sensitivity,
    redactions: pseudo.counts,
    haiku_pass: haikuRan,
    validated_clean: v.clean,
    payload_sha256: await sha256Hex(scrubbed),
  };

  return { text: scrubbed, map: pseudo.map, manifest };
}

/** Re-hydrate an LLM response (e.g. a generated draft) with the real values. */
export function rehydrateOutput(
  output: string,
  map: Record<string, string>
): string {
  return rehydrate(output, map);
}
