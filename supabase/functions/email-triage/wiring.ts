// email-triage/wiring.ts
// -----------------------------------------------------------------------------
// Carry-over wiring helpers for the D4 triage pipeline. Pulled out of
// `index.ts` so the unit tests can import them WITHOUT booting the
// `serve()` HTTP listener at module-eval time. (Importing index.ts in a
// Deno test triggers the listener and the test runner errors out on
// `Requires net access to "0.0.0.0:8000"`.)
//
// Each function is small, dependency-injected via the Supabase client,
// and soft-fails on error so the triage critical path is never blocked
// by an outage in a sidecar (RAG, memory, case timeline).
// -----------------------------------------------------------------------------

import type { MemoryBlock } from "./triage_logic.ts";
import type { MemoryUpdate } from "./parse_blocks.ts";

/**
 * Carry-over Task 1: build the MemoryBlock for a user.
 *
 * Sources (per OPERATOR_PROMPT v1 §3.7, ≤ ~2 KB total):
 *   - own_counsel_emails           ← user_settings.own_counsel_emails
 *   - dead_addresses               ← user_settings.dead_address_corrections
 *                                    (jsonb {from: to} → array of pairs)
 *   - identity_markers / known_…   ← user_ai_memory (Tier 2 — keys
 *                                    `name`, `known_party`, `discussed_topic`)
 *   - recent_owner_feedback        ← email_triage_results.user_action over
 *                                    the last 7 days (capped at 5)
 *
 * Soft-fail to a stable empty shape on any error — the model has a
 * stable schema regardless of DB availability.
 */
export async function loadMemoryBlockReal(
  // deno-lint-ignore no-explicit-any
  sb: any,
  userId: string,
): Promise<MemoryBlock> {
  const empty: MemoryBlock = {
    identity_markers: {},
    dead_addresses: [],
    own_counsel_emails: [],
    known_privileged_individuals: [],
    relations: null,
    recent_owner_feedback: undefined,
  };
  if (!userId) return empty;

  type SettingsRow = {
    own_counsel_emails?: string[] | null;
    dead_address_corrections?: Record<string, unknown> | null;
  };
  type MemoryRow = {
    key: string;
    value: { text?: string } | null;
    confidence?: number;
  };

  // Run the reads in parallel — none of them depend on each other.
  // Note: each is wrapped via try/catch (loadRecentOwnerFeedback) or
  // safeQuery so a single throw doesn't reject the Promise.all.
  let settingsRes: SettingsRow | null = null;
  let memoryRes: MemoryRow[] | null = null;
  let feedbackRes: string | undefined;
  try {
    const [s, m, f] = await Promise.all([
      safeQuery<SettingsRow | null>(sb
        .from("user_settings")
        .select("own_counsel_emails, dead_address_corrections")
        .eq("user_id", userId)
        .maybeSingle()),
      safeQuery<MemoryRow[] | null>(sb
        .from("user_ai_memory")
        .select("key, value, confidence")
        .eq("user_id", userId)
        .in("key", ["name", "known_party", "discussed_topic"])
        .order("confidence", { ascending: false })
        .limit(20)),
      loadRecentOwnerFeedback(sb, userId),
    ]);
    settingsRes = s;
    memoryRes = m;
    feedbackRes = f;
  } catch (_e) {
    return empty;
  }

  // own_counsel_emails — array<text>, dedupe + lowercase.
  const ownCounsel: string[] = Array.from(
    new Set(
      ((settingsRes?.own_counsel_emails as string[] | null) ?? [])
        .map((s) => String(s ?? "").trim().toLowerCase())
        .filter((s) => s.length > 0),
    ),
  );

  // dead_addresses — jsonb {from: to} → array<{from, to}>.
  const deadAddresses: Array<{ from: string; to: string }> = [];
  const dac = settingsRes?.dead_address_corrections;
  if (dac && typeof dac === "object" && !Array.isArray(dac)) {
    for (const [from, to] of Object.entries(dac as Record<string, unknown>)) {
      if (typeof from === "string" && typeof to === "string" &&
          from.length > 0 && to.length > 0) {
        deadAddresses.push({ from, to });
      }
    }
  }

  // identity_markers — flatten user_ai_memory rows by key.
  const identityMarkers: Record<string, string> = {};
  const knownPrivileged: string[] = [];
  for (const row of (memoryRes ?? []) as MemoryRow[]) {
    const text = row?.value?.text;
    if (!text) continue;
    if (row.key === "name" && !identityMarkers["name"]) {
      identityMarkers["name"] = String(text).slice(0, 200);
    } else if (row.key === "known_party") {
      // Surface as known_privileged_individuals when the text mentions a
      // role that signals legal-counsel context (lawyer/attorney/advokaat).
      const lower = String(text).toLowerCase();
      if (/(lawyer|attorney|advokaat|asianajaja|advokaadi|адвокат)/.test(lower)
          && knownPrivileged.length < 8) {
        knownPrivileged.push(text);
      }
    }
  }

  return {
    identity_markers: identityMarkers,
    dead_addresses: deadAddresses,
    own_counsel_emails: ownCounsel,
    known_privileged_individuals: knownPrivileged,
    relations: null,
    recent_owner_feedback: feedbackRes,
  };
}

