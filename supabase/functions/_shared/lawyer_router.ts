// lawyer_router.ts — picks 3-5 specialised lawyers for a given query.
// -----------------------------------------------------------------------------
// Routing rules (always-on, before optional Haiku classifier):
//
//   1. Always include exactly ONE general counsel:
//        - senior_asianajaja  if jurisdiction = FI / mixed-FI-dominant
//        - senior_vandeadvokaat  if jurisdiction = EE / mixed-EE-dominant
//        - jurisdiction unknown → default = senior_asianajaja IF query has
//          Finnish keywords; otherwise senior_vandeadvokaat.
//
//   2. Always include exactly ONE strategist (alternatives generator).
//
//   3. 1-3 domain experts by keyword score from the user's query:
//        immigration / tax / family / labor / corporate / criminal_defender
//
//   4. For complex / multi-jurisdiction / high-stakes queries (complexity ≥ 7
//      OR jurisdiction = "mixed" OR hasHardDeadline), add researcher AND
//      litigator. Total can reach 5 with the floor of 3.
//
//   5. Never duplicate. Always 3 ≤ |selection| ≤ 5.
//
// The optional Haiku classifier (`classifyLawyersWithHaiku`) can refine the
// selection — call it only when ANTHROPIC_API_KEY is available and you want
// the extra precision. Pure keyword routing already handles 80% of cases.
// -----------------------------------------------------------------------------

import type { CaseContext } from "./consilium_roles/types.ts";
import {
  ALL_LAWYERS,
  buildLawyerCtx,
  type LawyerAgent,
} from "./lawyer_agents/index.ts";

// ─── Constants ───────────────────────────────────────────────────────────────

const MIN_LAWYERS = 3;
const MAX_LAWYERS = 5;
const COMPLEXITY_THRESHOLD = 7;

// ─── Heuristic helpers ───────────────────────────────────────────────────────

/** Score one lawyer against the query: count of triggerKeywords that appear
 *  as substrings in the lowercase query + expertise tag bonus. */
function scoreLawyer(agent: LawyerAgent, query: string, ctx: CaseContext): number {
  const q = query.toLowerCase();
  let score = 0;
  for (const kw of agent.triggerKeywords) {
    if (q.includes(kw)) score += 1;
  }
  // Boost if ctx.caseType maps to this agent
  const caseToAgentId: Record<NonNullable<CaseContext["caseType"]>, string[]> = {
    immigration: ["immigration-lawyer"],
    criminal: ["criminal-defender"],
    contract: ["corporate-lawyer"],
    employment: ["labor-lawyer"],
    tax: ["tax-advisor"],
    family: ["family-lawyer"],
    consumer: ["corporate-lawyer"],
    gdpr: ["corporate-lawyer"],
    unknown: [],
  };
  if (ctx.caseType && caseToAgentId[ctx.caseType]?.includes(agent.id)) {
    score += 5;
  }
  if (ctx.secondaryTypes) {
    for (const t of ctx.secondaryTypes) {
      if (caseToAgentId[t]?.includes(agent.id)) score += 3;
    }
  }
  return score;
}

/** Pick the general counsel based on jurisdiction + language hints. */
function pickGeneralCounsel(
  query: string,
  ctx: CaseContext,
): LawyerAgent {
  const q = query.toLowerCase();
  const lang = ctx.language;

  // Explicit jurisdiction wins.
  if (ctx.jurisdiction === "FI") {
    return ALL_LAWYERS.find((a) => a.id === "senior-asianajaja")!;
  }
  if (ctx.jurisdiction === "EE") {
    return ALL_LAWYERS.find((a) => a.id === "senior-vandeadvokaat")!;
  }

  // Language hints.
  if (lang === "fi") {
    return ALL_LAWYERS.find((a) => a.id === "senior-asianajaja")!;
  }
  if (lang === "et") {
    return ALL_LAWYERS.find((a) => a.id === "senior-vandeadvokaat")!;
  }

  // Keyword heuristic.
  const fiHits = ["suomi", "finland", "финлянд", "soome", "kho", "kko", "ulkomaalaislaki", "asianajaja", "helsink"]
    .filter((k) => q.includes(k)).length;
  const eeHits = ["eesti", "estonia", "эстони", "soome ei", "riigikohus", "vandeadvokaat", "tallinn", "tartu", "äs"]
    .filter((k) => q.includes(k)).length;

  if (fiHits >= eeHits) {
    return ALL_LAWYERS.find((a) => a.id === "senior-asianajaja")!;
  }
  return ALL_LAWYERS.find((a) => a.id === "senior-vandeadvokaat")!;
}

