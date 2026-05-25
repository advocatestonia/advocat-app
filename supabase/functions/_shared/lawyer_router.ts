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
// Wave F (2026-05-25): bumped from 5 → 7 to accommodate up to 4 specialists
// (ecthr / forensic / writer / psychology) alongside general counsel + domain
// experts + strategist + (high-stakes) researcher/litigator. The cap-trim
// logic below guarantees strategist + general counsel always survive.
const MAX_LAWYERS = 7;
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

// ─── Wave F (2026-05-25) specialist triggers ────────────────────────────────
// Four specialised experts surface ON TOP of the domain expert pass when the
// query/context matches their trigger patterns. These do not replace the
// general counsel or strategist — they augment the roster.

/** ECtHR Specialist: Convention Arts + Strasbourg procedure markers. */
const ECTHR_REGEX =
  /\b(ECtHR|EIT|EIK|ECHR|ЕСПЧ|ЕКПЧ|Strasbourg|Strasburg|Страсбург|HUDOC|Rule\s?39|art\.?\s?(3|6|8|13|14)\s+(ECHR|EIS|EKIK|EIK)|protocol\s?(7|12|15)|четыр[её]хмесячн|four[-\s]?month|neljä\s?kuukau|neli\s?kuu)\b/i;

function shouldAddEcthrSpecialist(query: string, ctx: CaseContext): boolean {
  if (ECTHR_REGEX.test(query)) return true;
  // Lexical fallback via keywords (in case ctx.keywords already extracted them)
  const kws = (ctx.keywords ?? []).join(" ");
  return ECTHR_REGEX.test(kws);
}

/** Client Psychology: emotional markers + high complexity. */
const PSYCH_REGEX =
  /(бо[юе]сь|устал|стои[тл]\s+ли|сдат[ьc]я|не\s+могу\s+больше|сил\s+нет|worth\s+fighting|exhausted|give\s+up|i\s+can[''']?t|kannattaako|en\s+jaksa|ei\s+jaksa|väsynyt|loobuda|alistua|kas\s+tasub|tunteet|tunded|депресс|тревож|stress|стресс)/i;

function shouldAddClientPsychology(query: string, ctx: CaseContext): boolean {
  if (PSYCH_REGEX.test(query)) return true;
  const complexity = ctx.complexity ?? 0;
  // Complexity >= 6 alone is not enough; we also want a soft emotional signal
  // OR explicit emotional case posture. Pure procedural complexity goes to
  // researcher/litigator, not psychology.
  if (complexity >= 6 && PSYCH_REGEX.test((ctx.keywords ?? []).join(" "))) {
    return true;
  }
  return false;
}

/** Forensic Evidence: fact / document / medical markers. */
const FORENSIC_REGEX =
  /(доказательств|evidence|tõend|todiste|подпис[ьи]|signature|allekirjoit|allkir|F\s?43|PTSD|посттравмат|post[-\s]?traumat|epikriis|epikriisi|epicrisis|discharge\s+summary|ICD[-\s]?(10|11)|лекарск|медицинск|lääkärinlausunto|tervisetõend|chain\s+of\s+custody|цеп[ьи]\s+хранения|подлинност[ьи]|authenticity|forensic|кримина|ekspert\b|expert\s+witness|asiantuntijalausunto)/i;

function shouldAddForensicEvidence(query: string, ctx: CaseContext): boolean {
  if (FORENSIC_REGEX.test(query)) return true;
  const kws = (ctx.keywords ?? []).join(" ");
  return FORENSIC_REGEX.test(kws);
}

/** Native Writer: drafting verbs + document type names. */
const DRAFTING_REGEX =
  /\b(hakemus|kirjelmä|kirjelm|valitusluvan?\s?hakemus|valituslupa|kaebus|kassatsioonkaebus|menetluslub|valitus|vastine|vastus|lausunto|seisukoht|esitys|esitis|taotlus|draft|drafting|luonnos|kavand|черновик|написать|напиши|составить|составь|kirjoita|kirjuta|koosta|laadi|laatia|ходатайство|обращение)\b/i;

function shouldAddNativeWriter(query: string, ctx: CaseContext): boolean {
  if (DRAFTING_REGEX.test(query)) return true;
  const kws = (ctx.keywords ?? []).join(" ");
  return DRAFTING_REGEX.test(kws);
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

  // ── 4b. Wave F specialists — surface on trigger match ────────────────────
  const specialists: LawyerAgent[] = [];
  if (shouldAddEcthrSpecialist(query, ctx)) {
    const sp = ALL_LAWYERS.find((a) => a.id === "ecthr-specialist");
    if (sp) {
      specialists.push(sp);
      trace.push(`specialist=ecthr-specialist`);
    }
  }
  if (shouldAddForensicEvidence(query, ctx)) {
    const sp = ALL_LAWYERS.find((a) => a.id === "forensic-evidence");
    if (sp) {
      specialists.push(sp);
      trace.push(`specialist=forensic-evidence`);
    }
  }
  if (shouldAddNativeWriter(query, ctx)) {
    const sp = ALL_LAWYERS.find((a) => a.id === "native-writer");
    if (sp) {
      specialists.push(sp);
      trace.push(`specialist=native-writer`);
    }
  }
  if (shouldAddClientPsychology(query, ctx)) {
    const sp = ALL_LAWYERS.find((a) => a.id === "client-psychology");
    if (sp) {
      specialists.push(sp);
      trace.push(`specialist=client-psychology`);
    }
  }

  // ── 5. Combine, dedupe, cap ──────────────────────────────────────────────
  // Order: general counsel → domains → specialists → strategist → high-stakes
  // meta-roles. Specialists go BEFORE strategist because they feed concrete
  // material into the strategist's synthesis; strategist must always remain
  // present even if specialists fill the cap.
  const out: LawyerAgent[] = [];
  const seen = new Set<string>();
  for (
    const a of [generalCounsel, ...domains, ...specialists, strategist, ...extras]
  ) {
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

  // Cap at MAX_LAWYERS — but PRESERVE general counsel + strategist as
  // non-negotiable anchors. If the natural cap would drop strategist, we
  // promote it back in by dropping the lowest-priority specialist instead.
  let capped: LawyerAgent[];
  if (out.length <= MAX_LAWYERS) {
    capped = out;
  } else {
    const anchors = new Set([generalCounsel.id, strategist.id]);
    const head = out.slice(0, MAX_LAWYERS);
    const hasAllAnchors = [...anchors].every((id) =>
      head.some((a) => a.id === id)
    );
    if (hasAllAnchors) {
      capped = head;
    } else {
      // Build a guaranteed-anchor slate: anchors first, then remaining in
      // original priority order up to the cap.
      const anchorAgents = out.filter((a) => anchors.has(a.id));
      const rest = out.filter((a) => !anchors.has(a.id));
      capped = [...anchorAgents, ...rest].slice(0, MAX_LAWYERS);
      trace.push(`anchor_preserved`);
    }
    trace.push(`capped_from=${out.length}_to=${capped.length}`);
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
