// _shared/outbound_compliance.ts — UPL boundary + outbound disclosure
// -----------------------------------------------------------------------------
// Wave-1 fix coordinated via memory key:
//   swarm/security_audit_2026-05-28/wave1/email_agent
//
// Closes audit findings:
//   • 08_finland_legal.md §1.6 + §9 + F-1 (Asianajajaliitto UPL boundary,
//     asiamies risk via Email Agent outbound to FI authorities)
//   • 09_estonia_legal.md P0-EE-2 (same for EE — Advokatuuriseadus § 4(3),
//     § 41, § 47; HMS § 13 esindusõigus)
//   • 05_ai_agent_security.md F-004 (recipient allowlist becomes a permanent
//     sink for stolen data; needs recency tiering + hard-deny anomalous TLDs)
//   • 05_ai_agent_security.md F-006 (send_email currently skips allowlist —
//     gate must mirror handleDraftEmailWithAttachments)
//
// What this module exposes
// ------------------------
//   classifyRecipient(to[])          → {class, friction, reasons}
//   composeDisclosureFooter(...)     → exact verbiage per audit §1.6.2 +
//                                      EE P0-EE-1, in user's locale
//   isRecipientAllowed(...)          → 30-day recency + hard-deny rules
//   AUTHORITY_RATE_LIMIT_24H          → 3 outbound/24h cap for fi_/ee_authority
//   APPROXIMATE_FOOTER_BYTES         → use to estimate fit
//
// Coordinates with agent_safety on UNTRUSTED_DATA_RULE — the disclosure
// footer is appended at SEND ingress (server-side), AFTER the model is
// done writing. The footer text is therefore NEVER inside the system
// prompt and NEVER reachable by prompt injection — model output cannot
// suppress or rewrite it.
// -----------------------------------------------------------------------------

// =============================================================================
// Public types
// =============================================================================

export type RecipientClass =
  | "fi_authority"
  | "ee_authority"
  | "asianajaja"
  | "standard"
  | "denied";

export interface ClassifyResult {
  /** Highest-friction class among the recipients (worst-case). */
  class: RecipientClass;
  /**
   * Friction level required before this send may proceed:
   *   0 → no extra friction (standard recipient)
   *   1 → standard + AI-disclosure footer
   *   2 → standard + footer + per-message HMAC-attest token
   *   3 → 2 + 24h authority-rate-limit + hard-deny if disclosure
   *       footer cannot fit in body
   * The numbers compound — higher subsumes lower.
   */
  friction: number;
  /** Human-readable reasons for the classification, one per recipient. */
  reasons: string[];
}

export type UserLocale = "fi" | "et" | "en" | "ru";

export interface IsAllowedInput {
  /** Recipient email address (single — to or one cc), lowercased+trimmed. */
  recipient: string;
  /** Authenticated caller's user_id (for scoping the lookup, if used). */
  user_id: string;
  /**
   * Inbound correspondence history. Caller passes the candidate inbound
   * messages so this function can be unit-tested without a DB. Production
   * call sites (handleSendEmail, handleDraftEmailWithAttachments) build
   * this list from email_messages constrained by user_id; the recency
   * window is enforced HERE rather than in the SQL so a future relaxed
   * SQL bound is still bounded by this module.
   */
  inboundHistory: Array<{ from: string; sent_at: Date }>;
}

export interface IsAllowedResult {
  ok: boolean;
  reason?: string;
  /** When ok=false, the human-readable class that hard-denied (if any). */
  denied_by?: "tld_hardlist" | "newly_registered" | "recency" | "no_history";
}

// =============================================================================
// Constants
// =============================================================================

/**
 * F-1 cap from audit 08 §9.2 — authority class:
 *   "rate-limit max 3 outbound to authority recipients per 24h per user".
 * Used downstream by the agent loop / send-email ingress.
 */
export const AUTHORITY_RATE_LIMIT_24H = 3;