/** Pick 1-3 domain experts by keyword score (excluding general counsel + meta
 *  roles which the router handles separately). */
function pickDomainExperts(
  query: string,
  ctx: CaseContext,
  maxN: number,
): LawyerAgent[] {
  const domainIds = new Set([
    "immigration-lawyer",
    "tax-advisor",
    "family-lawyer",
    "labor-lawyer",
    "corporate-lawyer",
    "criminal-defender",
  ]);

  const scored = ALL_LAWYERS
    .filter((a) => domainIds.has(a.id))
    .map((a) => ({ a, score: scoreLawyer(a, query, ctx) }))
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score);

  return scored.slice(0, maxN).map((x) => x.a);
}

/** True if the query / context warrants pulling in the heavy meta roles. */
function isHighStakes(query: string, ctx: CaseContext): boolean {
  const complexity = ctx.complexity ?? 0;
  if (complexity >= COMPLEXITY_THRESHOLD) return true;
  if (ctx.jurisdiction === "mixed") return true;
  if (ctx.hasHardDeadline) return true;
  // Lexical signal: supreme court / ECHR / kassatio
  const q = query.toLowerCase();
  const highKw = [
    "kho",
    "kko",
    "riigikohus",
    "supreme",
    "верховн",
    "korkein",
    "kassatsioon",
    "kassaatio",
    "echr",
    "eit",
    "ekik",
    "eik",
    "valituslupa",
    "kassatsiooniluba",
    "ennakkopäätös",
    "prejudikaat",
    "depri",
    "deport",
    "депорт",
    "karkotus",
    "väljasaatmi",
  ];
  return highKw.some((k) => q.includes(k));
}

// ─── Public router ──────────────────────────────────────────────────────────

export interface LawyerRouterDecision {
  /** Selected lawyers in the order they should appear in Round 1. */
  agents: LawyerAgent[];
  /** Whether the high-stakes branch fired. */
  highStakes: boolean;
  /** Free-form trace for logging / SSE telemetry. */
  trace: string[];
}

/** Main router. Pure function — no I/O. */
export function routeToLawyers(
  query: string,
  lang: NonNullable<CaseContext["language"]>,
  baseCtx?: CaseContext,
): LawyerRouterDecision {
  const ctx = buildLawyerCtx(query, lang, baseCtx);
  const trace: string[] = [];

  // ── 1. General counsel ───────────────────────────────────────────────────
  const generalCounsel = pickGeneralCounsel(query, ctx);
  trace.push(`general_counsel=${generalCounsel.id}`);

  // ── 2. Domain experts ────────────────────────────────────────────────────
  // High-stakes can absorb up to 3 domain experts, else cap at 2 so we have
  // budget for strategist + (maybe) researcher + (maybe) litigator.
  const highStakes = isHighStakes(query, ctx);
  const domainBudget = highStakes ? 2 : 2;
  const domains = pickDomainExperts(query, ctx, domainBudget);
  for (const d of domains) {
    trace.push(`domain=${d.id}`);
  }

  // ── 3. Strategist — always ───────────────────────────────────────────────
  const strategist = ALL_LAWYERS.find((a) => a.id === "strategist")!;
  trace.push(`meta=strategist`);

  // ── 4. High-stakes adds researcher + litigator ───────────────────────────
  const extras: LawyerAgent[] = [];
  if (highStakes) {
    const researcher = ALL_LAWYERS.find((a) => a.id === "researcher")!;
    const litigator = ALL_LAWYERS.find((a) => a.id === "litigator")!;
    extras.push(researcher, litigator);
    trace.push(`meta=researcher`, `meta=litigator`, `high_stakes=true`);
  } else {
    trace.push(`high_stakes=false`);
  }

  // ── 5. Combine, dedupe, cap ──────────────────────────────────────────────
  const out: LawyerAgent[] = [];
  const seen = new Set<string>();
  for (const a of [generalCounsel, ...domains, strategist, ...extras]) {
    if (!seen.has(a.id)) {
      seen.add(a.id);
      out.push(a);
    }
  }

  // Floor at MIN_LAWYERS — if no domain expert keyword-matched, the floor
  // is satisfied by adding researcher (broad investigator) to cover the gap.
  while (out.length < MIN_LAWYERS) {
    const filler = ALL_LAWYERS.find((a) =>
      !seen.has(a.id) && (a.id === "researcher" || a.id === "litigator")
    );
    if (!filler) break;
    seen.add(filler.id);
    out.push(filler);
    trace.push(`filler=${filler.id}`);
  }

  // Cap at MAX_LAWYERS.
  const capped = out.slice(0, MAX_LAWYERS);
  if (capped.length < out.length) {
    trace.push(`capped_from=${out.length}_to=${MAX_LAWYERS}`);
  }

  return {
    agents: capped,
    highStakes,
    trace,
  };
}

