// language_detector.dart
//
// Lightweight per-message language detector for the Advocat chat pipeline.
//
// ---------------------------------------------------------------------------
// WHY THIS EXISTS (post-launch bug 1, 2026-04-22)
// ---------------------------------------------------------------------------
// Users choose a language during onboarding.  That preference was used as the
// sole input to the Claude system prompt, which contains a strong directive:
//
//     "You MUST respond ONLY in $langName. This is non-negotiable."
//
// The directive overrides the softer "USE THE PERSON'S LANGUAGE NATURALLY"
// personality rule.  Consequence: a user who picked Russian during onboarding
// and then wrote to the AI in Estonian got Russian replies.
//
// Fix: before building the system prompt we detect the language of the CURRENT
// message and — if it differs from the stored preference — override
// userLanguage for this single request.  The profile preference is preserved
// untouched; only the runtime prompt is adjusted.
//
// Design constraints:
//   * No ML, no network — runs inline in the UI thread.
//   * Deterministic / pure — easy to test.
//   * Conservative — if detection is ambiguous, keep the profile preference.
//     We would rather answer in the "wrong" language occasionally than flap
//     mid-conversation on a two-word user turn.
//
// Supported languages match the 17 the app offers:
//   en, ru, et, fi, uk, de, sv, fr, es, it, pl, ro, lt, lv, tr, ar, fa
// plus `el` is NOT supported (not in app).
//
// Detection strategy — in order:
//   1. Script-based hard filters for non-Latin scripts:
//        Cyrillic → ru (default) or uk (if Ukrainian-specific letter present)
//        Arabic  → ar or fa
//        (Latin continues to the keyword pass)
//   2. Keyword / function-word frequency pass for Latin-script languages.
//   3. Accented-character tie-breakers (e.g. õ ä ö ü → Estonian, ä ö → Finnish).
//
// Short utterances (< 3 meaningful chars) return null so the caller can fall
// back to the profile language.

abstract final class LanguageDetector {
  /// Minimum meaningful length before we try to detect.  Anything shorter
  /// returns null — the caller keeps the profile language.
  static const int _minLength = 3;

  // ── Script detection helpers ─────────────────────────────────────────────

  static final RegExp _cyrillicRe = RegExp(r'[\u0400-\u04FF]');
  static final RegExp _arabicRe = RegExp(r'[\u0600-\u06FF]');
  // Ukrainian-specific letters that never appear in standard Russian.
  static final RegExp _ukrainianMarkers = RegExp(r'[іїєґІЇЄҐ]');
  // Persian-specific letters that never appear in standard Arabic.
  static final RegExp _persianMarkers = RegExp(r'[پچژگ]');

  // ── Latin-script keyword tables ──────────────────────────────────────────
  //
  // Each list is a set of short function words / greetings / pronouns that
  // strongly signal the language without common false positives from the
  // others in the app.  Keep lists ~10–25 items; more doesn't help.

  static const List<String> _estonianKeywords = [
    'tere', 'tänan', 'aitäh', 'palun', 'kuule', 'mina', 'sina', 'meie',
    'olen', 'oled', 'on', 'ei', 'jah', 'saa', 'saab', 'saan', 'ole',
    'mis', 'kes', 'kuidas', 'kus', 'millal', 'miks', 'tahan', 'tahad',
    'pean', 'peab', 'päev', 'päeva', 'kohtus', 'seadus', 'kaebus',
  ];

  static const List<String> _finnishKeywords = [
    'hei', 'kiitos', 'kiitti', 'terve', 'minä', 'sinä', 'me', 'olen',
    'olet', 'ei', 'kyllä', 'voin', 'voit', 'voi', 'mitä', 'kuka',
    'miten', 'missä', 'milloin', 'miksi', 'haluan', 'tarvitsen', 'päivä',
    'tuomioistuin', 'laki', 'valitus', 'hallinto',
  ];

  static const List<String> _englishKeywords = [
    'hello', 'hi', 'hey', 'please', 'thanks', 'thank', 'you', 'the', 'and',
    'what', 'how', 'why', 'when', 'where', 'who', 'can', 'could', 'would',
    'should', 'will', 'have', 'has', 'is', 'am', 'are', 'was', 'were',
    'help', 'need', 'want', 'my', 'your', 'me', 'court', 'law',
  ];