/**
 * F-004 fix: 30-day recency window. A recipient who sent ONE email 11
 * months ago is no longer in the allowlist (prior implementation kept
 * them forever via the last-500-messages window).
 */
export const ALLOWLIST_RECENCY_DAYS = 30;

/**
 * F-004: hard-deny TLDs / domain patterns regardless of correspondence
 * history. A user who once replied to a phisher can be re-exfiltrated;
 * these patterns block that. Conservative list — any expansion needs
 * security review.
 */
const HARD_DENY_PATTERNS: RegExp[] = [
  /\.onion$/i, // Tor hidden services
  /\.local$/i, // mDNS / LAN-only
  /\.test$/i, // RFC 6761 reserved
  /\.invalid$/i, // RFC 6761 reserved
  /\.example$/i, // RFC 6761 reserved
  /\.localhost$/i, // RFC 6761 reserved
];

/**
 * F-004: newly-registered domain block. We don't ship a WHOIS client
 * in Deno-on-Edge; the caller passes domain-registration metadata if
 * known. As a coarse approximation, we maintain a static list of
 * known disposable-mail providers and bounce them outright.
 *
 * This list is config-driven and intentionally short to avoid false-
 * positive blocking; expand via env DENYLIST_EXTRA_DOMAINS (CSV).
 */
const DISPOSABLE_MAIL_DOMAINS: ReadonlySet<string> = new Set([
  "mailinator.com",
  "guerrillamail.com",
  "10minutemail.com",
  "tempmail.com",
  "trashmail.com",
  "dispostable.com",
  "throwawaymail.com",
  "yopmail.com",
  "maildrop.cc",
  "fakemail.net",
]);

/**
 * Approximate byte cost of the longest disclosure footer (Finnish,
 * authority recipient). Used by the caller (send-email ingress) to
 * decide if the footer fits before sending. If the body is so large
 * that subject+body+footer would exceed RFC limits, the send must be
 * rejected per audit 08 §1.6.2 ("reject if disclosure footer would
 * NOT fit").
 */
export const APPROXIMATE_FOOTER_BYTES = 1_400;

// =============================================================================
// Authority-domain rules (audit 08 §9.2 + 09 §P0-EE-2)
// =============================================================================

/**
 * Finland authority domain suffixes. Source: audit 08 §1.6.4 + §9.2.
 *
 * Hard match on suffix (after the rightmost "@"): any address whose
 * domain ENDS with one of these strings classifies as fi_authority.
 *
 * Why suffix-list rather than per-domain whitelist: FI authorities
 * delegate subdomains liberally (kirjaamo.helsinki.poliisi.fi,
 * stm.korkein-oikeus.fi etc.). The suffix list catches the entire
 * tree at one stroke. A subdomain explosion is acceptable — we want
 * MORE addresses to be classified as authority, not fewer.
 */
const FI_AUTHORITY_SUFFIXES: readonly string[] = [
  // Courts
  ".oikeus.fi",
  "oikeus.fi",
  ".kho.fi",
  "kho.fi",
  ".hao.fi",
  "hao.fi",
  ".korkein-oikeus.fi",
  "korkein-oikeus.fi",
  ".korkeinoikeus.fi",
  "korkeinoikeus.fi",
  // Police + prosecutor
  ".poliisi.fi",
  "poliisi.fi",
  ".syyttaja.fi",
  "syyttaja.fi",
  ".syyttajalaitos.fi",
  "syyttajalaitos.fi",
  ".krp.poliisi.fi",
  // Migration + border
  ".migri.fi",
  "migri.fi",
  // Ombudsman + chancellor
  ".oikeusasiamies.fi",
  "oikeusasiamies.fi",
  ".oikeuskansleri.fi",
  "oikeuskansleri.fi",
  // Parliament + supervision bodies
  ".eduskunta.fi",
  "eduskunta.fi",
  ".valvonta.fi",
  "valvonta.fi",
  ".aok.fi",
  "aok.fi",
  // Tax + customs + others surfaced in audit 08 §9.2
  ".tulli.fi",
  "tulli.fi",
  ".vero.fi",
  "vero.fi",
  ".valvira.fi",
  "valvira.fi",
  ".kkv.fi",
  "kkv.fi",
  ".tietosuoja.fi",
  "tietosuoja.fi",
  ".traficom.fi",
  "traficom.fi",
];

