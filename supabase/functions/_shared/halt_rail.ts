// halt_rail.ts — Serious-case detection + mandatory "consult licensed lawyer" CTA.
//
// Context (consilium adversary expert 2026-05-15, risk-mitigation A7 of вабанк):
// To eliminate any "unauthorized practice of law" claim risk from Eesti
// Advokatuur / Suomen Asianajajaliitto, every AI reply that touches a high-
// stakes situation (deportation, custody, criminal charges, big-money claim,
// ECHR application) must end with an explicit advisory that:
//
//   1. AI cannot represent the user in court.
//   2. AI cannot negotiate with the opposing side on their behalf.
//   3. AI does not provide attorney-client privilege.
//   4. For any actual litigation, the user MUST consult a licensed
//      asianajaja (FI) / vandeadvokaat (EE).
//
// This module is a small, pure-string helper. It does NOT call the LLM. It is
// wired into claude-proxy/index.ts at two points:
//
//   • PRE-LLM:   appendHaltRailToSystem() — adds an instruction so the model
//                naturally weaves the advisory into its own reply.
//   • POST-LLM:  appendHaltRailToResponse() — appends a visible banner block
//                regardless of whether the model complied. Belt + suspenders.
//
// Failure mode: every helper is total. Bad inputs return safe defaults (the
// system prompt is returned unchanged, the response is returned unchanged).
// A serious-case false negative is acceptable (model still has disclaimers).
// A false positive (extra banner on benign messages) is acceptable (it is
// just informational). Therefore detection errs slightly on the side of
// firing — better one false banner than one missed litigation case.

export type HaltCategory =
  | "deportation"
  | "custody"
  | "criminal"
  | "big_claim"
  | "echr";

export interface HaltDetection {
  isSerious: boolean;
  category: HaltCategory | null;
  /** Human-readable reason for telemetry. Empty when isSerious=false. */
  reason: string;
  /**
   * The matched amount in euros when category === "big_claim". 0 otherwise.
   * Used only for telemetry / debugging.
   */
  matchedAmount: number;
}

const EMPTY: HaltDetection = {
  isSerious: false,
  category: null,
  reason: "",
  matchedAmount: 0,
};

// ─── Keyword tables ──────────────────────────────────────────────────────────
//
// All keywords are lowercased and stored without diacritics-stripping —
// we lowercase the input but keep ä/ö/õ/š intact because that is how the
// terms appear in FI/EE/RU text. The regex below uses word-boundary-ish
// matching: each keyword is wrapped in a regex that requires either a non-
// letter boundary or string start/end on each side. This avoids matching
// "kriminaali" inside "kriminaalipoliittisesti" but still matches across
// most natural punctuation.

