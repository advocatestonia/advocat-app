// demand-letter/handler.ts — pure letter-building logic for Feature #2.
// -----------------------------------------------------------------------------
// Given the wizard inputs (claim type, parties, amount/basis, deadline,
// jurisdiction, language) this builds a formal demand letter as markdown. No IO
// here so the whole composition is unit-testable without a DB or LLM.
//
// The structure mirrors a real maksuvaatimus / nõudekiri:
//   1. date + sender (the user — "on behalf of the user", never "from Advocat")
//   2. recipient block
//   3. subject line
//   4. body: facts → claim → legal basis (cited norms) → payment deadline →
//      consequences if unpaid
//   5. closing + signature placeholder
//   6. a mandatory disclaimer line (UPL mitigation)
//
// We never auto-send and never sign as a lawyer. The signature line is the
// user's own name. The disclaimer is non-removable from the generated body.
// -----------------------------------------------------------------------------

import {
  type ClaimType,
  type Jurisdiction,
  type NormRef,
  normsFor,
} from "./presets.ts";

/** Supported output languages for the letter body. */
export type LetterLang = "fi" | "et" | "ru" | "en";

export const LETTER_LANGS: readonly LetterLang[] = [
  "fi",
  "et",
  "ru",
  "en",
] as const;

/** True when [v] is a supported letter language. */
export function isLetterLang(v: unknown): v is LetterLang {
  return (
    typeof v === "string" && (LETTER_LANGS as readonly string[]).includes(v)
  );
}

/** A party (sender or recipient) on the letter. */
export interface Party {
  /** Full legal name (person or company). Required. */
  name: string;
  /** Optional postal / e-mail address block (free text, multi-line allowed). */
  address?: string | null;
}

/** Everything the wizard collects to compose one letter. */
export interface LetterInput {
  claimType: ClaimType;
  jurisdiction: Jurisdiction;
  lang: LetterLang;
  sender: Party;
  recipient: Party;
  /** Monetary amount of the demand (already formatted, e.g. "850.00"). */
  amount?: string | null;
  /** Currency code, defaults to EUR. */
  currency?: string | null;
  /** Free-text factual basis: what happened, why the money is owed. */
  basis: string;
  /** Payment deadline as an ISO date (YYYY-MM-DD) or human string. */
  deadline: string;
  /** ISO date the letter is dated (YYYY-MM-DD). */
  todayIso: string;
  /**
   * Optional reference (case/contract number) shown in the subject line.
   */
  reference?: string | null;
}

/** The composed letter plus metadata the caller persists / displays. */
export interface LetterResult {
  /** The full letter body as markdown. */
  markdown: string;
  /** The norm references actually embedded (for the verifier + UI chips). */
  norms: NormRef[];
  /** The subject line (also reused as the saved-letter title). */
  subject: string;
}

// ─── Localised label strings ─────────────────────────────────────────────────

interface Strings {
  subjectPrefix: string;
  claimLabel: Record<ClaimType, string>;
  toLabel: string;
  fromLabel: string;
  refLabel: string;
  factsHeading: string;
  demandHeading: string;
  /** Templated demand sentence; {amount} substituted. */
  demandSentence: string;
  legalHeading: string;
  deadlineHeading: string;
  /** Templated deadline sentence; {deadline} substituted. */
  deadlineSentence: string;
  consequencesHeading: string;
  consequencesText: string;
  closing: string;
  signatureLabel: string;
  disclaimer: string;
}

