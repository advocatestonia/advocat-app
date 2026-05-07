// citation_persistence.ts — Phase 2 Pkg 2 closeout (server-side persistence).
// -----------------------------------------------------------------------------
// Pure-ish module that turns verifier output (Citation[]) into the row shape
// expected by `public.chat_message_citations`. The HTTP/DB I/O is wired in
// claude-proxy/index.ts; this module owns ONLY the row-building rules so the
// shape is unit-testable without spinning up Supabase.
//
// Design reference:
//   docs/architecture/phase2-pkg2-citations.md §5 (DB schema) + §6 (Flutter
//   contract / "prefer server-side to avoid race with offline queue").
//
// Migration:
//   supabase/migrations/20260507080000_message_citations.sql           — table
//   supabase/migrations/20260507090000_citations_position_idempotency.sql
//                                                                     — unique
//                                                                     idx
//
// Idempotency contract:
//   The unique index on (message_id, position) lets the writer use
//   `upsert(rows, { onConflict: 'message_id,position', ignoreDuplicates: true })`
//   so a retried turn (same UUID) doesn't double-insert. `position` is the
//   first-occurrence index of the marker in the reply (verifier already
//   emits citations in first-occurrence order — see verifyCitations).
//
// Trust boundary:
//   Caller must have authenticated the user and resolved their case_id +
//   user_id from server-side state (NOT from client body) before calling
//   buildCitationRows. The fields go straight into the DB; trusting client
//   `case_id` would let an attacker mint citations against another user's
//   case if RLS were ever weakened.
// -----------------------------------------------------------------------------

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { Citation } from "../_shared/citation_grounder.ts";

/** One row destined for `public.chat_message_citations`. Field names match
 *  the column names in 20260507080000_message_citations.sql exactly so the row
 *  goes straight to .insert/.upsert without further translation. */
export interface CitationRow {
  message_id: string;
  user_id: string;
  case_id: string;
  marker: string;
  status: "verified" | "unverified" | "historical";
  chunk_id: string | null;
  act_slug: string;
  paragraph: string;
  act_name: string | null;
  title: string | null;
  snippet: string | null;
  source_url: string | null;
  jurisdiction: string | null;
  in_force: boolean | null;
  occurrences: number;
  position: number;
}

/** Input bundle for buildCitationRows. The trust-boundary fields
 *  (message_id, user_id, case_id) come from server-side state — NOT the
 *  client request body — so the row can never lie about ownership. */
export interface BuildRowsInput {
  /** UUID of the assistant chat_messages row this batch belongs to. */
  message_id: string;
  /** Owner of the chat_messages row (resolved from authenticated session). */
  user_id: string;
  /** Owner's case (resolved server-side; never trust client). */
  case_id: string;
  /** Verifier output for this turn. May be empty — the function returns []
   *  in that case so the caller can short-circuit the DB write. */
  citations: ReadonlyArray<Citation>;
}

/** Build the row array. Pure function — no I/O. The order of citations is
 *  preserved (verifier already emits first-occurrence order), and `position`
 *  is the index in the input array. Empty input → empty output (lets the
 *  caller skip the DB round-trip).
 *
 *  Design choice: we DO write rows for `unverified` and `historical`
 *  statuses. The whole point of the citations table is to score grounding
 *  precision over time (Pkg 8 eval), and a "model fabricated a marker"
 *  signal is just as valuable as a verified hit. */
export function buildCitationRows(input: BuildRowsInput): CitationRow[] {
  if (!input.message_id || !input.user_id || !input.case_id) {
    // Belt-and-suspenders: caller must populate the trust-boundary fields.
    // We refuse to build rows that would FK-fail or RLS-fail downstream.
    return [];
  }
  if (!input.citations || input.citations.length === 0) return [];

  const rows: CitationRow[] = [];
  for (let i = 0; i < input.citations.length; i++) {
    const c = input.citations[i];
    rows.push({
      message_id: input.message_id,
      user_id: input.user_id,
      case_id: input.case_id,
      marker: c.marker,
      status: c.status,
      chunk_id: c.chunk_id,
      act_slug: c.act_slug,
      paragraph: c.paragraph,
      act_name: c.act_name,
      title: c.title,
      snippet: c.snippet,
      source_url: c.source_url,
      jurisdiction: c.jurisdiction,
      in_force: c.in_force,
      occurrences: c.occurrences,
      position: i,
    });
  }
  return rows;
}

/** Validate a UUID v4-ish string. Same regex shape as the rest of the
 *  codebase (see active_case_injection.ts::isValidCaseId). Used by the
 *  proxy to refuse malformed `body.message_id` before any DB call. */
const UUID_RE =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

export function isValidMessageId(id: unknown): id is string {
  return typeof id === "string" && UUID_RE.test(id);
}

// =============================================================================
// I/O seam — persistCitations
// =============================================================================

/**
 * Persist a verified-turn citations batch to `public.chat_message_citations`.
 *
 * Service-role only. RLS on the table forbids INSERT for anon + authenticated
 * (see migration _08), so the writer MUST use the service-role key. Failure
 * to persist is logged but never thrown — the response payload still carries
 * `citations[]` so the chat UI renders correctly. Persistence is a
 * best-effort durable record, not a blocking dependency for chat.
 *
 * Idempotency: relies on the unique index `(message_id, position)` from
 * migration _09. Retries with the same message_id+position become no-ops via
 * `.upsert(..., { onConflict: 'message_id,position', ignoreDuplicates: true })`.
 *
 * Returns the count of rows the writer attempted to push (NOT the count
 * actually inserted — supabase-js does not surface affected-row counts on
 * upsert with ignoreDuplicates). Useful only as a smoke signal for tests.
 */
export async function persistCitations(
  rows: ReadonlyArray<CitationRow>,
  opts: { supabaseUrl: string; serviceRoleKey: string },
): Promise<number> {
  if (rows.length === 0) return 0;
  if (!opts.supabaseUrl || !opts.serviceRoleKey) {
    console.warn(
      "claude-proxy: persistCitations skipped — missing service-role config",
    );
    return 0;
  }
  try {
    const supabase = createClient(opts.supabaseUrl, opts.serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { error } = await supabase
      .from("chat_message_citations")
      .upsert(rows as CitationRow[], {
        onConflict: "message_id,position",
        ignoreDuplicates: true,
      });
    if (error) {
      console.warn(
        `claude-proxy: persistCitations error: ${
          String(error.message ?? error).slice(0, 200)
        }`,
      );
      return 0;
    }
    return rows.length;
  } catch (e) {
    console.warn(
      `claude-proxy: persistCitations threw: ${String(e).slice(0, 200)}`,
    );
    return 0;
  }
}