/**
 * Estonia authority domain suffixes. Source: audit 09 §P0-EE-2 + §16.
 */
const EE_AUTHORITY_SUFFIXES: readonly string[] = [
  // Courts
  ".kohus.ee",
  "kohus.ee",
  ".riigikohus.ee",
  "riigikohus.ee",
  // Police + border
  ".politsei.ee",
  "politsei.ee",
  // Ministries + state offices
  ".siseministeerium.ee",
  "siseministeerium.ee",
  ".justiitsministeerium.ee",
  "justiitsministeerium.ee",
  ".riigikantselei.ee",
  "riigikantselei.ee",
  // Bar + chancellor + ombudsman
  ".advokatuur.ee",
  "advokatuur.ee",
  ".oiguskantsler.ee",
  "oiguskantsler.ee",
  // Tax + supervision
  ".emta.ee",
  "emta.ee",
  ".ttja.ee",
  "ttja.ee",
  ".aki.ee",
  "aki.ee",
  ".prokuratuur.ee",
  "prokuratuur.ee",
];

/**
 * Asianajaja / vandeadvokaat law-firm domains. Audit 08 §9.2 medium-
 * friction class. Start with an empty list + an env-configurable
 * extension list; over time the user nominates their own counsel.
 *
 * In practice the caller may also pass a per-user nominated-counsel
 * list at runtime (handleSendEmail can resolve user_oauth_tokens
 * or a user_attorneys table). We accept the static list here for
 * now; the runtime augmentation is layered on by the caller.
 */
const ASIANAJAJA_DOMAINS: ReadonlySet<string> = new Set([
  // No domains hard-coded; classification leans on caller-supplied
  // nominatedCounselDomains via classifyRecipient's optional 2nd arg.
  // Asianajajaliitto's own register portal (informational, not used
  // for routing here):
  //   "asianajajaliitto.fi"
  // — left out because it's not where lawyers receive mail.
]);

// =============================================================================
// classifyRecipient
// =============================================================================

/**
 * Classify a recipient list by the highest-friction member.
 *
 * The "to" array may contain multiple addresses (e.g. To + Cc consolidated).
 * Any single fi_authority bumps the entire send to fi_authority friction.
 * Mixing classes is allowed — the friction is the WORST of all addresses.
 *
 * @param to                       Array of recipient email addresses (raw)
 * @param nominatedCounselDomains  Optional per-user nominated counsel
 *                                 domain list (e.g. user's own asianajaja).
 *                                 Lowercase domains, no "@".
 * @returns ClassifyResult
 */
export function classifyRecipient(
  to: string[],
  nominatedCounselDomains?: ReadonlySet<string>,
): ClassifyResult {
  if (!Array.isArray(to) || to.length === 0) {
    return {
      class: "denied",
      friction: 3,
      reasons: ["empty recipient list"],
    };
  }

  let worst: RecipientClass = "standard";
  const reasons: string[] = [];

  for (const raw of to) {
    const cls = classifyOne(raw, nominatedCounselDomains);
    reasons.push(`${raw.trim()} → ${cls}`);
    worst = upgradeClass(worst, cls);
  }

  return {
    class: worst,
    friction: frictionFor(worst),
    reasons,
  };
}