  static const List<String> _germanKeywords = [
    'hallo', 'guten', 'bitte', 'danke', 'ich', 'du', 'sie', 'wir', 'bin',
    'bist', 'ist', 'nein', 'ja', 'kann', 'könnte', 'möchte', 'was', 'wer',
    'wie', 'wo', 'wann', 'warum', 'brauche', 'hilfe', 'gericht', 'gesetz',
  ];

  static const List<String> _swedishKeywords = [
    'hej', 'tack', 'snälla', 'jag', 'du', 'vi', 'är', 'var', 'kan',
    'vill', 'måste', 'vad', 'vem', 'hur', 'var', 'när', 'varför',
    'hjälp', 'behöver', 'domstol', 'lag',
  ];

  static const List<String> _frenchKeywords = [
    'bonjour', 'salut', 'merci', 'svp', 'oui', 'non', 'je', 'tu', 'nous',
    'suis', 'es', 'est', 'peux', 'voudrais', 'besoin', 'aide', "qu'est-ce",
    'quoi', 'qui', 'comment', 'où', 'quand', 'pourquoi', 'tribunal', 'loi',
  ];

  static const List<String> _spanishKeywords = [
    'hola', 'gracias', 'por favor', 'sí', 'no', 'yo', 'tú', 'soy', 'eres',
    'puedo', 'quiero', 'necesito', 'ayuda', 'qué', 'quién', 'cómo', 'dónde',
    'cuándo', 'por qué', 'tribunal', 'ley',
  ];

  static const List<String> _italianKeywords = [
    'ciao', 'grazie', 'prego', 'sì', 'io', 'tu', 'noi', 'sono', 'sei',
    'posso', 'voglio', 'aiuto', 'cosa', 'chi', 'come', 'dove', 'quando',
    'perché', 'tribunale', 'legge',
  ];

  static const List<String> _polishKeywords = [
    'cześć', 'dzień', 'dziękuję', 'proszę', 'tak', 'nie', 'ja', 'ty',
    'jestem', 'jesteś', 'mogę', 'chcę', 'pomoc', 'co', 'kto', 'jak',
    'gdzie', 'kiedy', 'dlaczego', 'sąd', 'prawo',
  ];

  static const List<String> _romanianKeywords = [
    'bună', 'salut', 'mulțumesc', 'vă rog', 'da', 'nu', 'eu', 'tu', 'sunt',
    'ești', 'pot', 'vreau', 'ajutor', 'ce', 'cine', 'cum', 'unde', 'când',
    'de ce', 'instanță', 'lege',
  ];

  static const List<String> _lithuanianKeywords = [
    'labas', 'ačiū', 'prašau', 'taip', 'ne', 'aš', 'tu', 'esu', 'esi',
    'galiu', 'noriu', 'pagalba', 'ką', 'kas', 'kaip', 'kur', 'kada',
    'kodėl', 'teismas', 'įstatymas',
  ];

  static const List<String> _latvianKeywords = [
    'sveiki', 'paldies', 'lūdzu', 'jā', 'nē', 'es', 'tu', 'esmu', 'esi',
    'varu', 'gribu', 'palīdzība', 'ko', 'kas', 'kā', 'kur', 'kad',
    'kāpēc', 'tiesa', 'likums',
  ];

  static const List<String> _turkishKeywords = [
    'merhaba', 'selam', 'teşekkür', 'lütfen', 'evet', 'hayır', 'ben', 'sen',
    'biz', 'değil', 'ne', 'kim', 'nasıl', 'nerede', 'ne zaman', 'neden',
    'yardım', 'mahkeme', 'kanun',
  ];

  // ── Cyrillic keyword tables ─────────────────────────────────────────────

  static const List<String> _russianKeywords = [
    'привет', 'здравствуйте', 'спасибо', 'пожалуйста', 'да', 'нет', 'я',
    'ты', 'вы', 'мы', 'он', 'она', 'быть', 'есть', 'был', 'что', 'кто',
    'как', 'где', 'когда', 'почему', 'зачем', 'могу', 'хочу', 'нужно',
    'помощь', 'помоги', 'суд', 'закон', 'жалоба', 'дело',
  ];

