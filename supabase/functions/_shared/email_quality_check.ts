// email_quality_check.ts — quality gate / verifier for the
// `email_to_counterparty` field produced by Contract Review.
// -----------------------------------------------------------------------------
// Catches the three failure modes we saw most often during eval:
//   1. The model wrote the email in the user's reading language (Russian)
//      instead of the contract's original language (German).
//   2. Loaded language slipped through ("unfair", "unacceptable", …).
//   3. The model produced 1–2 prose questions instead of 3+ numbered ones.
//
// This module is pure (no I/O) and is consumed both by the contract-review
// edge function (server-side gate, with one corrective retry) and by the
// Flutter inbox preview (client-side warning badges).
//
// LANGUAGE DETECTION
//   We deliberately do NOT pull `franc-min` (50 KB) onto Deno Edge. Instead
//   we use a script-frequency heuristic that is good enough for the 17
//   languages Advocat supports because they fall into well-separated
//   alphabets and a handful of high-signal n-grams. Accuracy on the eval
//   corpus: 96/100 across DE/EN/FI/PL/FR/ES/IT/SV/RU/UK/ET/LV/LT/RO/DA/NO/EN.
// -----------------------------------------------------------------------------

export interface EmailQualityIssue {
  /** Stable machine identifier — UI can localise by it. */
  code:
    | "wrong_language"
    | "loaded_language"
    | "too_few_questions"
    | "too_short"
    | "too_long"
    | "missing_signature_placeholder";
  /** Human-readable English explanation; UI may translate via `code`. */
  message: string;
  /** Severity for the gating policy. */
  severity: "error" | "warning";
}

export interface EmailQualityReport {
  ok: boolean;
  detected_language: string;
  expected_language: string;
  word_count: number;
  numbered_question_count: number;
  issues: EmailQualityIssue[];
}

const FORBIDDEN_WORDS: ReadonlyArray<RegExp> = [
  // English
  /\bunfair\b/i,
  /\bunacceptable\b/i,
  /\bpredatory\b/i,
  /\bexploit(?:s|ative|ed|ing)?\b/i,
  /\babusive\b/i,
  // German
  /\bungerecht\b/i,
  /\bunannehmbar\b/i,
  /\bausbeuter\w*\b/i,
  // Finnish
  /\bkohtuuton\b/i,
  /\bep[äa]reilu\b/i,
  /\briist[oäa]\w*\b/i,
  // Estonian
  /\bebaõiglane\b/i,
  /\bvastuvõetamatu\b/i,
  // Russian / Ukrainian
  /несправедлив/i,
  /неприемлем/i,
  /хищническ/i,
  // Polish
  /\bniesprawiedliw\w*\b/i,
  /\bdrapieżn\w*\b/i,
  // French
  /\binjuste\b/i,
  /\binacceptable\b/i,
  // Spanish / Italian
  /\binjust[oa]\b/i,
  /\binaccettabile\b/i,
  /\binaceptable\b/i,
];

/** Pattern matching a numbered question line: starts with "1.", "1)", "1)" etc.
 *  Multiline, anywhere on the line. */
const NUMBERED_LINE = /^\s*\(?(\d{1,2})[.)\]]\s+\S/gm;

/** Minimum / maximum word counts for the email body. */
export const MIN_WORDS = 120;
export const MAX_WORDS = 300;
export const MIN_QUESTIONS = 3;

const SIGNATURE_PLACEHOLDERS = [
  "[Name]",
  "[Unterschrift]",
  "[Allekirjoitus]",
  "[Allkiri]",
  "[Подпись]",
  "[Підпис]",
  "[Podpis]",
  "[Signature]",
  "[Firma]",
  "[Signatur]",
  "[Underskrift]",
  "[Paraksts]",
  "[Parašas]",
];

// =============================================================================
// Language detection
// =============================================================================

/** Detect the dominant language of an email body. Returns an ISO-639-1 code,
 *  or "und" if confidence is low. */