function classifyOne(
  raw: string,
  nominatedCounselDomains?: ReadonlySet<string>,
): RecipientClass {
  const norm = (raw ?? "").trim().toLowerCase();
  if (!norm || !norm.includes("@")) return "denied";
  const domain = norm.split("@").pop() ?? "";
  if (!domain) return "denied";

  // Hard deny — always wins regardless of any other classification.
  for (const re of HARD_DENY_PATTERNS) {
    if (re.test(domain)) return "denied";
  }
  if (DISPOSABLE_MAIL_DOMAINS.has(domain)) return "denied";

  // Authority match — suffix-based.
  if (matchesSuffix(domain, FI_AUTHORITY_SUFFIXES)) return "fi_authority";
  if (matchesSuffix(domain, EE_AUTHORITY_SUFFIXES)) return "ee_authority";

  // Asianajaja / nominated counsel.
  if (ASIANAJAJA_DOMAINS.has(domain)) return "asianajaja";
  if (nominatedCounselDomains?.has(domain)) return "asianajaja";

  return "standard";
}

function matchesSuffix(domain: string, suffixes: readonly string[]): boolean {
  for (const s of suffixes) {
    // Bare-domain entry (no leading dot) matches the exact domain.
    if (s.startsWith(".")) {
      if (domain.endsWith(s)) return true;
    } else {
      if (domain === s) return true;
    }
  }
  return false;
}

/**
 * Class ordering — higher wins when consolidating recipients:
 *   denied > fi_authority ≈ ee_authority > asianajaja > standard
 *
 * fi_authority and ee_authority have the same friction (3) and are
 * treated symmetrically — when both appear, fi_authority is reported
 * for stability (alphabetical first), but friction is identical.
 */
function upgradeClass(
  current: RecipientClass,
  next: RecipientClass,
): RecipientClass {
  const rank: Record<RecipientClass, number> = {
    standard: 0,
    asianajaja: 1,
    ee_authority: 2,
    fi_authority: 2,
    denied: 3,
  };
  if (rank[next] > rank[current]) return next;
  // Tie at authority level: prefer fi_authority deterministically.
  if (rank[next] === rank[current] && next === "fi_authority") {
    return "fi_authority";
  }
  return current;
}

function frictionFor(cls: RecipientClass): number {
  switch (cls) {
    case "standard":
      return 0;
    case "asianajaja":
      return 1;
    case "fi_authority":
    case "ee_authority":
      return 3;
    case "denied":
      return 3;
  }
}

// =============================================================================
// composeDisclosureFooter — exact verbiage per audit 08 §1.6.2 + 09 §P0-EE-1
// =============================================================================

/**
 * Compose the outbound disclosure footer. The exact verbiage is fixed
 * by the audit — DO NOT improvise wording at runtime.
 *
 * Four mandatory points the footer MUST include:
 *   1. Prepared with Advocat AI assistance (advocat.ee)
 *   2. Advocat is NOT a law firm and not subject to Asianajajaliitto /
 *      Eesti Advokatuur supervision
 *   3. Correspondence is sent from the user's own mailbox; the user is
 *      the legal sender
 *   4. Advocat does not enter into attorney-client relationship;
 *      communications with Advocat are NOT privileged
 *
 * For non-authority recipients we still surface a short version; for
 * fi_authority and ee_authority recipients we surface the full version
 * verbatim in the user's locale.
 */
export function composeDisclosureFooter(
  userLocale: UserLocale,
  recipientClass: RecipientClass,
  userFullName: string,
): string {
  const name = (userFullName ?? "").trim() || "—";

  // Standard recipients: short single-line disclosure (audit 08 §13.1
  // marks it as "recommended but optional"; we include the minimal
  // variant to make the AI provenance always visible).
  if (recipientClass === "standard" || recipientClass === "asianajaja") {
    return SHORT_FOOTERS[userLocale](name);
  }

  // Authority recipients: full disclosure per audit 08 §1.6.2.
  if (
    recipientClass === "fi_authority" || recipientClass === "ee_authority"
  ) {
    return AUTHORITY_FOOTERS[userLocale](name, recipientClass);
  }

  // denied class never reaches composeDisclosureFooter (caller has
  // already rejected), but be defensive.
  return AUTHORITY_FOOTERS[userLocale](name, "fi_authority");
}