  static const List<String> _ukrainianKeywords = [
    'привіт', 'дякую', 'будь ласка', 'так', 'ні', 'я', 'ти', 'ви', 'ми',
    'він', 'вона', 'що', 'хто', 'як', 'де', 'коли', 'чому', 'можу',
    'хочу', 'допомога', 'суд', 'закон', 'скарга', 'справа',
  ];

  // ── Public API ───────────────────────────────────────────────────────────

  /// Detects the language of [text].  Returns an ISO-639-1 code
  /// (`'en'`, `'ru'`, `'et'`, …) or `null` if the text is too short or
  /// the signal is insufficient to decide.
  static String? detect(String text) {
    final cleaned = text.trim();
    if (cleaned.length < _minLength) return null;

    // All digits / punctuation → not language.
    if (!RegExp(r'[a-zA-Zа-яА-ЯÀ-ÿĀ-žА-Яא-ת\u0600-\u06FF\u0400-\u04FF]')
        .hasMatch(cleaned)) {
      return null;
    }

    // ── 1. Script-based filters ─────────────────────────────────────────
    //
    // For mixed-script messages (e.g. Estonian word + one Russian word) we
    // don't short-circuit on the non-Latin script — instead we count every
    // candidate language and let the dominant one win.  Purely non-Latin
    // input always takes the script-based branch.
    final hasCyrillic = _cyrillicRe.hasMatch(cleaned);
    final hasArabic = _arabicRe.hasMatch(cleaned);
    final latinLetters = RegExp(r'[a-zA-ZÀ-ÿĀ-ž]').allMatches(cleaned).length;
    final cyrillicLetters = _cyrillicRe.allMatches(cleaned).length;
    final arabicLetters = _arabicRe.allMatches(cleaned).length;

    if (hasArabic && arabicLetters >= latinLetters) {
      if (_persianMarkers.hasMatch(cleaned)) return 'fa';
      return 'ar';
    }
    if (hasCyrillic && cyrillicLetters > latinLetters) {
      // Cyrillic-dominant → Russian / Ukrainian branch.
      if (_ukrainianMarkers.hasMatch(cleaned)) return 'uk';
      final uk = _countKeywordHits(cleaned, _ukrainianKeywords);
      final ru = _countKeywordHits(cleaned, _russianKeywords);
      if (uk > ru) return 'uk';
      return 'ru';
    }

    // ── 2. Score every candidate by keyword hits ─────────────────────────
    //
    // We include ru / uk here too so Latin-dominant messages with a single
    // Cyrillic word don't flap — whichever language has more hits wins.
    final scores = <String, int>{
      'et': _countKeywordHits(cleaned, _estonianKeywords),
      'fi': _countKeywordHits(cleaned, _finnishKeywords),
      'en': _countKeywordHits(cleaned, _englishKeywords),
      'de': _countKeywordHits(cleaned, _germanKeywords),
      'sv': _countKeywordHits(cleaned, _swedishKeywords),
      'fr': _countKeywordHits(cleaned, _frenchKeywords),
      'es': _countKeywordHits(cleaned, _spanishKeywords),
      'it': _countKeywordHits(cleaned, _italianKeywords),
      'pl': _countKeywordHits(cleaned, _polishKeywords),
      'ro': _countKeywordHits(cleaned, _romanianKeywords),
      'lt': _countKeywordHits(cleaned, _lithuanianKeywords),
      'lv': _countKeywordHits(cleaned, _latvianKeywords),
      'tr': _countKeywordHits(cleaned, _turkishKeywords),
      'ru': _countKeywordHits(cleaned, _russianKeywords),
      'uk': _countKeywordHits(cleaned, _ukrainianKeywords),
    };

    // ── 3. Accented-char tie-breakers ───────────────────────────────────
    // Estonian: õ is the most distinctive letter; ä, ö, ü also common
    // but shared with German/Finnish.
    if (cleaned.contains(RegExp(r'[õÕ]'))) {
      scores['et'] = (scores['et'] ?? 0) + 2;
    }
    // Finnish uses ä and ö but not õ/ü; if we see them without õ and with
    // Finnish tokens, boost Finnish.
    if (cleaned.contains(RegExp(r'[äöÄÖ]')) &&
        !cleaned.contains(RegExp(r'[õÕüÜ]'))) {
      scores['fi'] = (scores['fi'] ?? 0) + 1;
    }
    // German umlauts + ß
    if (cleaned.contains(RegExp(r'[ßÄÖÜäöü]'))) {
      scores['de'] = (scores['de'] ?? 0) + 1;
    }
    // Swedish å + ä + ö
    if (cleaned.contains(RegExp(r'[åÅ]'))) {
      scores['sv'] = (scores['sv'] ?? 0) + 2;
    }
    // Polish
    if (cleaned.contains(RegExp(r'[ąćęłńśźżĄĆĘŁŃŚŹŻ]'))) {
      scores['pl'] = (scores['pl'] ?? 0) + 2;
    }
    // Romanian
    if (cleaned.contains(RegExp(r'[ăâîșțĂÂÎȘȚ]'))) {
      scores['ro'] = (scores['ro'] ?? 0) + 2;
    }
    // Lithuanian
    if (cleaned.contains(RegExp(r'[ąčęėįšųūžĄČĘĖĮŠŲŪŽ]'))) {
      scores['lt'] = (scores['lt'] ?? 0) + 1;
    }
    // Latvian
    if (cleaned.contains(RegExp(r'[āčēģķļņšūžĀČĒĢĶĻŅŠŪŽ]'))) {
      scores['lv'] = (scores['lv'] ?? 0) + 1;
    }
    // Turkish
    if (cleaned.contains(RegExp(r'[çğıöşüÇĞİÖŞÜ]')) &&
        !cleaned.contains(RegExp(r'[õÕäÄ]'))) {
      scores['tr'] = (scores['tr'] ?? 0) + 1;
    }

    // ── 4. Pick best ─────────────────────────────────────────────────────
    var best = '';
    var bestScore = 0;
    scores.forEach((lang, score) {
      if (score > bestScore) {
        bestScore = score;
        best = lang;
      }
    });

    if (bestScore == 0) {
      // Latin alphabet with no recognised keywords — don't guess.
      return null;
    }
    return best;
  }

