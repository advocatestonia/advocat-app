// lawyer_agents/index.ts — barrel export for the lawyer department.
// -----------------------------------------------------------------------------

export type { LawyerAgent, LawyerModel } from "./types.ts";
export {
  buildLawyerCtx,
  extractKeywords,
  resolveModelId,
} from "./types.ts";

export { senior_vandeadvokaat } from "./senior_vandeadvokaat.ts";
export { senior_asianajaja } from "./senior_asianajaja.ts";
export { immigration_lawyer } from "./immigration_lawyer.ts";
export { tax_advisor } from "./tax_advisor.ts";
export { family_lawyer } from "./family_lawyer.ts";
export { labor_lawyer } from "./labor_lawyer.ts";
export { corporate_lawyer } from "./corporate_lawyer.ts";
export { criminal_defender } from "./criminal_defender.ts";
export { litigator } from "./litigator.ts";
export { researcher } from "./researcher.ts";
export { strategist } from "./strategist.ts";

import { senior_vandeadvokaat } from "./senior_vandeadvokaat.ts";
import { senior_asianajaja } from "./senior_asianajaja.ts";
import { immigration_lawyer } from "./immigration_lawyer.ts";
import { tax_advisor } from "./tax_advisor.ts";
import { family_lawyer } from "./family_lawyer.ts";
import { labor_lawyer } from "./labor_lawyer.ts";
import { corporate_lawyer } from "./corporate_lawyer.ts";
import { criminal_defender } from "./criminal_defender.ts";
import { litigator } from "./litigator.ts";
import { researcher } from "./researcher.ts";
import { strategist } from "./strategist.ts";
import type { LawyerAgent } from "./types.ts";

/** The full lawyer department. Order is meaningful: the router uses it as a
 *  tie-breaker when keyword scores are equal — general counsels first, then
 *  domain experts, then meta-roles (researcher, strategist) last. */
export const ALL_LAWYERS: ReadonlyArray<LawyerAgent> = [
  senior_vandeadvokaat,
  senior_asianajaja,
  immigration_lawyer,
  tax_advisor,
  family_lawyer,
  labor_lawyer,
  corporate_lawyer,
  criminal_defender,
  litigator,
  researcher,
  strategist,
] as const;

/** Lookup by id. Returns null if unknown. */
export function getLawyerById(id: string): LawyerAgent | null {
  return ALL_LAWYERS.find((a) => a.id === id) ?? null;
}
