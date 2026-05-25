// consilium_lawyer_bridge.ts — Convert lawyer_router decisions into the
// consilium runner's role roster.
// -----------------------------------------------------------------------------
// Why this file exists
// --------------------
// We have THREE role-selection paths in production today:
//
//   1. Legacy 6 generic roles            — consilium.ts ROLES
//   2. v2.2 router (DOMAIN/STRATEGIC)    — consilium_roles/selectConsiliumRoles
//   3. 11-persona lawyer department      — lawyer_router.ts routeToLawyers
//
// Path (3) was implemented (lawyer_router.ts + 11 LawyerAgent files) but only
// wired into the v3 adversarial pipeline (consilium_v3.ts:961-983), gated
// behind LAWYER_DEPARTMENT_ENABLED + highStakes check. For the standard v2
// non-adversarial pipeline the department is dark.
//
// This bridge exposes a thin pure function the standard runner (and any future
// caller) can call:
//
//     const roles = selectRolesFromLawyerDept(query, classification);
//     // → ConsiliumRole[] compatible with runRole() and the rest of the v2
//     //   pipeline.
//
// The function NEVER throws — on any error it returns the legacy ROLES so
// callers can always fall through safely.
//
// Phase 1 acceptance (consilium-arch sprint 2026-05-25):
//   • Bridges 11-persona router → ConsiliumRole[]
//   • Pure function, no I/O
//   • Default-off via env flag at the call site (this file does not read env)
//   • Safe-fallback contract — caller can `selectRolesFromLawyerDept(...) ??
//     selectConsiliumRoles(...)` without try/catch
// -----------------------------------------------------------------------------

import type { ConsiliumRole } from "./consilium.ts";
import type { CaseContext } from "./consilium_roles/types.ts";
import {
  ALL_LAWYERS,
  type LawyerAgent,
  resolveModelId,
} from "./lawyer_agents/index.ts";
import { routeToLawyers } from "./lawyer_router.ts";

// ─── Internal helpers ────────────────────────────────────────────────────────

/** Adapter — converts a single LawyerAgent to a ConsiliumRole.
 *
 *  This is the v2-pipeline twin of `lawyerToConsiliumRole` in consilium_v3.ts.
 *  We duplicate the few lines here to keep the import direction clean:
 *  consilium.ts ← consilium_lawyer_bridge.ts (this file) ← claude-proxy.
 *  Importing from consilium_v3.ts would create
 *  consilium.ts ← consilium_v3.ts ← consilium_lawyer_bridge.ts ← consilium.ts
 *  which is fine TypeScript-wise but obscures the layering.
 *
 *  The role's `focus` is the agent's compiled system prompt body; `isCompiled`
 *  is set so the runner suppresses the legacy "Ты выступаешь в роли" preamble.
 */
function agentToConsiliumRole(
  agent: LawyerAgent,
  query: string,
  ctx: CaseContext,
): ConsiliumRole {
  return {
    name: agent.name,
    model: resolveModelId(agent.model),
    maxTokens: agent.maxTokens,
    focus: agent.systemPrompt(query, ctx),
    isCompiled: true,
  };
}

/** Resolve a usable language tag for the lawyer router. Defaults to "ru"
 *  because the consilium synthesis prompts and base lawyer persona are
 *  Russian — see SYNTHESIS_SYSTEM_PROMPT in consilium.ts. */
function resolveLang(ctx: CaseContext | undefined): NonNullable<CaseContext["language"]> {
  return (ctx?.language ?? "ru") as NonNullable<CaseContext["language"]>;
}

// ─── Public API ──────────────────────────────────────────────────────────────

export interface LawyerBridgeResult {
  /** Selected ConsiliumRoles, ready for runRole(). 3-5 entries. */
  roles: ConsiliumRole[];
  /** The underlying LawyerAgents (for telemetry / SSE roster events). */
  agents: ReadonlyArray<LawyerAgent>;
  /** Pass-through of the lawyer_router's trace — useful for SSE / logging. */
  trace: string[];
  /** Whether the router classified the query as high-stakes. */
  highStakes: boolean;
}

/** Run the 11-persona router and convert the decision to ConsiliumRole[].
 *
 *  Pure function. NEVER throws — catches any internal error and returns
 *  `null` so the caller can fall back to its previous selection mechanism.
 *
 *  @param query           Raw user query (drives keyword routing).
 *  @param classification  Optional pre-computed CaseContext (caseType,
 *                         jurisdiction, language, complexity, …). If absent,
 *                         the router uses only keyword heuristics on `query`.
 *  @returns LawyerBridgeResult or null on failure / empty selection.
 */
export function selectRolesFromLawyerDept(
  query: string,
  classification?: CaseContext,
): LawyerBridgeResult | null {
  try {
    if (!query || query.trim().length === 0) return null;

    const lang = resolveLang(classification);
    const decision = routeToLawyers(query, lang, classification);

    if (!decision.agents || decision.agents.length === 0) return null;

    // ctx given to systemPrompt() must always be defined; rebuild a minimal
    // one if the caller passed nothing. routeToLawyers already does this
    // internally via buildLawyerCtx, but agent.systemPrompt is invoked again
    // here with whatever the caller passed, so we mirror the same defaults.
    const ctx: CaseContext = classification ?? { language: lang };

    const roles = decision.agents.map((a) => agentToConsiliumRole(a, query, ctx));

    return {
      roles,
      agents: decision.agents,
      trace: decision.trace,
      highStakes: decision.highStakes,
    };
  } catch (e) {
    console.warn(
      `consilium_lawyer_bridge: selection failed (returning null): ${
        String(e).slice(0, 200)
      }`,
    );
    return null;
  }
}

/** Convenience wrapper that returns ONLY the roles, for call sites that
 *  don't need the trace / highStakes flags. Mirrors the existing
 *  `selectConsiliumRoles` signature for drop-in use. Returns null if the
 *  department produced no selection. */
export function selectRolesFromLawyerDeptSimple(
  query: string,
  classification?: CaseContext,
): ConsiliumRole[] | null {
  const result = selectRolesFromLawyerDept(query, classification);
  return result ? result.roles : null;
}

// ─── Constants exposed for tests ─────────────────────────────────────────────

/** Env flag name. Caller (claude-proxy) reads this to decide whether to even
 *  invoke the bridge. Default OFF. */
export const LAWYER_ROUTER_FLAG_ENV = "CONSILIUM_LAWYER_ROUTER_ENABLED";

/** Read the lawyer-router feature flag from the runtime env. Defaults to
 *  false on any error. Mirrors `isLawyerDepartmentEnabled` from consilium_v3.ts. */
export function isLawyerRouterEnabled(): boolean {
  try {
    // deno-lint-ignore no-explicit-any
    const env = (globalThis as any).Deno?.env;
    if (!env || typeof env.get !== "function") return false;
    const raw = env.get(LAWYER_ROUTER_FLAG_ENV);
    if (!raw) return false;
    const normalised = String(raw).toLowerCase().trim();
    return normalised === "true" || normalised === "1" || normalised === "yes";
  } catch {
    return false;
  }
}

/** Re-export ALL_LAWYERS for tests so they can assert on roster composition
 *  without a second import path. */
export { ALL_LAWYERS };