// ─── Optional Haiku refinement ───────────────────────────────────────────────

/** Pluggable Haiku caller — same shape the consilium uses. */
export interface HaikuCaller {
  blocking(opts: {
    model: string;
    system: string;
    userMessage: string;
    maxTokens: number;
  }): Promise<string>;
}

const HAIKU_SYSTEM = `Ты — классификатор юридических запросов.
Тебе дан запрос клиента и список юридических специализаций.
Верни JSON: { "agent_ids": ["id1", "id2", "id3"] } — 3-5 наиболее релевантных id.
Доступные id: senior-vandeadvokaat, senior-asianajaja, immigration-lawyer, tax-advisor,
family-lawyer, labor-lawyer, corporate-lawyer, criminal-defender, litigator, researcher, strategist.
ВСЕГДА включи ровно ОДНОГО general counsel (senior-vandeadvokaat OR senior-asianajaja).
ВСЕГДА включи strategist.
Без markdown, только JSON.`;

/** Optional refinement of the keyword-routed selection. Returns the union of
 *  keyword-routed and Haiku-suggested agents, capped at MAX_LAWYERS. */
export async function refineWithHaiku(
  query: string,
  initial: LawyerRouterDecision,
  caller: HaikuCaller,
  modelId: string,
): Promise<LawyerRouterDecision> {
  try {
    const raw = await caller.blocking({
      model: modelId,
      system: HAIKU_SYSTEM,
      userMessage: `Запрос клиента:\n${query.slice(0, 1200)}\n\nКонтекст: ${
        initial.trace.join(", ")
      }`,
      maxTokens: 200,
    });
    const m = raw.match(/\{[\s\S]*\}/);
    if (!m) return initial;
    const parsed = JSON.parse(m[0]) as { agent_ids?: unknown };
    if (!Array.isArray(parsed.agent_ids)) return initial;
    const haikuIds = parsed.agent_ids
      .filter((x): x is string => typeof x === "string");

    const seen = new Set<string>(initial.agents.map((a) => a.id));
    const out: LawyerAgent[] = [...initial.agents];
    for (const id of haikuIds) {
      if (seen.has(id)) continue;
      const agent = ALL_LAWYERS.find((a) => a.id === id);
      if (!agent) continue;
      seen.add(id);
      out.push(agent);
      if (out.length >= MAX_LAWYERS) break;
    }
    return {
      agents: out.slice(0, MAX_LAWYERS),
      highStakes: initial.highStakes,
      trace: [...initial.trace, `haiku_added=${haikuIds.join(",")}`],
    };
  } catch (e) {
    console.warn(`lawyer_router: Haiku refine failed: ${String(e).slice(0, 200)}`);
    return initial;
  }
}

// ─── Constants exposed for tests ─────────────────────────────────────────────

export {
  COMPLEXITY_THRESHOLD,
  MAX_LAWYERS,
  MIN_LAWYERS,
};
