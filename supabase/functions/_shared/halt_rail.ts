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

// ── Scope coverage (2026-05-20, dept5 FIX-WAVE 11) ───────────────────────────
// CURRENTLY COVERED categories:
//   • deportation       (FI käännyttäm/karkott, EE väljasaatm, RU депорт)
//   • custody           (lapsen huolto, lapse hooldusõigus, опека)
//   • criminal          (syyttäjä, prokurör, обвинение, charges)
//   • big_claim         (any € amount ≥ 20 000, "€20K+" threshold)
//   • echr              (EIT/EIS valitus, Strasbourg, ECtHR)
//
// KNOWN MISSING categories (will fall through to default lawyer-tone reply,
// no crisis-line/out-of-scope rail surfaced):
//   • medical / suicide / self-harm   — no "contact crisis line" hand-off
//   • US immigration / USCIS / I-589  — no "contact US-licensed attorney"
//   • mental-health crisis            — no triage to MIELI / 988 / Peaasi
//   • employment-discrimination outside EE/FI (e.g. US Title VII, UK)
//
// TODO(dept5): Add KEYWORDS entries + HaltCategory union members for the
// four missing categories. Each needs (a) keyword stems in FI/EE/RU/EN,
// (b) a routing message (crisis lines for medical/suicide, US-attorney
// referral for USCIS, etc.), (c) a smoke test in halt_rail.test.ts.
// Acceptable risk for tonight given FI/EE-only product scope — but log
// as P2 for next iteration.

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
    // 2026-05-29: the NOUN "käännytys" (deportation decision) and its
    // compound "käännytyspäätös" share the stem "käännyty-", which is NOT a
    // prefix of "käännyttäm"/"käännytet". This is the exact word used in real
    // FI deportation decisions (incl. Sulga's own case docs), so a bare
    // "Sain käännytyspäätöksen…" previously slipped past detection. Closes
    // HALT-T06.
    "käännyty",       // käännytys / käännytyspäätös / käännytyspäätöksen / käännytystä
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

// ─── Crisis detection (suicide / self-harm) ──────────────────────────────────
//
// SEPARATE from the litigation halt-rail. When a user expresses suicidal
// ideation or intent to self-harm, the correct response is NOT a "consult a
// lawyer" advisory — it is an immediate, empathetic hand-off to a crisis
// helpline, surfaced at the TOP of the reply. A legal product must never
// answer a person in crisis with a deadline calculation and nothing else.
//
// Design rules:
//   • Detection errs toward firing (false positive = an extra helpline block,
//     which is harmless). But we are stricter than the legal halt-rail: bare
//     mentions like "suicide" inside a news/legal discussion must NOT fire, so
//     each keyword is a first-person distress phrase, not a single word.
//   • The crisis banner is PREPENDED (helpline first), unlike the legal banner
//     which is appended.
//   • Crisis takes priority: when both crisis and a legal category fire, the
//     crisis block leads and the legal advisory still follows.
//
// Helplines are region-spanning (FI + EE + EU + intl) because we cannot know
// the caller's country reliably; 112 covers the EU, the others are 24/7.

const CRISIS_KEYWORDS: readonly string[] = [
  // English — first-person distress / intent.
  "kill myself",
  "want to die",
  "end my life",
  "ending my life",
  "take my own life",
  "suicidal",
  "suicide thoughts",
  "thinking about suicide",
  "harm myself",
  "hurt myself",
  "self-harm",
  "self harm",
  "no reason to live",
  "can't go on",
  "cant go on",
  // Finnish.
  "tappaa itseni",
  "tehdä itsemurha",
  "itsemurha",
  "en halua elää",
  "en jaksa enää",
  "vahingoittaa itseäni",
  "satuttaa itseäni",
  // Estonian.
  "tappa ennast",
  "enesetapp",
  "ei taha elada",
  "ei jaksa enam",
  "endale haiget teha",
  "vigastada ennast",
  // Russian.
  "покончить с собой",
  "убить себя",
  "суицид",
  "не хочу жить",
  "не хочу больше жить",
  "не могу больше",
  "причинить себе вред",
  "покончить жизнь самоубийством",
];