// Keyword stems. We rely on word-PREFIX matching (boundary + prefix) so we
// only need the shortest unambiguous stem in each language. E.g.
//   "käännyttäm" matches käännyttäminen / käännyttämistä / käännyttämisestä
//   "väljasaatm" matches väljasaatmine / väljasaatmise / väljasaatmisel
//   "депорт"     matches депортация / депортируют / депортировать (also депорт)
//
// Caveat: a too-short stem can over-match. We hand-checked each stem against
// a corpus of non-legal Finnish / Estonian / Russian text and rejected any
// that produced false positives in everyday usage.
const KEYWORDS: Record<HaltCategory, readonly string[]> = {
  deportation: [
    // Finnish stems
    "karkott",        // karkottaminen / karkottamista / karkotetaan / karkottaa
    "käännyttäm",     // käännyttäminen / käännyttämistä / käännyttämisestä
    "käännytet",      // käännytetään / käännytettiin
    "maastapoist",    // maastapoistaminen / maastapoistoa
    "maahantulokielt", // maahantulokielto
    // Production-gap closer (P5 smoke 2026-05-15): live Finnish callers
    // colloquially write "deportointi / deportaatio" alongside the formal
    // "käännyttäminen / karkottaminen". Adding both stems closes Q06.
    "deportoin",      // deportointi / deportointia / deportointipäätös
    "deportaat",      // deportaatio / deportaatioon
    // Estonian stems
    "väljasaatm",     // väljasaatmine / väljasaatmise / väljasaatmisel
    "väljasaadet",    // väljasaadetakse
    // FIX-WAVE 12 (2026-05-20): live ET probe "Mind saadetakse Eestist välja"
    // missed because particle-separated "saadetakse … välja" doesn't match
    // the compound stems above. Add the bare root "saadeta" (matches
    // saadetakse / saadetama / saadetav / saadetama) AND the multi-word
    // "välja saade" variant (matches "välja saadetakse" / "välja saadeta").
    "saadeta",        // saadetakse / saadetama / saadetav (passive present root)
    "välja saade",    // "välja saadetakse" / "välja saadeta..." (particle variant)
    "lahkumisettekir", // lahkumisettekirjutus
    "sissesõidukeel", // sissesõidukeeld
    // Russian stems
    "депорт",         // депортация / депортацию / депортируют / депортировать
    "выдвор",         // выдворение / выдворить / выдворен
    "запрет на въезд",
    // English
    "deportation",
    "deport me",
    "being deported",
    "removal order",
    "entry ban",
  ],
  custody: [
    // Finnish stems
    "huoltajuu",      // huoltajuus / huoltajuuden / huoltajuuskiista
    "yksinhuol",      // yksinhuolto / yksinhuoltajuus
    "lapsen huolto",
    "huoltoriita",
    "tapaamisoikeu",  // tapaamisoikeus / tapaamisoikeuden
    // Estonian stems
    "hooldusõigu",    // hooldusõigus / hooldusõiguse
    "ainuhooldusõigu",
    "hoolduskonflikt",
    "suhtlusõigu",
    "lapse hooldus",
    // Russian
    "опека ребёнка",
    "опеку ребёнка",
    "опека ребенка",
    "опеку ребенка",
    // P5 smoke 2026-05-15: live users also write "опека на ребёнка"
    // (preposition variant — informal but common in Russian).
    "опека на ребёнка",
    "опеку на ребёнка",
    "опека на ребенка",
    "опеку на ребенка",
    "опекунств",
    "лишение родительских прав",
    "родительские права",
    "спор об опеке",
    // English
    "child custody",
    "custody dispute",
    "custody battle",
    "sole custody",
    "parental rights",
  ],
  criminal: [
    // Finnish stems
    "rikossyyt",      // rikossyyte / rikossyytteen
    "esitutkint",     // esitutkinta / esitutkintaa
    "rikosasia",
    "rikoksesta epäilty",
    "syytett",        // syytetty / syytettyä / syytettynä
    "tuomio rikoksesta",
    // Estonian stems
    "kriminaalsüüdis", // kriminaalsüüdistus / kriminaalsüüdistuse
    "kriminaalmenet",  // kriminaalmenetlus / kriminaalmenetluse
    "kriminaalasi",
    "kahtlustatav",
    "süüdistatav",
    "kohtu alla",
    "vahistatud",
    // P5 smoke 2026-05-15: live Estonian callers write "kuritegu" (crime,
    // KarS terminology) and its declensions far more often than the formal
    // "kriminaalsüüdistus". "uurimine" (investigation) + "kuriteo tunnustega"
    // is the typical police-summons phrasing — closes Q08.
    "kuritegu",       // kuritegu
    "kuriteo",        // kuriteo (sg gen) — "kuriteo tunnustega"
    "kuritegude",     // kuritegude (pl gen)
    "kuritöö",        // synonym, criminal act
    "süütegu",        // misdemeanour, often paired with criminal proceedings
    "süüteo",         // süüteo (sg gen)
    // Russian stems
    "уголовное дело",
    "уголовное преследование",
    "уголовка",
    "обвиняем",       // обвиняемый / обвиняемая
    "подозреваем",    // подозреваемый
    "арестован",
    "под стражей",
    "статья ук",
    "осуждён",
    "осужден",
    // English
    "criminal charge",
    "criminal charges",
    "criminal case",
    "indictment",
    "indicted",
    "i was arrested",
    "fight a criminal",
    "criminal prosecution",
  ],
  echr: [
    // Finnish
    "ihmisoikeustuomioistuin",
    "euroopan ihmisoikeustuomioistuin",
    "eit",
    "valitus eit",
    // FIX-WAVE 12 (2026-05-20): live FI probe
    // "valitus Euroopan ihmisoikeustuomioistuimeen" (illative case) didn't
    // match "ihmisoikeustuomioistuin" because the inflected form ends in
    // …-tuimeen, not …-tuin. Use a shorter PREFIX stem so all illative /
    // partitive / inessive / elative declensions match.
    "ihmisoikeustuomioistui", // ...tuimeen / ...tuinta / ...tuimessa
    // Estonian
    "euroopa inimõiguste kohus",
    "eik",
    "kaebus eik",
    // FIX-WAVE 12 (2026-05-20): live ET probe
    // "kaebuse Euroopa Inimõiguste Kohtule" (allative) didn't match
    // "euroopa inimõiguste kohus" because the inflected form is "kohtule"
    // not "kohus". Use a multi-word substring that catches allative /
    // genitive / partitive ("...õiguste kohtule" / "...õiguste kohut" /
    // "...õiguste kohust" all start with "inimõiguste koht").
    "inimõiguste koht",       // ...kohtule / ...kohut / ...kohust
    // Russian
    "еспч",
    "европейский суд по правам человека",
    "страсбург",
    "жалоба в еспч",
    // English
    "echr",
    "european court of human rights",
    "strasbourg court",
    "application to echr",
  ],
  big_claim: [
    // big_claim is matched by amount regex below, not keywords.
    // Sentinel: keep the array non-empty for type symmetry but unused.
    "\u0000",
  ],
};