const STRINGS: Record<LetterLang, Strings> = {
  fi: {
    subjectPrefix: "Maksuvaatimus",
    claimLabel: {
      deposit_return: "Vuokravakuuden palautus",
      unpaid_wage: "Maksamaton palkka",
      fine_dispute: "Maksun / sakon oikaisuvaatimus",
      generic_claim: "Saatavan vaatimus",
    },
    toLabel: "Vastaanottaja",
    fromLabel: "Lähettäjä",
    refLabel: "Viite",
    factsHeading: "Asian tausta",
    demandHeading: "Vaatimus",
    demandSentence:
      "Vaadin teitä maksamaan minulle {amount} viipymättä alla mainittuun määräpäivään mennessä.",
    legalHeading: "Oikeudellinen peruste",
    deadlineHeading: "Maksun määräpäivä",
    deadlineSentence: "Pyydän suorittamaan maksun viimeistään {deadline}.",
    consequencesHeading: "Seuraukset, jos maksua ei suoriteta",
    consequencesText:
      "Mikäli maksua ei suoriteta määräaikaan mennessä, varaan oikeuden ryhtyä perintä- ja oikeudellisiin toimiin sekä vaatia viivästyskorkoa ja kuluja.",
    closing: "Kunnioittavasti,",
    signatureLabel: "Allekirjoitus",
    disclaimer:
      "Tämä asiakirja on laadittu käyttäjän omasta puolesta yleisenä mallina. Se ei ole oikeudellinen neuvonta eikä asianajajan toimenpide.",
  },
  et: {
    subjectPrefix: "Nõudekiri",
    claimLabel: {
      deposit_return: "Tagatisraha tagastamine",
      unpaid_wage: "Maksmata töötasu",
      fine_dispute: "Trahvi / makse vaie",
      generic_claim: "Rahalise nõude esitamine",
    },
    toLabel: "Saaja",
    fromLabel: "Saatja",
    refLabel: "Viide",
    factsHeading: "Asjaolud",
    demandHeading: "Nõue",
    demandSentence:
      "Nõuan teilt {amount} tasumist viivitamatult allpool märgitud tähtajaks.",
    legalHeading: "Õiguslik alus",
    deadlineHeading: "Maksetähtaeg",
    deadlineSentence: "Palun tasuda hiljemalt {deadline}.",
    consequencesHeading: "Tagajärjed maksmata jätmisel",
    consequencesText:
      "Kui makset ei tasuta tähtajaks, jätan endale õiguse pöörduda võla sissenõudmiseks kohtusse ning nõuda viivist ja kulusid.",
    closing: "Lugupidamisega,",
    signatureLabel: "Allkiri",
    disclaimer:
      "Käesolev dokument on koostatud kasutaja enda nimel üldise näidisena. See ei ole õigusnõustamine ega advokaadi toiming.",
  },
  ru: {
    subjectPrefix: "Требование об оплате",
    claimLabel: {
      deposit_return: "Возврат залога по аренде",
      unpaid_wage: "Невыплаченная заработная плата",
      fine_dispute: "Оспаривание штрафа / платежа",
      generic_claim: "Денежное требование",
    },
    toLabel: "Получатель",
    fromLabel: "Отправитель",
    refLabel: "Ссылка",
    factsHeading: "Обстоятельства дела",
    demandHeading: "Требование",
    demandSentence: "Требую выплатить мне {amount} в срок, указанный ниже.",
    legalHeading: "Правовое основание",
    deadlineHeading: "Срок оплаты",
    deadlineSentence: "Прошу произвести оплату не позднее {deadline}.",
    consequencesHeading: "Последствия неоплаты",
    consequencesText:
      "В случае неоплаты в указанный срок оставляю за собой право обратиться в суд для взыскания долга, а также требовать пени и расходов.",
    closing: "С уважением,",
    signatureLabel: "Подпись",
    disclaimer:
      "Настоящий документ составлен от имени пользователя как общий образец. Он не является юридической консультацией или действием адвоката.",
  },
  en: {
    subjectPrefix: "Demand for Payment",
    claimLabel: {
      deposit_return: "Return of rental deposit",
      unpaid_wage: "Unpaid wages",
      fine_dispute: "Dispute of a fine / charge",
      generic_claim: "Monetary claim",
    },
    toLabel: "To",
    fromLabel: "From",
    refLabel: "Reference",
    factsHeading: "Background",
    demandHeading: "Demand",
    demandSentence:
      "I hereby demand payment of {amount} by the deadline stated below.",
    legalHeading: "Legal basis",
    deadlineHeading: "Payment deadline",
    deadlineSentence: "Please make payment no later than {deadline}.",
    consequencesHeading: "Consequences of non-payment",
    consequencesText:
      "Should payment not be made by the deadline, I reserve the right to pursue debt-recovery and legal proceedings and to claim default interest and costs.",
    closing: "Yours faithfully,",
    signatureLabel: "Signature",
    disclaimer:
      "This document was prepared on behalf of the user as a general template. It is not legal advice or an act of a licensed attorney.",
  },
};

/** Picks the localised string bundle, falling back to English. */
export function stringsFor(lang: LetterLang): Strings {
  return STRINGS[lang] ?? STRINGS.en;
}

// ─── Validation ──────────────────────────────────────────────────────────────

/** A validation problem keyed by the offending field. */
export interface ValidationIssue {
  field: string;
  message: string;
}

/**
 * Validates the wizard input. Returns an empty array when valid. Pure — no IO.
 * We keep the rules deliberately light (the UI guides the user) but reject the
 * cases that would produce a nonsensical letter.
 */
