# Phase 2 Pkg 6 — Planner + Executor + Self-Critique

Status: shipped 2026-05-07. Default OFF; Pro-only opt-in.

## 1. Goal

Replace the single-shot legal answer with a three-pass loop that plans the
question, drafts a grounded answer with Pkg 2 citation markers, and self-
critiques for material gaps. One regeneration when the critique flags a
gap. Trade-off: +3-6s latency and 3-4× API cost on legal turns, in
exchange for noticeably tighter coverage of sub-questions and counter-
arguments — the kind of failure mode evals (Pkg 8) flag most often.

## 2. Pass shapes (binding)

| Pass     | Model  | Temperature | Max tokens | Output                                |
|----------|--------|-------------|------------|---------------------------------------|
| Planner  | Sonnet | 0.0         | 500        | `<plan>` XML with sub-questions, counter-args, evidence gaps |
| Executor | Sonnet | 0.2         | 4096       | Draft with `[[ref:slug:para]]` markers (Pkg 2 syntax) |
| Critique | Haiku  | 0.0         | 300        | `<critique>{material_gap, issues}` JSON |
| Regen    | Sonnet | 0.2         | 4096       | (Optional) Re-execute with critique injected — **cap = 1 per turn** |

The regen cap is enforced in code (`MAX_REGENERATIONS = 1` in
`legal_planner.ts`); a future change cannot accidentally make the loop
self-recur.

## 3. Trigger gate (3-AND)

The planner only runs when **all three** are true:

1. `ClaudeService.looksLegalish(text)` returns true (existing detector).
2. User is on Pro plan.
3. `user_settings.enable_planner_for_legal_turns` is true (default OFF).

Pure function `shouldRouteToPlanner` in `lib/services/legal_planner.dart`
pins the gate so future re-orderings cannot drift from the spec. The
SharedPreferences mirror (`advocat_planner_enabled_v1`) lets the chat
orchestrator decide synchronously without a Supabase round-trip per turn.

## 4. Wire protocol

The Flutter client adds `mode: "legal_planner"` to the existing claude-
proxy POST. The proxy:

1. Strips `mode` before any forwarding (defence-in-depth).
2. Refuses to enable the planner on streaming requests or for anon
   callers — degrades silently to single-pass.
3. Runs `runLegalPlannerLoop` from `_shared/legal_planner.ts`.
4. Runs the **existing Pkg 2 verifier** (`citation_grounder`) on the
   final draft. Reuse is unconditional — invented citations get a
   downgraded badge regardless of which path produced them.
5. Persists the trace via service-role upsert (`message_id`-keyed).
6. Returns an augmented JSON shape: `{mode, content[], citations[],
   message_id?, planner: {regenerated_once, latency_ms, cost_cents}}`.

## 5. UPL footer (Pkg 0 reuse)

The Pkg 0 UPL footer is already baked into `system_prompts.dart` for
every assistant turn. The planner's per-pass instructions are appended
**below** the base prompt, so the footer guidance stays in scope on
both planner and executor passes. Tests pin that the executor system
prompt contains the base prompt verbatim.

## 6. Storage

`chat_planner_traces` (migration `20260507_16_planner_traces.sql`):

- Owner-only RLS via JOIN to `chat_messages.user_id` (no denormalised
  `user_id` column — the join keeps ownership consistent if a message
  is ever reassigned).
- No INSERT/UPDATE/DELETE policies — service-role writes only. This
  keeps `regenerated_once` and `cost_cents` trustworthy.
- `UNIQUE INDEX` on `message_id` so regen overwrites in place via the
  service-role upsert (`Prefer: resolution=merge-duplicates`).
- `CHECK` on `latency_ms >= 0` and `cost_cents >= 0`.
- RPC `planner_trace(uuid)`: SECURITY DEFINER, explicit `search_path`,
  `auth.uid()` null guard, owner re-check via `chat_messages` join.

## 7. UI

`PlannerTrail` widget (`lib/features/chat/widgets/planner_trail.dart`)
is a sibling of the existing `ReasoningTrail`. ReasoningTrail handles
the live-streaming pill; PlannerTrail renders the post-loop trace card
underneath the assistant message: header line ("3 passes + 1 regen ·
4s"), Plan section (sub-questions + counter-args + evidence gaps),
Critique section ("clean" or "material gap" + issues bullets).

Settings toggle: a single new tile "Smart legal reasoning" under
Notifications, backed by `plannerEnabledProvider` in
`lib/services/legal_planner.dart`. SharedPreferences-backed; Pro check
is enforced at the chat-path gate, not on the toggle itself (so the
user can pre-flip it before upgrading).

## 8. Failure modes

- **Planner pass throws** → proxy logs and falls back to single-pass.
  User still gets an answer.
- **Trace persist throws** → `runLegalPlannerLoop` swallows + logs.
  User reply unaffected.
- **Critique JSON broken** → heuristic fallback: regex for
  `material_gap.*true`. Conservative — over-triggers regen rather
  than under.
- **Streaming + planner mode** → planner mode wins, response is
  non-streaming. The existing `ReasoningTrail` does NOT mount;
  `PlannerTrail` mounts under the message once it lands.

## 9. Cost model

Approx per-turn cost (auth user, 4-pass worst case):

- Planner   ~500 in / 500 out Sonnet  ≈ $0.0023
- Executor  ~3K in / 1K out Sonnet    ≈ $0.0240
- Critique  ~500 in / 200 out Haiku   ≈ $0.0006
- Regen     ~3K in / 1K out Sonnet    ≈ $0.0240
- **Total**: ~$0.05/turn (vs. ~$0.024 single-pass), ~2× the cost.

Recorded in `chat_planner_traces.cost_cents` for the Pkg 8 eval suite
to bucket runs. Not user-facing.

## 10. Tests pinned

- `_shared/__tests__/legal_planner_test.ts` — 14 Deno tests for parsers,
  per-pass model+budget contract, regen-once guard, trace writer, error
  swallow.
- `test/services/legal_planner_test.dart` — gate semantics +
  augmented-JSON unwrapping (12 tests).
- `test/features/chat/widgets/planner_trail_test.dart` — widget
  contract (7 tests).
- `test/contract/planner_traces_migration_contract_test.dart` —
  migration idempotency, RLS join, UNIQUE on message_id, RPC security
  invariants (16 tests).