async function loadRecentOwnerFeedback(
  // deno-lint-ignore no-explicit-any
  sb: any,
  userId: string,
): Promise<string | undefined> {
  // Last 7 days of explicit user_action on triage rows.
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 3600 * 1000)
    .toISOString();
  try {
    const { data, error } = await sb
      .from("email_triage_results")
      .select("created_at, user_action, draft_subject, draft_to")
      .eq("user_id", userId)
      .gte("created_at", sevenDaysAgo)
      .not("user_action", "is", null)
      .order("created_at", { ascending: false })
      .limit(5);
    if (error || !Array.isArray(data) || data.length === 0) return undefined;
    const lines = data.map((row: Record<string, unknown>) => {
      const date = String(row.created_at ?? "").slice(0, 10);
      const recipient = Array.isArray(row.draft_to) && row.draft_to.length > 0
        ? String(row.draft_to[0])
        : "(no recipient)";
      const verdict = String(row.user_action ?? "");
      return `${date} → ${recipient}: ${verdict}`;
    });
    return lines.join("; ");
  } catch (_e) {
    return undefined;
  }
}

/**
 * Carry-over Task 2: invoke the existing `law-search` edge fn.
 *
 * Wire-format ref: supabase/functions/law-search/index.ts header.
 * Soft-fail to `[]` on ANY error so the triage critical path is never
 * blocked by RAG outages.
 */
export async function loadLawSearchReal(
  // deno-lint-ignore no-explicit-any
  sb: any,
  query: string,
): Promise<unknown> {
  if (!query || query.trim().length === 0) return [];
  try {
    const { data, error } = await sb.functions.invoke("law-search", {
      body: {
        query: query.trim().slice(0, 1500),
        // Default jurisdiction → Estonian. Caller passes
        // active_case.jurisdiction via extractLegalKeywords-derived
        // context if it's set; in the carry-over wiring we keep the
        // default conservative — the law-search fn validates lang.
        lang: "et",
        match_count: 5,
      },
    });
    if (error) return [];
    if (data && typeof data === "object" && Array.isArray(data.chunks)) {
      // Return only the fields the model actually consumes — keep the
      // injected context tight (§3.7 budget).
      return data.chunks.slice(0, 5).map((c: Record<string, unknown>) => ({
        act_slug: c.act_slug,
        paragraph: c.paragraph,
        title: c.title,
        body: typeof c.body === "string"
          ? (c.body as string).slice(0, 800)
          : c.body,
        source_url: c.source_url,
        similarity: c.similarity,
      }));
    }
    return [];
  } catch (_e) {
    return [];
  }
}

/**
 * Carry-over Task 3: append a typed event to `user_cases.timeline`
 * (jsonb), with idempotency guard.
 *
 * Idempotency hash: `(case_id, type, ref_email_id, occurred_at)`. If a
 * timeline entry with the same hash already exists, the write is a
 * no-op — re-running triage on the same thread does not duplicate
 * events.
 */