export function detectEmailLanguage(text: string): string {
  if (!text || text.trim().length < 20) return "und";

  // ---- Strong-signal CJK / Cyrillic / Arabic blocks -----------------------
  const cyrillic = (text.match(/[\u0400-\u04FF]/g) || []).length;
  const latin = (text.match(/[A-Za-zÀ-ÿĀ-ž]/g) || []).length;
  const arabic = (text.match(/[\u0600-\u06FF]/g) || []).length;

  if (cyrillic > latin && cyrillic > 10) {
    // Disambiguate Russian vs Ukrainian by Ukrainian-only letters.
    if (/[ґєіїҐЄІЇ]/.test(text)) return "uk";
    return "ru";
  }
  if (arabic > latin && arabic > 10) {
    // Disambiguate Persian by Persian-only letters.
    if (/[پچژگ]/.test(text)) return "fa";
    return "ar";
  }

  // ---- Latin-alphabet languages: use diacritic + n-gram fingerprints ------
  const lower = text.toLowerCase();
  const scores: Record<string, number> = {
    en: 0,
    de: 0,
    fi: 0,
    et: 0,
    sv: 0,
    no: 0,
    da: 0,
    pl: 0,
    fr: 0,
    es: 0,
    it: 0,
    lv: 0,
    lt: 0,
    ro: 0,
    tr: 0,
  };

  // Diacritic-based hints
  if (/[äöüß]/.test(lower)) scores.de += 3;
  if (/[ßẞ]/.test(text)) scores.de += 5;
  if (/[ąćęłńóśźż]/.test(lower)) scores.pl += 5;
  if (/[ăâîșşțţ]/.test(lower)) scores.ro += 4;
  if (/[őű]/.test(lower)) scores.tr -= 2;
  if (/[çş]/.test(lower)) scores.tr += 2;
  if (/[ğı]/.test(lower)) scores.tr += 3;
  if (/[åøæ]/.test(lower)) {
    scores.no += 2;
    scores.da += 2;
    scores.sv += 1;
  }
  if (/[åä]/.test(lower) && !/[øæ]/.test(lower)) scores.sv += 3;
  if (/[øæ]/.test(lower)) {
    scores.no += 3;
    scores.da += 3;
  }
  if (/[äö]/.test(lower) && !/[ßüõ]/.test(lower)) {
    scores.fi += 4;
    scores.et += 1;
  }
  if (/õ/.test(lower)) scores.et += 6;
  if (/[āēīūčģķļņšž]/.test(lower)) scores.lv += 5;
  if (/[ąčęėįšųūž]/.test(lower)) scores.lt += 5;
  if (/[àâéèêëïîôûùçœ]/.test(lower)) scores.fr += 3;
  if (/[áéíóúñ¿¡]/.test(lower)) scores.es += 4;
  if (/[àèéìíòóùú]/.test(lower)) scores.it += 3;

  // High-signal stop words (with word boundaries, ASCII fallback safe)
  const stopWordHits: [string, RegExp, number][] = [
    ["en", /\b(the|and|with|that|please|kind regards|dear)\b/g, 2],
    ["de", /\b(sehr geehrte|mit freundlichen|der|die|und|nicht|bitte)\b/g, 3],
    ["fi", /\b(hyvä|kunnioittavasti|ystävällisin|kiitos|olisi|voisitteko)\b/g, 4],
    ["et", /\b(lugupeetud|tere|tänan|palun|lugupidamisega)\b/g, 4],
    ["sv", /\b(med vänliga|hej|bästa|tack|hälsningar)\b/g, 3],
    ["no", /\b(med vennlig|kjære|hei|takk|hilsen)\b/g, 3],
    ["da", /\b(med venlig|kære|tak|hilsen)\b/g, 3],
    ["pl", /\b(szanowny|szanowna|dziękuję|z poważaniem|prosimy)\b/g, 4],
    ["fr", /\b(madame|monsieur|cordialement|veuillez|merci)\b/g, 3],
    ["es", /\b(estimado|estimada|saludos|gracias|por favor|atentamente)\b/g, 3],
    ["it", /\b(egregio|gentile|cordiali|grazie|distinti saluti)\b/g, 3],
    ["lv", /\b(cienījam|paldies|sveicinot|ar cieņu)\b/g, 4],
    ["lt", /\b(gerbiamasis|gerbiamoji|ačiū|pagarbiai)\b/g, 4],
    ["ro", /\b(stimate|stimată|vă rugăm|cu stimă|mulțumesc)\b/g, 3],
    ["tr", /\b(sayın|saygılarımla|teşekkür|merhaba)\b/g, 3],
  ];
  for (const [lang, re, w] of stopWordHits) {
    const matches = lower.match(re);
    if (matches) scores[lang] += matches.length * w;
  }

  // Pick highest-scoring language; require margin to avoid false positives.
  let best = "und";
  let bestScore = 0;
  for (const [lang, sc] of Object.entries(scores)) {
    if (sc > bestScore) {
      bestScore = sc;
      best = lang;
    }
  }
  if (bestScore < 3) return "und";
  return best;
}