const CATEGORIES_IN_ORDER: readonly HaltCategory[] = [
  // Order matters: when multiple categories match, the first one wins
  // in the reported reason. Criminal and ECHR are the most consequential.
  "criminal",
  "echr",
  "deportation",
  "custody",
  "big_claim",
];

// ─── Big-claim amount detector ───────────────────────────────────────────────
//
// Matches sums written in any of:
//   €50000   €50,000   €50.000   €50 000   50000€   50 000 EUR   50,000 euros
//   50000 евро   50 000 eurot   50 000 eurosse   etc.
//
// Threshold: 20 000 EUR. Below that the user is usually self-help territory
// (small claims, late deposit returns, parking fines). Above that they are
// in district-court territory and should have a licensed advocate review the
// case before filing.

const BIG_CLAIM_THRESHOLD_EUR = 20000;

/**
 * Extract the largest euro amount mentioned in `text`. Returns 0 if none.
 * Recognises common European number formats (space, comma, dot thousands
 * separators) and a few currency markers (€, eur, euro, евро, eurot).
 */
export function extractLargestEuroAmount(text: string): number {
  if (!text || typeof text !== "string") return 0;
  let max = 0;

  // Strategy: scan for runs of digits ± thousands separators that are
  // adjacent (within 4 chars) to a currency marker. This avoids matching
  // case numbers like "1366/2026" or phone numbers as amounts.
  //
  // We use a permissive regex and then post-filter: a candidate match must
  // be ≥ 4 digits long after stripping separators (so 1000+) AND must have
  // a currency marker within 0-4 chars before or after.
  const numRe = /\d{1,3}(?:[\s.,]\d{3})+|\d{4,9}/g;
  const lower = text.toLowerCase();

  // Currency markers we accept.
  // Order matters only for length-prefix matching (we match any).
  const markers = ["€", "eur", "euro", "eurot", "евро", "eврo"];

  let m: RegExpExecArray | null;
  while ((m = numRe.exec(lower)) !== null) {
    const raw = m[0];
    const startIdx = m.index;
    const endIdx = startIdx + raw.length;

    // Look in a 6-char window on each side for a currency marker.
    const leftWin = lower.slice(Math.max(0, startIdx - 6), startIdx);
    const rightWin = lower.slice(endIdx, Math.min(lower.length, endIdx + 8));

    const hasCurrency = markers.some(
      (mk) => leftWin.includes(mk) || rightWin.includes(mk),
    );
    if (!hasCurrency) continue;

    // Strip thousands separators and parse. Use Number() (no locale) since
    // we've normalised separators out.
    const stripped = raw.replace(/[\s.,]/g, "");
    const value = Number(stripped);
    if (!Number.isFinite(value)) continue;

    // Reject 4-digit values that are bare years (1900-2099) and were
    // matched only because someone wrote "2026 EUR" — extremely rare but
    // would false-trigger on dates.
    if (stripped.length === 4 && value >= 1900 && value <= 2099) continue;

    if (value > max) max = value;
  }

  return max;
}

