// =============================================================================
// upl_sanitizer.dart — UPL (Unauthorized Practice of Law) post-hoc sanitizer
// =============================================================================
//
// 2026-05-06 — Track B-3 of Pkg 0. STUB implementation. The real sanitizer
// is wired into the chat path in Pkg 0 Phase 2 (after the system-prompt UPL
// rules ship in the same PR as this stub).
//
// Why a stub now:
//   - The system-prompt UPL rules are the FIRST line of defence: they tell
//     the model "do not write 'I recommend filing a lawsuit'". That ships
//     in this PR.
//   - The post-hoc sanitizer is the SECOND line: even if the model slips, a
//     regex pass redacts UPL-violating phrases before they reach the user.
//     That ships in Phase 2 once we have a green-list of approved phrasings.
//   - Tests in `test/services/upl_forbidden_phrases_test.dart` document the
//     forbidden patterns so the regression net is laid before the
//     implementation lands. The tests are `skip:`-ed for now and will
//     un-skip in Phase 2.
//
// DO NOT silently activate this stub by removing the pass-through return —
// doing so would [UPL_REDACTED]-stamp every legitimate reply.
// =============================================================================

/// Replace UPL-violating phrases with a `[UPL_REDACTED]` marker.
///
/// STUB — currently a pass-through. The Phase-2 implementation will use
/// the patterns documented in `test/services/upl_forbidden_phrases_test.dart`:
///
///   - "I recommend filing/suing …"  →  "you may consider filing …"
///   - "Я рекомендую подать иск …"   →  "вы можете рассмотреть подачу иска …"
///   - "Soovitan esitada hagi …"     →  "võite kaaluda hagi esitamist …"
///   - "80 % chance of winning"      →  redacted (UPL: outcome prediction)
///   - "I am Advocat's signature"    →  redacted (UPL: signing on behalf)
///
/// Returns the input verbatim until Phase 2 wiring lands.
String sanitizeUpl(String aiOutput) {
  // NOTE: deliberate pass-through until the green-list of safe replacement
  // phrases has counsel sign-off. Phase-2 will apply forbiddenUplPatterns.
  // See header comment for full rationale.
  return aiOutput;
}

/// The set of regex patterns that the Phase-2 sanitizer will redact.
/// Public so the test suite can pin them without re-deriving the regex.
///
/// Keep multilingual: each phrase must be redacted across EN/ET/RU at
/// minimum. Owner spec from 2026-05-06.
// NOTE on word boundaries:
// Dart RegExp `\b` is ASCII-only — it does NOT recognise Cyrillic / Estonian
// letters as word characters, so `\bРекомендую\b` will never match. For
// non-ASCII patterns we anchor with explicit non-letter context instead
// (start of string OR a non-Cyrillic / non-letter char). Patterns are
// applied with `caseSensitive: false, unicode: true` by callers.
//
// The Cyrillic boundary class includes A-Я-Ёё PLUS the Ukrainian-specific
// letters (Ї, Є, І, ґ, lower equivalents) and the Belarusian Ў/ў so the
// patterns do not falsely fire mid-word in those languages either (W2 fix
// 2026-05-06). Cyrillic boundary literals are duplicated across patterns
// rather than templated to keep them visible at a glance.
const List<String> forbiddenUplPatterns = [
  // EN — directive recommendation
  r'\bI\s+recommend\s+(filing|suing|sueing)\b',
  r'\bI\s+advise\s+you\s+to\s+(file|sue)\b',
  // ET — directive recommendation (Estonian letters are ASCII-mapped enough
  // for \b to work on "Soovitan", "hagi")
  r'\bSoovitan\s+(esitada|teile\s+esitada)\s+hagi\b',
  // RU — directive recommendation. Cannot use \b on Cyrillic — use the
  // (?:^|[^...]) lookbehind-equivalent form: anchor at start of string
  // or a non-Cyrillic-letter char. Same on the trailing edge. Boundary
  // class also covers Ukrainian (ЇїІіЄєҐґ) and Belarusian (Ўў) so the
  // anchor isn't accidentally satisfied mid-word in those languages.
  r'(?:^|[^А-Яа-яЁёЇїІіЄєҐґЎў])Рекомендую[^.!?]{0,40}?подать\s+иск(?:[^А-Яа-яЁёЇїІіЄєҐґЎў]|$)',
  r'(?:^|[^А-Яа-яЁёЇїІіЄєҐґЎў])Я\s+советую\s+вам\s+подать(?:[^А-Яа-яЁёЇїІіЄєҐґЎў]|$)',
  // UK — Ukrainian directive recommendation ("Я раджу подати позов").
  // Uses the same Cyrillic+Ukrainian+Belarusian boundary class.
  r'(?:^|[^А-Яа-яЁёЇїІіЄєҐґЎў])Я\s+раджу\s+подати\s+позов(?:[^А-Яа-яЁёЇїІіЄєҐґЎў]|$)',
  // Outcome prediction (UPL: lawyers do not quote success probabilities).
  // Tightened W1 (2026-05-06): the previous broad
  // `\bchances\s+are\s+(high|low|...)\b` over-fired on legitimate legal
  // information like "the chances are high THAT the deadline applies"
  // and "the chances are high THE court will grant ...". We add a
  // negative lookahead so the pattern fires on bare success-probability
  // claims ("Your chances are high — go ahead") but skips the
  // legal-information forms that follow with "that"/"the". "of" is
  // intentionally NOT in the exclusion: "chances are high of winning"
  // is itself an outcome prediction.
  r'\bchances\s+are\s+(high|low|good|bad|excellent|poor)\b(?!\s+(?:that|the)\b)',
  r'\b\d+\s*%\s*(chance|chance\s+of\s+winning)\b',
  r'\d+\s*%\s*(?:шанс|võiduvõimalus)',
  // Signing on behalf — "Advocat's signature" in EN, free-form on the
  // other side. Use a lookahead for the apostrophe variants.
  r"\bAdvocat(?:'s|s|)\s+signature\b",
  r'(?:^|[^А-Яа-яЁёЇїІіЄєҐґЎў])сигнатура\s+(?:[^.!?]{0,40}?)Advocat',
  r'\bI\s+sign\s+(this|on\s+your\s+behalf)\b',
];