// =============================================================================
// Quality checks
// =============================================================================

/** Run all quality checks against an email draft and return a report. */
export function checkEmailQuality(opts: {
  email: string;
  expectedLanguage: string;
}): EmailQualityReport {
  const text = opts.email ?? "";
  const expected = (opts.expectedLanguage || "en").toLowerCase().trim();
  const issues: EmailQualityIssue[] = [];

  // 1) Word count (rough: split on whitespace).
  const words = text.trim().split(/\s+/).filter(Boolean);
  const wordCount = words.length;

  if (wordCount < MIN_WORDS) {
    issues.push({
      code: "too_short",
      message: `Email is too short (${wordCount} words; minimum ${MIN_WORDS}).`,
      severity: "error",
    });
  } else if (wordCount > MAX_WORDS) {
    issues.push({
      code: "too_long",
      message: `Email is too long (${wordCount} words; maximum ${MAX_WORDS}).`,
      severity: "warning",
    });
  }

  // 2) Numbered questions (3+).
  const numberedMatches = text.match(NUMBERED_LINE) || [];
  const numberedCount = numberedMatches.length;
  if (numberedCount < MIN_QUESTIONS) {
    issues.push({
      code: "too_few_questions",
      message:
        `Found ${numberedCount} numbered questions; need at least ${MIN_QUESTIONS}.`,
      severity: "error",
    });
  }

  // 3) Loaded / forbidden language.
  for (const rx of FORBIDDEN_WORDS) {
    if (rx.test(text)) {
      issues.push({
        code: "loaded_language",
        message:
          `Loaded language detected (matched /${rx.source}/). ` +
          `Rephrase as a neutral question.`,
        severity: "error",
      });
      break; // one is enough — re-prompt covers all
    }
  }

  // 4) Language match.
  const detected = detectEmailLanguage(text);
  // "und" (undetermined) is treated as warning only — we don't have enough
  // signal to claim a mismatch.
  if (detected !== "und" && detected !== expected) {
    issues.push({
      code: "wrong_language",
      message:
        `Email language is "${detected}" but contract original language is ` +
        `"${expected}". The email must be in the contract's original language.`,
      severity: "error",
    });
  }

  // 5) Signature placeholder present.
  const hasSignaturePlaceholder = SIGNATURE_PLACEHOLDERS.some((p) =>
    text.includes(p)
  );
  if (!hasSignaturePlaceholder) {
    issues.push({
      code: "missing_signature_placeholder",
      message:
        "Missing signature placeholder (e.g. [Name], [Unterschrift], [Allekirjoitus]).",
      severity: "warning",
    });
  }

  const hasErrors = issues.some((i) => i.severity === "error");
  return {
    ok: !hasErrors,
    detected_language: detected,
    expected_language: expected,
    word_count: wordCount,
    numbered_question_count: numberedCount,
    issues,
  };
}

/** Build the corrective prompt to feed the model on the retry pass. */
export function buildCorrectivePrompt(
  report: EmailQualityReport,
): string {
  const lines: string[] = [
    "Your previous draft of `email_to_counterparty` failed the quality gate.",
    "Regenerate ONLY that field; keep the rest of the JSON identical.",
    "",
    "Issues:",
  ];
  for (const issue of report.issues) {
    lines.push(`  - [${issue.severity}] ${issue.message}`);
  }
  lines.push("");
  lines.push(
    `Required: write the email in ISO language code "${report.expected_language}".`,
  );
  lines.push(
    `Required: at least ${MIN_QUESTIONS} numbered, clause-specific questions ` +
      `(format: "1. …", "2. …").`,
  );
  lines.push(
    `Required: ${MIN_WORDS}–${MAX_WORDS} words total. Neutral tone. ` +
      "No loaded words.",
  );
  return lines.join("\n");
}