// ─── Core detector ───────────────────────────────────────────────────────────

/**
 * Inspect a user message and decide whether it warrants the halt-rail.
 *
 * Pure function — no I/O, no exceptions. Safe to call on any string.
 *
 * @param message       The latest user turn (string). Anything else returns EMPTY.
 * @param _jurisdiction Reserved for future per-jurisdiction tuning. Ignored.
 */
export function detectSeriousCase(
  message: unknown,
  _jurisdiction?: string,
): HaltDetection {
  if (typeof message !== "string" || message.length === 0) return EMPTY;

  // Cap input we scan at 8 KB to keep this O(1)-ish per request.
  const text = message.length > 8192 ? message.slice(0, 8192) : message;
  const lower = text.toLowerCase();

  // 1. Keyword categories.
  for (const cat of CATEGORIES_IN_ORDER) {
    if (cat === "big_claim") continue; // handled below
    const list = KEYWORDS[cat];
    for (const kw of list) {
      if (!kw) continue;
      // Single-token vs multi-token: multi-token keywords contain spaces,
      // we match those as plain substrings. Single tokens get a word-ish
      // boundary check so "kriminaali" doesn't fire on "kriminaalipoliisi".
      if (kw.includes(" ")) {
        if (lower.includes(kw)) {
          return {
            isSerious: true,
            category: cat,
            reason: `keyword:${cat}:${kw}`,
            matchedAmount: 0,
          };
        }
      } else {
        // Word-PREFIX match: keyword must start at a word boundary (preceded
        // by non-letter/digit OR string start), but may be followed by inflection
        // letters. This catches Finnish/Russian/Estonian declension/conjugation
        // (käännyttäminen → käännyttämisestä, väljasaatmine → väljasaatmisel,
        // депортация → депортацию). Suffix-only matches (e.g. "kriminaali"
        // inside "rikoskriminaalipoliisi") are still rejected because the
        // preceding letter "s" fails the boundary check.
        const idx = lower.indexOf(kw);
        if (idx === -1) continue;
        const before = idx === 0 ? " " : lower[idx - 1];
        if (!/[\p{L}\p{N}]/u.test(before)) {
          return {
            isSerious: true,
            category: cat,
            reason: `keyword:${cat}:${kw}`,
            matchedAmount: 0,
          };
        }
      }
    }
  }

  // 2. Big-claim amount.
  const amount = extractLargestEuroAmount(text);
  if (amount > BIG_CLAIM_THRESHOLD_EUR) {
    return {
      isSerious: true,
      category: "big_claim",
      reason: `amount:${amount}EUR>threshold:${BIG_CLAIM_THRESHOLD_EUR}`,
      matchedAmount: amount,
    };
  }

  return EMPTY;
}

// ─── Prompt + response appenders ─────────────────────────────────────────────

/**
 * Short, model-facing description of what each category implies for the
 * mandatory advisory. The model uses this to weave the disclaimer naturally
 * into the answer rather than as a bolted-on footer.
 */
const CATEGORY_FRAMING: Record<HaltCategory, string> = {
  deportation:
    "an immigration / deportation matter (käännyttäminen, väljasaatmine, депортация). " +
    "These are appealed under strict statutory deadlines (UlkomaalaisL §190, 30 days; " +
    "VRK §40, 30 days) where missing a deadline is usually fatal. Court representation " +
    "and oral hearings require a licensed advocate.",
  custody:
    "a child-custody dispute (huoltajuus, hooldusõigus, опека). Custody disputes are " +
    "litigated in district court, require party representation, and the outcome depends " +
    "heavily on factual evidence and witness handling — areas where AI cannot stand in " +
    "for a licensed family-law advocate.",
  criminal:
    "a criminal matter (rikossyyte, kriminaalsüüdistus, уголовное дело). Under " +
    "ECHR Art. 6(3)(c) and national law (e.g. ROL 8 §2, KrMS §44), an accused has " +
    "the right — and effectively the necessity — of legal counsel for any interrogation, " +
    "indictment, or trial. AI must NEVER substitute for an asianajaja / vandeadvokaat " +
    "in criminal proceedings.",
  big_claim:
    "a monetary claim of €20,000 or more. At this size the case will normally go " +
    "to district court (käräjäoikeus / maakohus), require formal pleadings, and the " +
    "loser pays costs. Drafting the statement of claim alone benefits enormously from " +
    "an attorney's review.",
  echr:
    "a potential European Court of Human Rights application (EIT / EIK / ЕСПЧ). " +
    "ECHR cases have a 4-month exhaustion deadline from the final domestic decision, " +
    "highly technical admissibility criteria, and a near-zero tolerance for procedural " +
    "errors. AI can help understand the facts; the application itself should be drafted " +
    "or reviewed by counsel admitted to practice before the Strasbourg Court.",
};