export function validateLetterInput(input: LetterInput): ValidationIssue[] {
  const issues: ValidationIssue[] = [];
  if (!input.sender?.name?.trim()) {
    issues.push({ field: "sender.name", message: "Sender name is required" });
  }
  if (!input.recipient?.name?.trim()) {
    issues.push({
      field: "recipient.name",
      message: "Recipient name is required",
    });
  }
  if (!input.basis?.trim()) {
    issues.push({ field: "basis", message: "Factual basis is required" });
  }
  if (!input.deadline?.trim()) {
    issues.push({ field: "deadline", message: "Deadline is required" });
  }
  // A monetary amount is required for everything except fine disputes (where
  // the user may be contesting rather than claiming a sum).
  if (input.claimType !== "fine_dispute" && !input.amount?.trim()) {
    issues.push({ field: "amount", message: "Amount is required" });
  }
  return issues;
}

// ─── Composition ─────────────────────────────────────────────────────────────

/** Renders a party block ("Name\nAddress") with the address optional. */
function partyBlock(p: Party): string {
  const name = p.name.trim();
  const addr = (p.address ?? "").trim();
  return addr ? `${name}\n${addr}` : name;
}

/** Formats "850.00 EUR"; tolerant of a blank amount. */
function formatAmount(input: LetterInput): string {
  const amt = (input.amount ?? "").trim();
  if (!amt) return "";
  const cur = (input.currency ?? "EUR").trim() || "EUR";
  return `${amt} ${cur}`;
}

/**
 * Builds the full demand letter. Deterministic given its input. The returned
 * markdown always ends with the (non-removable) disclaimer line.
 */
export function buildLetter(input: LetterInput): LetterResult {
  const s = stringsFor(input.lang);
  const norms = normsFor(input.claimType, input.jurisdiction);

  const amountStr = formatAmount(input);
  const claimLabel = s.claimLabel[input.claimType];
  const ref = (input.reference ?? "").trim();
  const subject = ref
    ? `${s.subjectPrefix}: ${claimLabel} — ${s.refLabel} ${ref}`
    : `${s.subjectPrefix}: ${claimLabel}`;

  const lines: string[] = [];

  // Date.
  lines.push(input.todayIso, "");

  // Recipient + sender blocks.
  lines.push(`**${s.toLabel}:**`, partyBlock(input.recipient), "");
  lines.push(`**${s.fromLabel}:**`, partyBlock(input.sender), "");

  if (ref) {
    lines.push(`**${s.refLabel}:** ${ref}`, "");
  }

  // Subject.
  lines.push(`## ${subject}`, "");

  // Facts.
  lines.push(`### ${s.factsHeading}`, input.basis.trim(), "");

  // Demand.
  lines.push(`### ${s.demandHeading}`);
  lines.push(s.demandSentence.replace("{amount}", amountStr || "—"), "");

  // Legal basis (cited norms). Omitted entirely when there are no norms.
  if (norms.length > 0) {
    lines.push(`### ${s.legalHeading}`);
    for (const n of norms) {
      lines.push(`- **${n.label}** — ${n.note}`);
    }
    lines.push("");
  }

  // Deadline.
  lines.push(`### ${s.deadlineHeading}`);
  lines.push(
    s.deadlineSentence.replace("{deadline}", input.deadline.trim()),
    ""
  );

  // Consequences.
  lines.push(`### ${s.consequencesHeading}`, s.consequencesText, "");

  // Closing + signature.
  lines.push(
    s.closing,
    "",
    `_${s.signatureLabel}:_ ${input.sender.name.trim()}`,
    ""
  );

  // Mandatory disclaimer (UPL mitigation) — always last, never removable.
  lines.push("---", `_${s.disclaimer}_`);

  return {
    markdown: lines.join("\n"),
    norms,
    subject,
  };
}

// ─── Auto-fill from profile / case (mirrors template-fill.buildAutoValues) ───

export interface ProfileRow {
  full_name?: string | null;
  email?: string | null;
}

export interface CaseRow {
  title?: string | null;
  court_case_number?: string | null;
}

/**
 * Derives a default sender Party + reference from the signed-in user's profile
 * and an optional case. The wizard pre-fills these but the user can override
 * every field before composing.
 */
export function autoSender(opts: {
  profile?: ProfileRow | null;
  caseRow?: CaseRow | null;
}): { sender: Party; reference: string | null } {
  const p = opts.profile ?? {};
  const c = opts.caseRow ?? {};
  const name = (p.full_name ?? "").trim();
  const email = (p.email ?? "").trim();
  return {
    sender: {
      name,
      address: email || null,
    },
    reference: (c.court_case_number ?? "").trim() || null,
  };
}
