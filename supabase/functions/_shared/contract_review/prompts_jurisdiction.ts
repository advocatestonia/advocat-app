// prompts_jurisdiction.ts — Jurisdiction-aware toolkit fragment.
// -----------------------------------------------------------------------------
// We bucket by legal family rather than every ISO country code: DE/AT/CH share
// the BGB tradition; US/UK share UCC + common-law warranty doctrine; EU is
// the cross-border default (GDPR, Brussels I bis, CISG, Rome I). Estonian
// and Finnish content lives in the main legal stack; Contract Review only
// adds the foreign-law layer.
// -----------------------------------------------------------------------------

enum LegalFamily {
  De = "de",
  Anglo = "anglo",
  Eu = "eu",
  Generic = "generic",
}

function classify(tag: string): LegalFamily {
  const t = tag.trim().toLowerCase();
  if (t === "de" || t === "at" || t === "ch" || t === "dach") {
    return LegalFamily.De;
  }
  if (t === "us" || t === "uk" || t === "gb" || t === "ie") {
    return LegalFamily.Anglo;
  }
  if (t === "eu") return LegalFamily.Eu;
  return LegalFamily.Generic;
}

const JURISDICTION_DE = `## DE / AT / CH (BGB family)
- **BGB**: §§ 305–310 (AGB-Kontrolle / standard-terms control), §§ 433 ff. (Kauf), §§ 611 ff. (Dienstvertrag), §§ 631 ff. (Werkvertrag), § 309 Nr. 7 (forbidden liability caps).
- **HGB**: § 84 (Handelsvertreter / commercial agent — territorial protection, post-contractual non-compete & Ausgleichsanspruch § 89b), § 377 (Kaufmännische Rügepflicht — buyer must inspect & notify "unverzüglich"; default ~ 1–2 weeks, max statute of limitations runs from notice).
- **AGB-Kontrolle**: any pre-formulated clause favouring the drafter is subject to § 307 BGB review. Flag one-sided liability caps, automatic renewals > 1 year, jurisdiction clauses in adhesion contracts.
- **AT specifics**: § 6 KSchG (consumer protection) overlays business-to-business agency arrangements if a sole-trader counterparty resembles a consumer.
- **CH specifics**: OR Art. 184 ff. (Kauf), Art. 394 ff. (Auftrag), Art. 418a ff. (Agenturvertrag with Kundschaftsentschädigung Art. 418u).
`;

const JURISDICTION_ANGLO = `## US / UK / IE (common-law family)
- **US — UCC Article 2** (Sale of Goods): § 2-207 (battle of forms), § 2-302 (unconscionability), § 2-313 (express warranties), § 2-314 (implied warranty of merchantability), § 2-315 (fitness for purpose), § 2-316 (disclaimers — must be conspicuous & use "merchantability"/"as is"), § 2-719 (remedy limitation; must not "fail of its essential purpose").
- **US — Common law**: parol-evidence rule, doctrine of consideration, promissory estoppel. Flag entire-agreement / merger clauses that exclude pre-contractual reps.
- **UK — Sale of Goods Act 1979** (commercial supply) + **Consumer Rights Act 2015** (consumer). For commercial contracts: **Unfair Contract Terms Act 1977** s.3 (reasonableness of liability clauses), s.6–7 (implied terms), **Misrepresentation Act 1967** s.3.
- **UK — Common law**: Hadley v. Baxendale remoteness test, penalty-vs-liquidated-damages doctrine (Cavendish Square Holding v. Makdessi [2015] UKSC 67), force majeure & frustration (Davis Contractors v. Fareham).
- **Flag**: "as is" disclaimers without conspicuous notice; one-sided indemnity; non-mutual jurisdiction; "sole and exclusive remedy" clauses that fail § 2-719(2).
`;

const JURISDICTION_EU = `## EU (cross-border default)
- **GDPR (Reg. 2016/679)**: Art. 28 (processor agreements — SCC mandatory clauses), Art. 32 (security), Art. 33–34 (breach notification 72h), Art. 44–49 (international transfers — flag any data flow to non-adequate jurisdictions without SCCs or BCRs).
- **Brussels I bis (Reg. 1215/2012)**: jurisdiction clauses Art. 25, consumer protection Art. 17–19, exclusive jurisdiction Art. 24.
- **Rome I (Reg. 593/2008)**: choice-of-law for contractual obligations; Art. 6 consumer overrides; Art. 9 overriding mandatory provisions.
- **CISG (Vienna 1980)**: applies by default to international sale-of-goods between contracting states (Art. 1(1)(a)) UNLESS explicitly excluded. If contract is silent and counterparties are in CISG states — point this out. Notice of non-conformity within "reasonable time" Art. 39.
- **Late Payment Directive 2011/7/EU**: statutory interest floor (ECB + 8pp), commercial payment terms cap 60 days unless expressly agreed otherwise and not "grossly unfair".
- **DSA / DMA / AI Act**: flag if contract touches platform liability, gatekeeper obligations, or high-risk AI systems.
`;

const JURISDICTION_GENERIC = `## Generic toolkit (no jurisdiction declared)
- Ask the user to confirm the governing-law clause before final analysis.
- Apply CISG default test (international sale-of-goods between contracting states unless excluded).
- Flag the absence of a governing-law and dispute-resolution clause as **HIGH risk**: in the silence of choice-of-law, conflicts rules of multiple fora may compete.
`;

/** Returns a prompt fragment describing the legal toolkit the model should
 * have ready when analysing a contract governed by [jurisdictions]. Multiple
 * jurisdictions stack (e.g. ["DE", "EU"] for a German contract with a GDPR
 * data-processing addendum). Unknown tags fall back to the EU/generic
 * toolkit so we never refuse to analyse. */
export function buildJurisdictionContext(jurisdictions: string[]): string {
  if (jurisdictions.length === 0) {
    return JURISDICTION_GENERIC;
  }
  const families = new Set<LegalFamily>(jurisdictions.map(classify));
  const parts: string[] = [];
  parts.push("# JURISDICTION TOOLKIT");
  parts.push(
    "When citing or reasoning about the contract's governing law, draw on " +
      "the following statutory toolkits. Always quote the section number AND " +
      "the law's native-language name; provide a parenthetical translation " +
      "when the user's output language differs.",
  );
  parts.push("");
  if (families.has(LegalFamily.De)) parts.push(JURISDICTION_DE);
  if (families.has(LegalFamily.Anglo)) parts.push(JURISDICTION_ANGLO);
  if (families.has(LegalFamily.Eu)) parts.push(JURISDICTION_EU);
  if (
    families.has(LegalFamily.Generic) &&
    !families.has(LegalFamily.De) &&
    !families.has(LegalFamily.Anglo) &&
    !families.has(LegalFamily.Eu)
  ) {
    parts.push(JURISDICTION_GENERIC);
  }
  // Match Dart `writeln` which appends a trailing newline.
  return parts.join("\n") + "\n";
}