  /// Integration point for AIService.  Given the user's profile language
  /// preference and the current message, returns the language Claude should
  /// respond in for THIS message.
  ///
  /// Rules:
  ///   * If message-detection fails (too short / unclear) → keep the profile
  ///     preference.
  ///   * If detection succeeds and matches the profile → return the profile.
  ///   * If detection succeeds and differs from the profile → OVERRIDE and
  ///     return the detected code.
  ///   * If the profile is null and detection fails → return null (Claude's
  ///     system prompt has its own fallback wording).
  static String? resolveUserLanguage({
    required String? profileLanguage,
    required String message,
  }) {
    final detected = detect(message);
    if (detected == null) return profileLanguage;
    if (profileLanguage == null) return detected;
    // Only override when it actually differs — avoids spurious reconfigures.
    if (detected == profileLanguage) return profileLanguage;
    return detected;
  }

  // ── Internals ────────────────────────────────────────────────────────────

  /// Counts how many keywords from [keywords] appear in [text] as whole
  /// tokens (case-insensitive).  Token boundary is non-letter.  Returns
  /// hit count, not normalised score.
  static int _countKeywordHits(String text, List<String> keywords) {
    final lower = text.toLowerCase();
    var hits = 0;
    for (final kw in keywords) {
      final k = kw.toLowerCase();
      // Cheap contains() first, then verify with word-boundary match only
      // if contains hits.  Word boundary = start/end of string OR
      // adjacent char is not a letter.
      if (!lower.contains(k)) continue;
      final re = RegExp(
        '(^|[^\\p{L}])${RegExp.escape(k)}([^\\p{L}]|\$)',
        unicode: true,
      );
      if (re.hasMatch(lower)) hits++;
    }
    return hits;
  }
}