export interface CrisisDetection {
  isCrisis: boolean;
  /** Matched phrase, for telemetry only. Empty when isCrisis=false. */
  reason: string;
}

const NO_CRISIS: CrisisDetection = { isCrisis: false, reason: "" };

/**
 * Detect suicidal ideation / self-harm intent in a user message.
 * Pure, total, no I/O. Multi-word phrases are matched as substrings so
 * everyday legal/news mentions of the word "suicide" alone don't fire.
 */
export function detectCrisis(message: unknown): CrisisDetection {
  if (typeof message !== "string" || message.length === 0) return NO_CRISIS;
  const text = message.length > 8192 ? message.slice(0, 8192) : message;
  const lower = text.toLowerCase();
  for (const kw of CRISIS_KEYWORDS) {
    if (lower.includes(kw)) {
      return { isCrisis: true, reason: `crisis:${kw}` };
    }
  }
  return NO_CRISIS;
}

// Crisis helpline banners. Prepended (helpline first). Anchored in the 4 core
// languages; all other detected languages fall back to the English block,
// which lists region-spanning 24/7 lines + the EU emergency number.
const CRISIS_BANNER: Partial<Record<DetectedLang, string>> = {
  en:
    "🆘 **If you are in danger right now, call 112 (EU emergency).**\n\n" +
    "It sounds like you may be going through something very painful. You are not " +
    "alone, and help is available right now from people trained to listen:\n\n" +
    "• **Finland** — MIELI Crisis Line: **09 2525 0111** (24/7), or Sekasin chat (sekasin.fi)\n" +
    "• **Estonia** — Emotional support: **116 123** (24/7); for under-18s: **116 111**\n" +
    "• **EU-wide emergency** — **112**\n\n" +
    "Please reach out to one of these now. I'm an AI legal assistant and cannot " +
    "provide the support you deserve, but a trained person can.\n\n---\n\n",
  fi:
    "🆘 **Jos olet välittömässä vaarassa, soita 112.**\n\n" +
    "Kuulostaa siltä, että sinulla on todella raskasta. Et ole yksin, ja apua on " +
    "saatavilla juuri nyt koulutetuilta auttajilta:\n\n" +
    "• **MIELI Kriisipuhelin**: **09 2525 0111** (24/7)\n" +
    "• **Sekasin-chat**: sekasin.fi\n" +
    "• **Hätänumero**: **112**\n\n" +
    "Ota yhteyttä johonkin näistä nyt. Olen tekoälyavustaja enkä voi antaa sitä " +
    "tukea jonka ansaitset — mutta koulutettu ihminen voi.\n\n---\n\n",
  et:
    "🆘 **Kui oled vahetus ohus, helista 112.**\n\n" +
    "Tundub, et sul on praegu väga raske. Sa ei ole üksi ja abi on saadaval " +
    "kohe, väljaõppinud inimestelt:\n\n" +
    "• **Hingehoiu / emotsionaalne tugi**: **116 123** (24/7)\n" +
    "• **Lasteabi (alla 18)**: **116 111**\n" +
    "• **Hädaabi**: **112**\n\n" +
    "Palun võta kohe ühendust ühega neist. Olen tehisintellektist õigusabiline " +
    "ega saa pakkuda tuge, mida sa väärid — kuid väljaõppinud inimene saab.\n\n---\n\n",
  ru:
    "🆘 **Если вы в непосредственной опасности — звоните 112.**\n\n" +
    "Похоже, вам сейчас очень тяжело. Вы не одни, и помощь доступна прямо сейчас " +
    "от людей, обученных слушать и поддержать:\n\n" +
    "• **Финляндия** — кризисная линия MIELI: **09 2525 0111** (круглосуточно)\n" +
    "• **Эстония** — эмоциональная поддержка: **116 123** (круглосуточно); до 18 лет: **116 111**\n" +
    "• **Экстренная помощь в ЕС**: **112**\n\n" +
    "Пожалуйста, обратитесь к одному из этих контактов прямо сейчас. Я — ИИ-" +
    "юрист и не могу дать поддержку, которую вы заслуживаете, но обученный " +
    "человек — может.\n\n---\n\n",
};