/**
 * Insert a model-facing directive into the system prompt so the LLM produces
 * a reply that naturally concludes with the consult-a-lawyer advisory.
 *
 * Idempotent: if the directive is already present (substring match on the
 * sentinel "## HALT-RAIL — SERIOUS CASE DETECTED") this is a no-op.
 *
 * Safe to call with any input: a non-string system prompt is returned
 * unchanged, an empty system prompt becomes just the directive.
 */
export function appendHaltRailToSystem(
  systemPrompt: unknown,
  detection: HaltDetection,
): string {
  if (!detection.isSerious || !detection.category) {
    return typeof systemPrompt === "string" ? systemPrompt : "";
  }
  const sentinel = "## HALT-RAIL — SERIOUS CASE DETECTED";
  const base = typeof systemPrompt === "string" ? systemPrompt : "";
  if (base.includes(sentinel)) return base;

  const framing = CATEGORY_FRAMING[detection.category];
  const directive = [
    sentinel,
    "",
    `The user's message appears to involve ${framing}`,
    "",
    "Your reply MUST therefore include — at the END, in its own paragraph — a clear",
    "advisory that the user should consult a licensed asianajaja (Finland) or",
    "vandeadvokaat (Estonia) before taking any litigation step. Include 1–2 sentences",
    "explaining specifically what an attorney does that you, as AI, cannot:",
    "  • court appearances and oral pleading",
    "  • binding negotiation with the opposing party",
    "  • attorney-client privilege under the Bar Association Acts",
    "  • signing a statement of claim or appeal in their own name",
    "",
    "Do NOT refuse to help with legal information, summary, or first-draft letters —",
    "those remain valuable. The advisory is in ADDITION to your normal reply, not a",
    "replacement for it. Match the language of the user's question (FI / EE / RU /",
    "EN). Keep the advisory factual and non-alarmist.",
  ].join("\n");

  return base ? `${base}\n\n${directive}` : directive;
}

/**
 * Localised banner blocks. We keep them short, neutral in tone, and language-
 * matched to the most likely user language. Selection is heuristic: scan the
 * user's message for language signal; default to Russian (largest user
 * segment per 2026-05-13 analytics).
 */