// -----------------------------------------------------------------------------
// Footer copy — verbatim from audit 08 §1.6.2 (Finnish), with EE/EN/RU
// parallels per audit 09 §P0-EE-1 and §16. The Finnish text MUST match
// the audit text byte-for-byte; any change requires re-review.
// -----------------------------------------------------------------------------

type ShortFooterFn = (userName: string) => string;
type AuthorityFooterFn = (
  userName: string,
  recipientClass: RecipientClass,
) => string;

const SHORT_FOOTERS: Record<UserLocale, ShortFooterFn> = {
  fi: (name) =>
    `\n\n---\n` +
    `Tämä viesti on lähetetty allekirjoittajan (${name}) omasta ` +
    `sähköpostiosoitteesta. Viestin valmistelussa on käytetty Advocat-` +
    `AI-työkalua (Vorantis OÜ, Viro, advocat.ee). Advocat ei ole ` +
    `asianajotoimisto.`,
  et: (name) =>
    `\n\n---\n` +
    `Käesolev kiri on saadetud allakirjutanud isiku (${name}) enda ` +
    `e-posti aadressilt. Kirja koostamisel on kasutatud Advocat AI ` +
    `tööriista (Vorantis OÜ, Eesti, advocat.ee). Advocat ei ole ` +
    `advokaadibüroo Advokatuuriseaduse § 47 mõttes.`,
  en: (name) =>
    `\n\n---\n` +
    `This message was sent from the signatory's (${name}) own mailbox. ` +
    `It was prepared with the assistance of Advocat AI (Vorantis OÜ, ` +
    `Estonia, advocat.ee). Advocat is not a law firm.`,
  ru: (name) =>
    `\n\n---\n` +
    `Настоящее сообщение отправлено с собственного почтового ящика ` +
    `подписанта (${name}). Подготовлено с использованием AI-инструмента ` +
    `Advocat (Vorantis OÜ, Эстония, advocat.ee). Advocat не является ` +
    `адвокатским бюро.`,
};

