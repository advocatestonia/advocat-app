// email-triage/reviewer.ts
// -----------------------------------------------------------------------------
// Lightweight Haiku-grade reviewer that regex-validates the parsed Sonnet
// output. We do NOT invoke Haiku live in this module — the regex anchors
// implement the same checks the spec mandates (§697), so we get the
// determinism + cost saving of running them locally. A future revision
// can plug Haiku in by calling `runHaikuReviewer` with an explicit
// prompt; for now `runReviewerLocal` IS the reviewer.
//
// Anchors validated (per §697):
//   1. case-number anchor present whenever <draft> is emitted (heuristic:
//      subject contains a recognised case-number-shaped token, or the
//      draft body cites one);
//   2. <conflict_check> populated and well-formed (parser already guards);
//   3. <appeal_route> present whenever inbound subject contains
//      päätös/otsus/decision/määräys AND POSTURE = reply_now;
//   4. <gdpr_basis> present whenever <draft> is emitted (one entry per
//      To+Cc recipient);
//   5. <actions_required> present whenever POSTURE != no_reply;
//   6. own_counsel_advisory threads have send_recommendation =
//      hold_for_user_review (Rule 16.bis hard cap).
// -----------------------------------------------------------------------------

import type { ParsedTriage } from "./parse_blocks.ts";

export interface ReviewerResult {
  ok: boolean;
  failures: string[];
  retry_with_hint: string | null;
}

const CASE_NUMBER_RE = [
  /\b\d{1,5}\/[A-Z]\b/, // R-number variants e.g. 5500/R
  /\bdnro\s*\d+\/\d{4}\b/i, // FI dnro
  /\b\d+\/\d{4}\b/, // generic NN/YYYY
  /\bcase\s*no\.?\s*\d+\b/i,
  /\bdiaari\s*\d+\b/i,
];

const DECISION_SUBJECT_RE =
  /\b(päätös|paatos|otsus|määräys|maaraus|decision|ruling|ratkaisu)\b/i;

export function runReviewerLocal(
  parsed: ParsedTriage,
  inboundSubject: string,
): ReviewerResult {
  const failures: string[] = [];

  // 1. case-number anchor on draft (only when draft is emitted)
  if (parsed.draft) {
    const corpus = `${parsed.draft.subject ?? ""}\n${parsed.draft.body ?? ""}`;
    const hasAnchor = CASE_NUMBER_RE.some((re) => re.test(corpus));
    if (!hasAnchor) {
      failures.push("missing_case_number_anchor");
    }
  }

  // 2. conflict_check is parser-guarded; keep an explicit check anyway.
  if (
    parsed.conflict_check !== "passed" && parsed.conflict_check !== "flagged"
  ) {
    failures.push("malformed_conflict_check");
  }

  // 3. appeal_route required when inbound subject is decision-shaped AND
  //    posture is reply_now (drafting a response to a päätös).
  const subjectIsDecision = DECISION_SUBJECT_RE.test(inboundSubject ?? "");
  if (
    subjectIsDecision && parsed.triage.posture === "reply_now" &&
    parsed.appeal_route == null
  ) {
    failures.push("missing_appeal_route_on_decision");
  }

  // 4. gdpr_basis required whenever a draft is emitted (one entry per
  //    To+Cc recipient).
  if (parsed.draft) {
    const recipients = [...parsed.draft.to, ...parsed.draft.cc];
    if (parsed.gdpr_basis.length === 0) {
      failures.push("missing_gdpr_basis_on_draft");
    } else if (recipients.length > 0) {
      const bases = new Set(
        parsed.gdpr_basis.map((g) => g.recipient.toLowerCase()),
      );
      const missing = recipients.filter((r) => !bases.has(r.toLowerCase()));
      if (missing.length > 0) {
        failures.push(`missing_gdpr_recipient:${missing.join(",")}`);
      }
    }
  }

  // 5. actions_required required whenever posture != no_reply.
  if (
    parsed.triage.posture !== "no_reply" &&
    parsed.actions_required.length === 0
  ) {
    failures.push("missing_actions_required");
  }

  // 6. own_counsel_advisory hard cap (Rule 16.bis). The pre-classifier
  //    sets the input variable; this is the post-model check.
  if (
    parsed.privilege_check === "own_counsel_advisory" &&
    parsed.send_recommendation === "auto_send_eligible"
  ) {
    failures.push("own_counsel_advisory_must_be_hold_for_user_review");
  }

  if (failures.length === 0) {
    return { ok: true, failures: [], retry_with_hint: null };
  }
  return {
    ok: false,
    failures,
    retry_with_hint: `Reviewer failures (regenerate once): ${failures.join("; ")}.`,
  };
}