export async function appendCaseEventReal(
  // deno-lint-ignore no-explicit-any
  sb: any,
  args: {
    user_id: string;
    case_id: string | null;
    type: string;
    payload: Record<string, unknown>;
  },
): Promise<void> {
  if (!args.case_id) return;
  try {
    const { data: caseRow, error } = await sb
      .from("user_cases")
      .select("timeline")
      .eq("id", args.case_id)
      .eq("user_id", args.user_id)
      .maybeSingle();
    if (error || !caseRow) return;
    const tl = Array.isArray(caseRow.timeline) ? caseRow.timeline : [];
    const occurredAt = new Date().toISOString();
    const refEmailId = String(args.payload?.thread_id ?? "");
    const hash = `${args.case_id}|${args.type}|${refEmailId}|${occurredAt.slice(0, 10)}`;
    // Skip if same-day same-thread same-type already there.
    const dup = (tl as Array<Record<string, unknown>>).some((entry) => {
      const eHash = `${args.case_id}|${entry.type}|${entry.ref_email_id ?? ""}|${
        String(entry.occurred_at ?? entry.ts ?? "").slice(0, 10)
      }`;
      return eHash === hash;
    });
    if (dup) return;
    tl.push({
      type: args.type,
      thread_id: refEmailId || null,
      ref_email_id: refEmailId || null,
      summary: typeof args.payload.summary === "string"
        ? args.payload.summary
        : null,
      metadata: {
        inbound_type: args.payload.inbound ?? null,
        tracks: args.payload.tracks ?? null,
        deadlines: args.payload.deadlines ?? null,
      },
      occurred_at: occurredAt,
      // Legacy `ts` kept for backwards compat with existing readers
      // that still use the case-auto-patch shape.
      ts: occurredAt,
    });
    await sb
      .from("user_cases")
      .update({ timeline: tl })
      .eq("id", args.case_id)
      .eq("user_id", args.user_id);
  } catch (_e) { /* swallow */ }
}

/**
 * Carry-over Task 5: apply `<memory_update>` entries from the parsed
 * Sonnet output back to `user_settings.own_counsel_emails`.
 *
 * Match keys (case-insensitive):
 *   - "own_counsel_email"         (singular, primary)
 *   - "own_counsel_emails"        (plural — alias)
 *   - "confirmed_attorney_email"  (alternative spelling some prompt
 *                                  variants emit)
 *
 * Confidence gate: only `high` or `medium` confidence updates are
 * applied — a `low`-confidence guess from the model must not promote a
 * stranger to own-counsel status.
 */
export async function applyMemoryUpdatesReal(
  // deno-lint-ignore no-explicit-any
  sb: any,
  userId: string,
  updates: MemoryUpdate[],
): Promise<void> {
  if (!userId || !Array.isArray(updates) || updates.length === 0) return;

  const newEmails: string[] = [];
  for (const u of updates) {
    const key = (u.key ?? "").toLowerCase().trim();
    const isOwnCounsel =
      key === "own_counsel_email" ||
      key === "own_counsel_emails" ||
      key === "confirmed_attorney_email";
    if (!isOwnCounsel) continue;
    if (u.confidence !== "high" && u.confidence !== "medium") continue;
    const value = (u.value ?? "").trim().toLowerCase();
    if (!isLikelyEmail(value)) continue;
    newEmails.push(value);
  }
  if (newEmails.length === 0) return;

  try {
    // Read existing row (may not exist).
    const { data: existing } = await sb
      .from("user_settings")
      .select("user_id, own_counsel_emails")
      .eq("user_id", userId)
      .maybeSingle();
    const current: string[] = Array.isArray(existing?.own_counsel_emails)
      ? existing!.own_counsel_emails as string[]
      : [];
    const merged = Array.from(new Set([
      ...current.map((s) => String(s ?? "").trim().toLowerCase())
        .filter((s) => s.length > 0),
      ...newEmails,
    ]));
    if (merged.length === current.length &&
        merged.every((e) => current.includes(e))) {
      // No-op: nothing new to write.
      return;
    }
    if (existing?.user_id) {
      await sb
        .from("user_settings")
        .update({ own_counsel_emails: merged })
        .eq("user_id", userId);
    } else {
      await sb
        .from("user_settings")
        .insert({ user_id: userId, own_counsel_emails: merged });
    }
  } catch (_e) { /* swallow */ }
}

function isLikelyEmail(s: string): boolean {
  // Conservative — anchor on `@`, require a dot in the domain, no
  // whitespace, length 5..254 (RFC 3696 practical bound).
  if (s.length < 5 || s.length > 254) return false;
  if (/\s/.test(s)) return false;
  const at = s.indexOf("@");
  if (at <= 0 || at === s.length - 1) return false;
  const domain = s.slice(at + 1);
  if (!domain.includes(".")) return false;
  return true;
}

/** Wrap a Supabase query promise so a thrown error becomes `null`. */
async function safeQuery<T>(
  // deno-lint-ignore no-explicit-any
  p: PromiseLike<{ data: any; error: unknown }>,
): Promise<T | null> {
  try {
    const { data, error } = await p;
    if (error) return null;
    return data as T;
  } catch (_e) {
    return null;
  }
}