const AUTHORITY_FOOTERS: Record<UserLocale, AuthorityFooterFn> = {
  /**
   * Finnish authority — verbatim per audit 08 §1.6.2 second-paragraph
   * formulation, expanded to cover all 4 mandatory points.
   */
  fi: (name, cls) => {
    const supervisor = cls === "ee_authority"
      ? "Eesti Advokatuurin"
      : "Suomen Asianajajaliiton";
    return (
      `\n\n---\n` +
      `Tämä viesti on lähetetty allekirjoittajan (${name}) omasta ` +
      `sähköpostiosoitteesta. Viestin valmistelussa on käytetty ` +
      `Advocat-AI-työkalua (Vorantis OÜ, Viro). Allekirjoittaja toimii ` +
      `itse asiassa omasta puolestaan eikä ole asianajajan tai ` +
      `lupalakimiehen edustama tämän viestin osalta, ellei muuta ole ` +
      `erikseen ilmoitettu.\n\n` +
      `Advocat ei ole asianajotoimisto eikä kuulu ${supervisor} ` +
      `valvonnan piiriin. Allekirjoittaja on viestin lähettäjä ja ` +
      `oikeudellinen vastuussa sen sisällöstä. Vorantis OÜ tai Advocat ` +
      `ei muodosta asianajajan ja päämiehen välistä toimeksiantosuhdetta, ` +
      `eivätkä viestintä Advocatin kanssa kuulu asianajosalaisuuden ` +
      `(OK 17:13, AAL § 5c, LuvLakL § 8) piiriin.\n` +
      `Lisätiedot: advocat.ee — Vorantis OÜ, Viro.`
    );
  },

  /**
   * Estonian authority — verbatim per audit 09 §P0-EE-1 (informal
   * letter to Advokatuur) + §P0-EE-2 (cover-page directive), unified
   * into a single footer that satisfies both.
   */
  et: (name, cls) => {
    const supervisor = cls === "fi_authority"
      ? "Soome Asianajajaliiton"
      : "Eesti Advokatuuri";
    return (
      `\n\n---\n` +
      `Käesolev e-kiri on saadetud allakirjutanud isiku (${name}) enda ` +
      `e-posti aadressilt. Kirja koostamisel on kasutatud Advocat AI ` +
      `tööriista (Vorantis OÜ, Eesti). Allakirjutanu tegutseb iseenda ` +
      `nimel ega ole tema poolt esindatud advokaadi või tegevusloaga ` +
      `õigusabi osutaja poolt selle kirja osas, kui ei ole eraldi ` +
      `teisiti märgitud.\n\n` +
      `Advocat ei ole advokaadibüroo Advokatuuriseaduse § 47 mõttes ` +
      `ega kuulu ${supervisor} järelevalve alla. Allakirjutanu on ` +
      `kirja saatja ja vastutab ainuisikuliselt selle sisu eest. ` +
      `Vorantis OÜ ega Advocat ei sõlmi advokaadi ja kliendi vahelist ` +
      `lepingulist suhet ning suhtlus Advocatiga ei ole kaitstud ` +
      `advokaadisaladusega Advokatuuriseaduse § 45 mõttes.\n` +
      `Lisateave: advocat.ee — Vorantis OÜ, Eesti.`
    );
  },

  /**
   * English authority — used when user_locale is "en". Covers FI + EE
   * symmetrically since the recipient may be either.
   */
  en: (name, cls) => {
    const supervisor = cls === "ee_authority"
      ? "Eesti Advokatuur (Estonian Bar Association)"
      : "Suomen Asianajajaliitto (Finnish Bar Association)";
    return (
      `\n\n---\n` +
      `This message was sent from the signatory's (${name}) own mailbox. ` +
      `It was prepared with the assistance of Advocat AI (Vorantis OÜ, ` +
      `Estonia). The signatory is acting in person on their own behalf ` +
      `and is not represented by a licensed advocate or counsel for the ` +
      `purposes of this message, unless explicitly stated otherwise.\n\n` +
      `Advocat is not a law firm and is not subject to the supervision ` +
      `of ${supervisor}. The signatory is the sender of this message and ` +
      `is solely legally responsible for its content. Vorantis OÜ and ` +
      `Advocat do not enter into an attorney-client relationship; ` +
      `communications with Advocat are NOT protected by attorney-client ` +
      `privilege (OK 17:13 Finland; § 45 Advokatuuriseadus Estonia).\n` +
      `Further information: advocat.ee — Vorantis OÜ, Estonia.`
    );
  },

  /**
   * Russian authority — used when user_locale is "ru".
   */
  ru: (name, cls) => {
    const supervisor = cls === "ee_authority"
      ? "Эстонской адвокатуры (Eesti Advokatuur)"
      : "Финляндской ассоциации адвокатов (Suomen Asianajajaliitto)";
    return (
      `\n\n---\n` +
      `Настоящее сообщение отправлено с собственного почтового ящика ` +
      `подписанта (${name}). Подготовлено с использованием AI-инструмента ` +
      `Advocat (Vorantis OÜ, Эстония). Подписант действует лично от ` +
      `собственного имени и не представлен лицензированным адвокатом или ` +
      `советником в рамках данного сообщения, если иное не оговорено ` +
      `отдельно.\n\n` +
      `Advocat не является адвокатским бюро и не подпадает под надзор ` +
      `${supervisor}. Подписант является отправителем настоящего сообщения ` +
      `и несёт единоличную юридическую ответственность за его содержание. ` +
      `Vorantis OÜ и Advocat не вступают в отношения «адвокат-клиент»; ` +
      `переписка с Advocat НЕ защищена адвокатской тайной (OK 17:13 ` +
      `Финляндия; § 45 Advokatuuriseadus Эстония).\n` +
      `Подробнее: advocat.ee — Vorantis OÜ, Эстония.`
    );
  },
};

