// consilium_roles/router.ts — selects 4-6 roles for a given case context.
// -----------------------------------------------------------------------------
// Pure function; no I/O. Memory injection happens later in compileRoles().
//
// Selection algorithm:
//   1. Filter DOMAIN_EXPERTS by applicableWhen(ctx) → pick 2-3 with the
//      best match score (caseType+jurisdiction match wins over keyword match).
//   2. Filter STRATEGIC_POSITIONS by applicableWhen(ctx) → pick 2-3 with
//      the best match score plus mandatory inclusions (deadline if hard,
//      silent-concession if opposing correspondence, 23-test if complex).
//   3. Return 4-6 roles total. If no domain expert matches, fall back to
//      legacy 6-role roster (caller handles this).
// -----------------------------------------------------------------------------

import type {
  CaseContext,
  CompiledRole,
  DomainExpert,
  RoleDef,
  StrategicPosition,
} from "./types.ts";
import { pickName } from "./types.ts";
import { DOMAIN_EXPERTS } from "./domain.ts";
import { STRATEGIC_POSITIONS } from "./strategic.ts";
import { loadMemoryHooks, type MemoryReader } from "./memory.ts";

// ─── Selection result type ───────────────────────────────────────────────────

export interface RoleSelection {
  /** Whether the router could pick domain experts. If false, caller should
   *  fall back to the legacy 6 generic roles. */
  hasDomainMatch: boolean;
  /** Selected DomainExperts in priority order. */
  domainRoles: ReadonlyArray<DomainExpert>;
  /** Selected StrategicPositions in priority order. */
  strategicRoles: ReadonlyArray<StrategicPosition>;
}

// ─── Scoring helpers ─────────────────────────────────────────────────────────

function scoreDomain(d: DomainExpert, ctx: CaseContext): number {
  let score = 0;
  // applicableWhen is binary — if false, skip outright
  if (!d.applicableWhen(ctx)) return -1;
  // jurisdiction match is the highest signal
  if (ctx.jurisdiction && d.id.endsWith(`-${ctx.jurisdiction.toLowerCase()}`)) {
    score += 10;
  }
  // primary case type match outranks secondary
  if (ctx.caseType && d.id.startsWith(ctx.caseType)) score += 5;
  // secondary case type match — lower weight than primary
  if (ctx.secondaryTypes?.some((t) => d.id.startsWith(t))) score += 3;
  // keyword nudge
  if (ctx.keywords && ctx.keywords.length > 0) score += 1;
  return score;
}

function scoreStrategic(s: StrategicPosition, ctx: CaseContext): number {
  if (!s.applicableWhen(ctx)) return -1;
  let score = 0;
  // Hard-deadline cases prioritise deadline-strategist
  if (ctx.hasHardDeadline && s.id === "deadline-strategist") score += 10;
  // Opposing correspondence prioritises silent-concession
  if (ctx.hasOpposingCorrespondence && s.id === "silent-concession") score += 10;
  // Complex cases get long-game and 23-test
  const complexity = ctx.complexity ?? 0;
  if (complexity >= 7 && (s.id === "long-game" || s.id === "23-test")) score += 5;
  // decision-maker-risk and procedural-posture are useful almost always
  if (s.id === "decision-maker-risk") score += 3;
  if (s.id === "procedural-posture") score += 2;
  // tie-breaker
  score += 1;
  return score;
}

// ─── Public router ──────────────────────────────────────────────────────────

/** Pure router. No I/O. Returns 2-3 domain + 2-3 strategic, total 4-6 roles. */
export function selectConsiliumRoles(ctx: CaseContext): RoleSelection {
  // ── Domain selection ────────────────────────────────────────────────────
  const domainScored = DOMAIN_EXPERTS
    .map((d) => ({ d, s: scoreDomain(d, ctx) }))
    .filter((x) => x.s >= 0)
    .sort((a, b) => b.s - a.s);

  const domainRoles = domainScored.slice(0, 3).map((x) => x.d);
  const hasDomainMatch = domainRoles.length > 0;

  // ── Strategic selection ─────────────────────────────────────────────────
  const strategicScored = STRATEGIC_POSITIONS
    .map((s) => ({ s, score: scoreStrategic(s, ctx) }))
    .filter((x) => x.score >= 0)
    .sort((a, b) => b.score - a.score);

  // Always at least 2 strategic roles, up to 3
  let strategicRoles = strategicScored.slice(0, 3).map((x) => x.s);

  // Floor at 2 strategics if any are applicable
  if (strategicRoles.length < 2 && strategicScored.length >= 2) {
    strategicRoles = strategicScored.slice(0, 2).map((x) => x.s);
  }

  // If domain is empty but strategic exists, the caller should still fall back
  // to legacy (we don't run strategic-only consilium because it lacks statute grounding).
  return {
    hasDomainMatch,
    domainRoles,
    strategicRoles,
  };
}

// ─── Compilation: roles → ConsiliumRole for the runner ───────────────────────

/** Compile a set of roles to runnable ConsiliumRole objects, injecting memory
 *  hooks from the provided reader. Pure aside from the reader.read() calls. */
export async function compileRoles(params: {
  selection: RoleSelection;
  ctx: CaseContext;
  memoryReader: MemoryReader;
}): Promise<ReadonlyArray<CompiledRole>> {
  const { selection, ctx, memoryReader } = params;
  const lang = ctx.language ?? "ru";

  const compiledDomain = await Promise.all(
    selection.domainRoles.map(async (d) => compileSingleRole(d, ctx, lang, memoryReader)),
  );
  const compiledStrategic = await Promise.all(
    selection.strategicRoles.map(async (s) => compileSingleRole(s, ctx, lang, memoryReader)),
  );

  return [...compiledDomain, ...compiledStrategic];
}

async function compileSingleRole(
  role: RoleDef,
  ctx: CaseContext,
  lang: CaseContext["language"],
  reader: MemoryReader,
): Promise<CompiledRole> {
  const memoryBlobs = await loadMemoryHooks(role.memoryHooks, reader);
  const body = role.systemPromptFactory(ctx, memoryBlobs);
  return {
    id: role.id,
    name: pickName(role.name, lang),
    kind: role.kind,
    model: role.model,
    maxTokens: role.maxTokens,
    systemBody: body,
  };
}