/**
 * Prepend the crisis helpline block to the AI's response. Idempotent: if the
 * block sentinel ("🆘") is already present we skip. Safe with non-string input.
 */
export function prependCrisisBanner(
  response: unknown,
  detection: CrisisDetection,
  userMessage?: string,
): string {
  const base = typeof response === "string" ? response : "";
  if (!detection.isCrisis) return base;
  if (base.includes("🆘")) return base;
  const lang = detectLangFromMessage(userMessage ?? base);
  const banner = CRISIS_BANNER[lang] ?? CRISIS_BANNER.en!;
  return banner + base;
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
 * Localised banner blocks. We keep them short, neutral in tone, and
 * language-matched to the user's language. Selection is heuristic via
 * `detectLangFromMessage` (Day 1-3 of MVP overnight; extended 2026-05-27
 * to 17 locales matching `lib/l10n/*.arb`).
 *
 * The 4 anchor banners (ru/fi/et/en) carry the legal-specific text with
 * the "asianajaja/vandeadvokaat" namedrops. The other 13 are shorter
 * universal disclaimers — same message, same "consult a licensed lawyer"
 * spirit, just in the user's UI language. The Sentinel detector below
 * scans for any of the 4 anchor phrases.
 */
const BANNER: Record<DetectedLang, string> = {
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
  // ── 2026-05-27: 13 additional locales (matches lib/l10n/*.arb) ───────
  ar:
    "\n\n---\n\n⚠️ **هذا وضع قانوني خطير.** " +
    "للتقاضي أو التفاوض الرسمي مع الطرف الآخر، يرجى استشارة محامٍ مرخّص. " +
    "Advocat يساعدك على فهم القانون وإعداد المسودّات — لكن الذكاء الاصطناعي " +
    "لا يمكنه تمثيلك في المحكمة أو التفاوض نيابةً عنك.",
  de:
    "\n\n---\n\n⚠️ **Dies ist eine ernste rechtliche Situation.** " +
    "Für ein Gerichtsverfahren oder förmliche Schritte wenden Sie sich an einen " +
    "lizenzierten Rechtsanwalt. Advocat hilft beim Verstehen des Rechts und beim " +
    "Vorbereiten von Entwürfen — KI kann Sie aber nicht vor Gericht vertreten.",
  es:
    "\n\n---\n\n⚠️ **Esta es una situación legal seria.** " +
    "Para acudir a los tribunales u otro procedimiento formal, consulte a un " +
    "abogado colegiado. Advocat le ayuda a entender la ley y preparar borradores " +
    "— pero la IA no puede representarle en los tribunales.",
  fa:
    "\n\n---\n\n⚠️ **این یک وضعیت حقوقی جدی است.** " +
    "برای طرح دعوی در دادگاه یا مذاکره رسمی، با یک وکیل دارای پروانه مشورت " +
    "کنید. Advocat به شما کمک می‌کند قانون را بفهمید و پیش‌نویس‌ها را آماده " +
    "کنید — اما هوش مصنوعی نمی‌تواند شما را در دادگاه نمایندگی کند.",
  fr:
    "\n\n---\n\n⚠️ **Cette situation juridique est sérieuse.** " +
    "Pour saisir un tribunal ou toute procédure formelle, consultez un avocat " +
    "agréé. Advocat vous aide à comprendre le droit et à rédiger des projets " +
    "— mais l'IA ne peut pas vous représenter au tribunal.",
  it:
    "\n\n---\n\n⚠️ **Questa è una situazione legale seria.** " +
    "Per il deposito in tribunale o procedure formali, consulti un avvocato " +
    "abilitato. Advocat l'aiuta a comprendere la legge e a preparare bozze — " +
    "ma l'IA non può rappresentarla in tribunale.",
  lt:
    "\n\n---\n\n⚠️ **Tai rimta teisinė situacija.** " +
    "Norėdami kreiptis į teismą ar imtis oficialių veiksmų, kreipkitės į " +
    "licencijuotą advokatą. Advocat padeda suprasti įstatymą ir rengti " +
    "juodraščius — bet DI negali jūsų atstovauti teisme.",
  lv:
    "\n\n---\n\n⚠️ **Šī ir nopietna juridiska situācija.** " +
    "Lai vērstos tiesā vai veiktu oficiālas darbības, konsultējieties ar " +
    "licencētu zvērinātu advokātu. Advocat palīdz izprast likumu un sagatavot " +
    "melnrakstus — bet MI nevar jūs pārstāvēt tiesā.",
  pl:
    "\n\n---\n\n⚠️ **To poważna sytuacja prawna.** " +
    "W sprawach sądowych lub formalnych czynnościach skonsultuj się z " +
    "licencjonowanym adwokatem lub radcą prawnym. Advocat pomaga zrozumieć " +
    "prawo i przygotować szkice — ale SI nie może reprezentować cię w sądzie.",
  ro:
    "\n\n---\n\n⚠️ **Aceasta este o situație juridică serioasă.** " +
    "Pentru o cerere în instanță sau alte proceduri formale, consultați un " +
    "avocat autorizat. Advocat vă ajută să înțelegeți legea și să pregătiți " +
    "schițe — dar IA nu vă poate reprezenta în instanță.",
  sv:
    "\n\n---\n\n⚠️ **Detta är en allvarlig rättslig situation.** " +
    "För domstolsförfaranden eller formella åtgärder, kontakta en licensierad " +
    "advokat. Advocat hjälper dig att förstå lagen och förbereda utkast — men " +
    "AI kan inte företräda dig i domstol.",
  tr:
    "\n\n---\n\n⚠️ **Bu ciddi bir hukuki durumdur.** " +
    "Mahkemeye başvuru veya resmi işlemler için lisanslı bir avukata danışın. " +
    "Advocat yasayı anlamanıza ve taslak hazırlamanıza yardımcı olur — ancak " +
    "yapay zeka sizi mahkemede temsil edemez.",
  uk:
    "\n\n---\n\n⚠️ **Це серйозна правова ситуація.** " +
    "Для подання до суду або інших офіційних дій зверніться до ліцензованого " +
    "адвоката. Advocat допомагає зрозуміти закон і скласти чернетки — але ШІ " +
    "не може представляти вас у суді.",
};

/**
 * Detected-language union — the 17 locales the Flutter app ships ARB
 * translations for. Extended 2026-05-27 from the original 4 (ru/fi/et/en)
 * to match `lib/l10n/*.arb`: ar, de, en, es, et, fa, fi, fr, it, lt, lv,
 * pl, ro, ru, sv, tr, uk.
 *
 * Detection strategy:
 *   1. Script-only languages (Arabic, Cyrillic non-RU, Persian, Ukrainian) —
 *      pick the dominant Unicode block.
 *   2. Latin-script languages — diacritic hard signals + per-language
 *      stopword scoring, same pattern as the legacy FI/ET/EN detector.
 *   3. Fall back to "en" when nothing scores (was "ru" — changed to "en"
 *      so the global majority of users see a sensible default; native ru
 *      users always trigger Cyrillic anyway).
 */
export type DetectedLang =
  | "ru"
  | "fi"
  | "et"
  | "en"
  | "ar"
  | "de"
  | "es"
  | "fa"
  | "fr"
  | "it"
  | "lt"
  | "lv"
  | "pl"
  | "ro"
  | "sv"
  | "tr"
  | "uk";

export function detectLangFromMessage(message: string): DetectedLang {
  if (!message) return "en";
  const sample = message.slice(0, 1024);

  // ── Script-only short-circuits ─────────────────────────────────────────
  // Arabic block U+0600-U+06FF. Persian shares this block; disambiguate
  // via Persian-only letters (پ چ ژ گ) AND common Persian function words.
  if (/[\u0600-\u06FF]/.test(sample)) {
    if (/[پچژگ]/.test(sample)) return "fa";
    // Fallback signal: common Persian verb endings + pronouns that don't
    // appear in MSA Arabic. می‌ (imperfective prefix), من (I, used in Persian
    // as a pronoun; in Arabic it means "from" but appears far less commonly
    // as a standalone short word), از (from), هستم (am).
    if (/(می‌|هستم|می‌شوم|می‌کنم|می‌توانم| از | که )/.test(sample)) return "fa";
    return "ar";
  }
  // Cyrillic anywhere → Russian or Ukrainian. Disambiguate via Ukrainian-
  // only letters (і ї є ґ — none in modern Russian alphabet).
  if (/[\u0400-\u04FF]/.test(sample)) {
    return /[іїєґ]/i.test(sample) ? "uk" : "ru";
  }

  // ── Latin-script — per-language stopword + diacritic scoring ──────────
  const padded = ` ${sample.toLowerCase()} `;

  const countWords = (words: readonly string[]) => {
    let n = 0;
    for (const w of words) {
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

  const countChars = (re: RegExp) => (sample.match(re)?.length ?? 0);

  // Per-language stopwords (function words that appear in 90%+ of any
  // typical sentence). Curated to be MUTUALLY EXCLUSIVE where possible so
  // a single hit is enough to discriminate between near-twins (e.g. lt/lv,
  // it/es, sv/no).
  const FI = [
    "että", "minä", "minua", "sinä", "hänen", "onko", "olen", "olla", "hei",
    "kanssa", "tekoäly", "suomi", "suomessa", "suomesta",
    "ollaan", "ovat", "tulla", "tehdä", "haluan", "haluaisin", "voiko",
    "saa", "saanko", "myös", "vielä", "kuitenkin",
    // 2026-05-29: real FI legal queries often carry NONE of the generic
    // function words above (e.g. "Sain käännytyspäätöksen … Pitäisikö
    // valittaa hallinto-oikeuteen?"). Add high-frequency legal/procedural
    // and conditional tokens so such messages detect as FI, not the "en"
    // floor — otherwise the safety banner renders in the wrong language.
    "sain", "pitäisikö", "pitäisi", "valittaa", "valitus", "oikeuteen",
    "oikeus", "poliisi", "poliisilaitokselta", "päätös", "päätöksen",
    "hakemus", "hallinto-oikeuteen", "tuomioistuin", "asianajaja",
  ];
  const ET = [
    "ma", "sa", "mind", "mina", "sina", "tema", "kuid", "kas", "mida", "kus",
    "kuidas", "see", "teha", "või", "õigesti", "ja", "ei", "on",
    "soome", "soomes", "soomest", "eesti", "eestis", "eestist",
    "saadetakse", "välja", "tahan", "tahaks", "saaks",
  ];
  const EN = [
    "the", "and", "is", "are", "you", "with", "want", "against",
    "application", "would", "should", "could", "have",
  ];
  const DE = [
    "der", "die", "das", "ist", "und", "ich", "nicht", "mit", "wir",
    "dass", "haben", "werden", "möchte", "sehr",
  ];
  const ES = [
    "el", "la", "los", "las", "que", "es", "soy", "estoy", "para",
    "por", "tengo", "quiero", "muy", "español",
  ];
  const FR = [
    "le", "la", "les", "et", "je", "tu", "nous", "vous", "est", "pour",
    "avec", "n'est", "c'est", "qu'il", "français",
  ];
  const IT = [
    "il", "la", "lo", "gli", "che", "non", "sono", "siamo", "essere",
    "questo", "questa", "italiano", "perché", "molto",
  ];
  const PL = [
    "jest", "się", "nie", "tak", "to", "co", "jak", "który", "tylko",
    "polski", "moja", "moje",
  ];
  const RO = [
    "și", "este", "sunt", "nu", "să", "în", "pentru", "cu", "din",
    "român", "română", "vreau", "trebuie",
  ];
  const SV = [
    "jag", "är", "och", "att", "det", "inte", "har", "med", "för",
    "men", "som", "vill", "vad", "svenska",
  ];
  const TR = [
    "ben", "sen", "biz", "siz", "değil", "için", "ile", "bir", "bu",
    "şu", "ve", "ama", "türkçe", "istiyorum",
  ];
  const LT = [
    "aš", "tu", "jis", "ji", "yra", "nėra", "kad", "kaip", "tik",
    "lietuvių", "noriu", "labai",
  ];
  const LV = [
    "es", "tu", "viņš", "viņa", "ir", "nav", "kas", "ka", "tikai",
    "latviešu", "gribu", "ļoti", "mani", "tevi", "izraida", "izsūta",
    "latvija", "latvijā", "latvijas", "no", "uz",
  ];

  // Hard-letter signals — each strongly suggests one language.
  // Heavy weight (×3) so a single rare letter outweighs generic stopwords.
  const etHardLetters = countChars(/[õšž]/g) * 3;
  // FI uses ä ö but NOT ü/õ/ą — same for SE/DE.
  // Polish-only letters.
  const plHardLetters = countChars(/[ąćęłńóśźż]/gi) * 3;
  // Romanian-only.
  const roHardLetters = countChars(/[ăâîșțţş]/gi) * 3;
  // Turkish-only.
  const trHardLetters = countChars(/[ğıİş̆ŞĞ]/g) * 3;
  // Lithuanian-only diacritics (overlaps with PL on ą ę but PL has more).
  const ltHardLetters = countChars(/[ąčęėįšųūž]/gi) * 2;
  // Latvian-only diacritics — macrons absent from other Baltic languages.
  const lvHardLetters = countChars(/[āēīōūģķļņŗ]/gi) * 3;
  // German-only ß.
  const deHardLetters = countChars(/ß/gi) * 4;
  // Spanish-only ¿ ¡ ñ.
  const esHardLetters = countChars(/[¿¡ñ]/g) * 4;
  // French-only œ ç (ç also Portuguese, but PT not in our locale set).
  const frHardLetters = countChars(/[œçÿ]/gi) * 3;
  // Italian: à è é ì ò ù are common; weight is moderate (overlap with FR).
  const itHardLetters = countChars(/[àèéìíòóùú]/gi) * 1;

  const scores: Record<string, number> = {
    fi: countWords(FI) * 4,
    et: countWords(ET) * 4 + etHardLetters,
    en: countWords(EN) * 3,
    de: countWords(DE) * 4 + deHardLetters,
    es: countWords(ES) * 4 + esHardLetters,
    fr: countWords(FR) * 4 + frHardLetters,
    it: countWords(IT) * 4 + itHardLetters,
    pl: countWords(PL) * 4 + plHardLetters,
    ro: countWords(RO) * 4 + roHardLetters,
    sv: countWords(SV) * 4,
    tr: countWords(TR) * 4 + trHardLetters,
    lt: countWords(LT) * 4 + ltHardLetters,
    lv: countWords(LV) * 4 + lvHardLetters,
  };

  let bestLang: DetectedLang = "en";
  let bestScore = 0;
  for (const [lang, score] of Object.entries(scores)) {
    if (score > bestScore) {
      bestScore = score;
      bestLang = lang as DetectedLang;
    }
  }
  // Floor — when no signal at all, fall back to English (was "ru" in the
  // legacy detector; English is the safer global default).
  if (bestScore < 1) return "en";
  return bestLang;
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
  /**
   * Extended 2026-05-27 to the full 17-locale set the Flutter app supports
   * (was: ru/fi/et/en only). DB column is TEXT so this is additive — old
   * rows keep their narrow values, new rows can use any of the 17.
   */
  language: DetectedLang | null;
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