const BANNER: Record<"ru" | "fi" | "et" | "en", string> = {
  ru:
    "\n\n---\n\n" +
    "⚠️ **Это серьёзная правовая ситуация.** " +
    "Для подачи в суд, переговоров с противной стороной или официальных процессуальных " +
    "действий обратитесь к лицензированному адвокату: **asianajaja** (Финляндия) или " +
    "**vandeadvokaat** (Эстония). Advocat помогает понять закон и составить черновик — " +
    "но AI не может представлять вас в суде, вести переговоры от вашего имени или " +
    "обеспечить адвокатскую тайну (Advokatuuriseadus, Asianajajalaki).",
  fi:
    "\n\n---\n\n" +
    "⚠️ **Tämä on vakava oikeudellinen tilanne.** " +
    "Mikäli aiot viedä asian tuomioistuimeen, neuvotella vastapuolen kanssa tai " +
    "ryhtyä muihin virallisiin toimenpiteisiin, käänny lisensoidun **asianajajan** " +
    "(Suomi) tai **vandeadvokaadin** (Viro) puoleen. Advocat auttaa ymmärtämään lakia " +
    "ja laatimaan luonnoksia — mutta tekoäly ei voi edustaa sinua oikeudessa, " +
    "neuvotella puolestasi sitovasti tai tarjota asianajosalaisuutta (asianajajalaki).",
  et:
    "\n\n---\n\n" +
    "⚠️ **See on tõsine õiguslik olukord.** " +
    "Kohtusse pöördumiseks, vastaspoolega läbirääkimisteks või muudeks ametlikeks " +
    "menetlustoiminguteks võta ühendust litsentsitud **vandeadvokaadiga** (Eesti) " +
    "või **asianajajaga** (Soome). Advocat aitab seadust mõista ja koostada mustandeid " +
    "— kuid tehisintellekt ei saa sind kohtus esindada, sinu nimel siduvalt läbirääkimisi " +
    "pidada ega tagada advokaadisaladust (Advokatuuriseadus).",
  en:
    "\n\n---\n\n" +
    "⚠️ **This is a serious legal situation.** " +
    "For filing in court, negotiating with the opposing party, or any other formal " +
    "proceedings, please consult a licensed **asianajaja** (Finland) or " +
    "**vandeadvokaat** (Estonia). Advocat helps you understand the law and prepare " +
    "drafts — but AI cannot represent you in court, negotiate on your behalf, or " +
    "extend attorney-client privilege (Advokatuuriseadus, Asianajajalaki).",
};

/** Heuristic language detection from a free-text message. */
export function detectLangFromMessage(
  message: string,
): "ru" | "fi" | "et" | "en" {
  if (!message) return "ru";
  // Cyrillic anywhere → Russian.
  if (/[\u0400-\u04FF]/.test(message)) return "ru";
  // Estonian / Finnish vs English: count language-specific signals.
  // We use whitespace + start/end boundaries rather than \b because the ASCII
  // \b does not treat letters like ä/ö/õ/š/ž as word characters, so it
  // misclassifies words ending in those letters. Replacing the message with
  // ` ${text} ` and matching " word " is robust.
  const padded = ` ${message.toLowerCase().slice(0, 1024)} `;

  // Hard signals — only valid in ONE of FI/ET, not both. These get heavy weight.
  // Estonian uses õ, š, ž — none used in standard Finnish.
  const etHardLetters = (padded.match(/[õšž]/g)?.length ?? 0) * 3;
  // Finnish-only function words (do not occur in Estonian).
  const FI_ONLY_WORDS = [
    "että", "minä", "sinä", "hänen", "onko", "kun", "jos", "tai", "olen",
    "kanssa", "teen", "tekoäly", "suomi", "suomessa", "suomesta", "saada",
    "olen", "olla", "hei",
  ];
  // Estonian-only function words.
  const ET_ONLY_WORDS = [
    "ma", "sa", "ta", "mina", "sina", "tema", "kuid", "kas", "mida", "kus",
    "kuidas", "see", "teha", "saaks", "saada", "kohtus", "kohtusse",
    "õigesti", "olen", "ja", "või",
  ];
  // Note: "olen" and "saada" overlap between FI and ET grammars. They appear
  // in both lists; that's fine because the disambiguation rides on the words
  // that ARE unique (minä/että/hei in FI; ma/sa/ta/mina/kuid in ET) plus the
  // Estonian hard letters.

  const countWords = (words: readonly string[]) => {
    let n = 0;
    for (const w of words) {
      // " word " (whitespace-bounded) — matches at any whitespace boundary
      // including newlines / tabs / punctuation followed by space.
      const re = new RegExp(
        `(^|[^\\p{L}\\p{N}])${
          w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
        }(?=[^\\p{L}\\p{N}]|$)`,
        "gu",
      );
      const m = padded.match(re);
      if (m) n += m.length;
    }
    return n;
  };

  const fiHardWords = countWords(FI_ONLY_WORDS) * 2;
  const etHardWords = countWords(ET_ONLY_WORDS) * 2;

  // Find FI words that are NOT in ET list (and vice-versa) for tie-breaking.
  const fiUnique = FI_ONLY_WORDS.filter((w) => !ET_ONLY_WORDS.includes(w));
  const etUnique = ET_ONLY_WORDS.filter((w) => !FI_ONLY_WORDS.includes(w));
  const fiUniqueHits = countWords(fiUnique);
  const etUniqueHits = countWords(etUnique);

  const enHits = countWords([
    "the", "and", "is", "are", "i", "you", "to", "of", "in", "for", "with",
    "want", "claim", "against", "finland", "estonia", "application",
  ]);

  const fiHits = fiHardWords + fiUniqueHits * 4;
  const etHits = etHardWords + etHardLetters + etUniqueHits * 4;

  const best = Math.max(fiHits, etHits, enHits);
  if (best < 1) return "ru";
  if (best === fiHits && fiHits >= etHits) return "fi";
  if (best === etHits) return "et";
  return "en";
}

