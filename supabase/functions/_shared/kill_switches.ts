// _shared/kill_switches.ts
// -----------------------------------------------------------------------------
// Real env-flag kill switches for high-cost edge functions (HN-launch
// insurance per the launch runbook).
//
// Three flags, all default UNSET = current behavior (backward compatible).
// To activate, set the env var to the literal string "true" on the function
// (via `supabase secrets set FLAG=true --project-ref ...`) — anything else
// (unset, "false", "1", "yes") is treated as off.
//
// Flags:
//   CLAUDE_PROXY_MAINTENANCE
//     - Scope: claude-proxy
//     - Effect: returns 503 maintenance for ALL chat (auth + anon).
//     - Use when: the upstream model is degraded, or we need to drain.
//     - Trumps ANON_CHAT_DISABLED (more severe → earlier check).
//
//   ANON_CHAT_DISABLED
//     - Scope: claude-proxy
//     - Effect: returns 403 for anonymous demo callers only.
//       Paid / authenticated users continue normally.
//     - Use when: anon abuse spikes during HN launch and we want to keep
//       the paid product up while shutting the open demo.
//
//   CONTRACT_REVIEW_DISABLED
//     - Scope: contract-review + classify-contract
//     - Effect: returns 503 for both functions.
//     - Use when: planner JSON corruption, storage incident, or known bug.
//
// Tests live in `_tests/kill_switches.test.ts`. Add a new flag here, test it
// there, and document it in `/tmp/hn_launch_runbook.md`.
// -----------------------------------------------------------------------------

import { corsHeaders } from "./auth.ts";

/** Env-flag check — true only if the var equals the literal string "true". */
export function flagOn(name: string): boolean {
  return Deno.env.get(name) === "true";
}

/** 503 — maintenance window for claude-proxy. */
export function maintenanceResponse(): Response {
  return new Response(
    JSON.stringify({
      error: "maintenance",
      message: "Advocat AI is under maintenance. Back in a few minutes.",
    }),
    {
      status: 503,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
}

/** 403 — anonymous chat disabled (paid continues). */
export function anonDisabledResponse(): Response {
  return new Response(
    JSON.stringify({
      error: "anon_disabled",
      message: "Sign up to continue using Advocat AI",
    }),
    {
      status: 403,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
}

/** 503 — contract review mode disabled (both classify + review). */
export function contractReviewDisabledResponse(): Response {
  return new Response(
    JSON.stringify({
      error: "contract_review_disabled",
      message:
        "Contract Review temporarily unavailable. Try again in a few minutes.",
    }),
    {
      status: 503,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
}