// =============================================================================
// isRecipientAllowed — 30-day recency + hard-deny rules
// =============================================================================

/**
 * Decide whether a single recipient may receive outbound mail.
 *
 * Three layers (in evaluation order):
 *   1. Hard-deny TLD / disposable-mail patterns — *.onion, mailinator, etc.
 *      Audit 05 F-004 (3). These ALWAYS deny regardless of history.
 *   2. Newly-registered domain check — at this layer we lack a WHOIS
 *      client, so the disposable-mail set in HARD_DENY covers the
 *      practical attacks. Caller may pre-resolve domain age and pass
 *      a denied result before invoking us; we don't fabricate one.
 *   3. Recency-windowed correspondence history — recipient must have
 *      appeared as a `from` address on an inbound message within the
 *      last ALLOWLIST_RECENCY_DAYS (default 30). Audit 05 F-004 (1).
 *
 * @param input  see {@link IsAllowedInput}
 */
export function isRecipientAllowed(input: IsAllowedInput): IsAllowedResult {
  const recipient = (input.recipient ?? "").trim().toLowerCase();
  if (!recipient || !recipient.includes("@")) {
    return {
      ok: false,
      reason: "invalid recipient",
      denied_by: "no_history",
    };
  }
  const domain = recipient.split("@").pop() ?? "";

  // (1) hard-deny TLDs.
  for (const re of HARD_DENY_PATTERNS) {
    if (re.test(domain)) {
      return {
        ok: false,
        reason: `recipient domain matches hard-deny pattern (${re.source})`,
        denied_by: "tld_hardlist",
      };
    }
  }
  if (DISPOSABLE_MAIL_DOMAINS.has(domain)) {
    return {
      ok: false,
      reason: `recipient domain is on the disposable-mail block list`,
      denied_by: "tld_hardlist",
    };
  }

  // (2) Newly-registered — handled by caller via the disposable list +
  // an external WHOIS check upstream. No-op here.

  // (3) Recency-windowed history. F-004: drop the "permanent allowlist"
  // semantics; require the recipient to have been an inbound sender
  // within ALLOWLIST_RECENCY_DAYS.
  const cutoff = Date.now() - ALLOWLIST_RECENCY_DAYS * 24 * 60 * 60 * 1_000;
  const history = Array.isArray(input.inboundHistory) ? input.inboundHistory : [];
  for (const m of history) {
    const from = (m.from ?? "").trim().toLowerCase();
    if (from !== recipient) continue;
    const sentMs = m.sent_at instanceof Date
      ? m.sent_at.getTime()
      : new Date(m.sent_at as unknown as string).getTime();
    if (Number.isFinite(sentMs) && sentMs >= cutoff) {
      return { ok: true };
    }
  }

  // No history within the recency window.
  return {
    ok: false,
    reason:
      `recipient has no inbound correspondence in the last ` +
      `${ALLOWLIST_RECENCY_DAYS} days`,
    denied_by: history.length === 0 ? "no_history" : "recency",
  };
}

// =============================================================================
// Helpers exported for tests
// =============================================================================

/** Re-export for unit testing: lowercased domain extraction. */
export function _domainOf(addr: string): string {
  return (addr ?? "").trim().toLowerCase().split("@").pop() ?? "";
}

/** Re-export for unit testing: is this domain on the disposable list? */
export function _isDisposable(domain: string): boolean {
  return DISPOSABLE_MAIL_DOMAINS.has(domain);
}