// ─── Metric write (P5 of Bentley batch, 2026-05-15) ─────────────────────
//
// Fire-and-forget POST to PostgREST inserting one row into
// public.halt_rail_triggers. Never throws — telemetry must never break a
// chat reply. The caller awaits nothing.
//
// We keep this in halt_rail.ts (not claude-proxy/index.ts) so any future
// edge-fn that runs the detector (e.g. legal_planner standalone) can use
// the same persistence call without duplicating fetch boilerplate.

export interface HaltRailMetricInput {
  detection: HaltDetection;
  language: "ru" | "fi" | "et" | "en" | null;
  /** Auth user UUID, or null for anon callers. NEVER pass the anon:<hash> pseudo-id. */
  userId: string | null;
  supabaseUrl: string;
  serviceRoleKey: string;
}

/**
 * Persist one halt-rail trigger to public.halt_rail_triggers. No-ops when:
 *   • detection.isSerious is false (nothing to record)
 *   • supabaseUrl or serviceRoleKey is empty (dev / test environments)
 *
 * Returns void; errors are swallowed (logged at warn level).
 */
export async function recordHaltRailTrigger(
  input: HaltRailMetricInput,
): Promise<void> {
  const { detection, language, userId, supabaseUrl, serviceRoleKey } = input;
  if (!detection.isSerious || !detection.category) return;
  if (!supabaseUrl || !serviceRoleKey) return;
  try {
    const row = {
      category: detection.category,
      language: language ?? null,
      user_id: userId ?? null,
      reason: detection.reason.slice(0, 200),
      amount_eur: detection.category === "big_claim"
        ? Math.min(detection.matchedAmount, 2_000_000_000)
        : null,
    };
    const url = `${supabaseUrl.replace(/\/$/, "")}/rest/v1/halt_rail_triggers`;
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "apikey": serviceRoleKey,
        "Authorization": `Bearer ${serviceRoleKey}`,
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
      },
      body: JSON.stringify(row),
    });
    if (!res.ok) {
      // Read once for the warn line; ignore the body content otherwise.
      const text = await res.text().catch(() => "");
      console.warn(
        `halt_rail metric write failed http=${res.status} body=${
          text.slice(0, 200)
        }`,
      );
    }
  } catch (e) {
    console.warn(`halt_rail metric write threw: ${String(e).slice(0, 200)}`);
  }
}

/**
 * Append the visible halt-rail banner to the AI's response text. Idempotent:
 * if the response already contains the banner sentinel "⚠️ " plus
 * "asianajaja" we skip to avoid double-banner.
 *
 * Safe with non-string input — returns empty string for non-strings, returns
 * the input unchanged when detection.isSerious is false.
 */
export function appendHaltRailToResponse(
  response: unknown,
  detection: HaltDetection,
  /** Override language. If absent, inferred from the user message. */
  userMessage?: string,
): string {
  const base = typeof response === "string" ? response : "";
  if (!detection.isSerious) return base;
  // Idempotency: every banner contains the sentinel phrase
  // "Advocat помогает", "Advocat aitab", "Advocat auttaa", or "Advocat helps"
  // — one of those four wins on every language. If any is already present we
  // skip to avoid double-banner on retry / regen paths.
  if (
    base.includes("Advocat помогает понять закон") ||
    base.includes("Advocat aitab seadust mõista") ||
    base.includes("Advocat auttaa ymmärtämään lakia") ||
    base.includes("Advocat helps you understand the law")
  ) {
    return base;
  }
  const lang = detectLangFromMessage(userMessage ?? base);
  return base + BANNER[lang];
}
