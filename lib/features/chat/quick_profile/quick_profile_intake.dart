// quick_profile_intake.dart — first-chat intake widget that asks the
// user's legal status once and never again (2026-05-05).
// -----------------------------------------------------------------------------
// Renders four tappable cards underneath an assistant-style intake prompt.
// Three carry a structured answer ([QuickProfileAnswer.estonianCitizen],
// [QuickProfileAnswer.euCitizen], [QuickProfileAnswer.residencePermit])
// and one is a Skip button. Tapping a status card fires [onAnswer] with
// the structured value; the parent screen is responsible for posting
// it to the extract-memory Edge Function with `intake: 'quick_profile'`
// (so the focused prompt picks only legal_status / nationality /
// residence_status, never tone/preference).
//
// Localisation:
//   The widget is locale-driven via the [locale] argument so we can show
//   the correct prompt + chip labels even when tested in isolation
//   without a full AppLocalizations stack. The arb keys
//   (quickProfilePrompt, quickProfileChipEstonianCitizen, etc.) are
//   present in app_en.arb, app_et.arb, app_ru.arb, app_fi.arb,
//   app_de.arb — the inline switch below is the same shape used by
//   welcome_chips.dart for the existing first-conversation prompt.
//
// The widget is intentionally small + stateless — gating is decided
// upstream by [QuickProfileGate]; persistence (the SharedPreferences
// flag) is also upstream so the widget remains pure.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme.dart';

/// One of the four canonical answers the user can tap.
///
/// `toFacts()` produces the (key, value) pairs that the extract-memory
/// Edge Function should upsert as memory rows. Skip yields `[]` — the
/// caller must skip the network round-trip in that case.
enum QuickProfileAnswer {
  estonianCitizen,
  euCitizen,
  residencePermit,
  skip;

  /// Structured facts the Edge Function should upsert. Mirrors the
  /// schema vocabulary in `lib/models/user_memory.dart` and
  /// `supabase/functions/extract-memory/memory_schema.ts`. We hand the
  /// canonical English value to the server because the bounded
  /// vocabulary itself is English ("citizen | eu_citizen | 3rd_country
  /// | …") regardless of UI locale.
  List<({String key, String value})> toFacts() {
    switch (this) {
      case QuickProfileAnswer.estonianCitizen:
        return const [
          (key: 'legal_status', value: 'You are an Estonian citizen.'),
          (key: 'nationality', value: 'EE'),
        ];
      case QuickProfileAnswer.euCitizen:
        return const [
          (
            key: 'legal_status',
            value:
                'You are an EU citizen (eu_citizen) — citizen of an EU member '
                'state other than Estonia.',
          ),
        ];
      case QuickProfileAnswer.residencePermit:
        return const [
          (
            key: 'legal_status',
            value:
                'You are a 3rd_country national living in Estonia under a '
                'residence permit.',
          ),
          (
            key: 'residence_status',
            value: 'temporary',
          ),
        ];
      case QuickProfileAnswer.skip:
        return const [];
    }
  }
}

/// Free-text rendering of an answer, in the user's locale, for echoing
/// back into the chat as a "user" message after they tap a chip.
String quickProfileAnswerLabel(
  QuickProfileAnswer answer,
  String locale,
) {
  final l = locale.toLowerCase();
  switch (answer) {
    case QuickProfileAnswer.estonianCitizen:
      return switch (l) {
        'ru' => 'Гражданин Эстонии',
        'et' => 'Eesti kodanik',
        'fi' => 'Viron kansalainen',
        'de' => 'Estnischer Staatsbürger',
        _ => 'Estonian citizen',
      };
    case QuickProfileAnswer.euCitizen:
      return switch (l) {
        'ru' => 'Гражданин ЕС (другая страна)',
        'et' => 'EL kodanik (muu)',
        'fi' => 'EU-kansalainen (muu)',
        'de' => 'EU-Bürger (anderes Land)',
        _ => 'EU citizen (other)',
      };
    case QuickProfileAnswer.residencePermit:
      return switch (l) {
        'ru' => 'ВНЖ / временный',
        'et' => 'Elamisluba',
        'fi' => 'Oleskelulupa',
        'de' => 'Aufenthaltstitel',
        _ => 'Residence permit',
      };
    case QuickProfileAnswer.skip:
      return switch (l) {
        'ru' => 'Пропустить',
        'et' => 'Jäta vahele',
        'fi' => 'Ohita',
        'de' => 'Überspringen',
        _ => 'Skip',
      };
  }
}

/// Localised intake question. Anchor terms (status / статус / staatus)
/// are tested in `quick_profile_intake_test.dart` so a future copy edit
/// that drops the anchor will fail loudly.
String quickProfilePrompt(String locale) {
  switch (locale.toLowerCase()) {
    case 'ru':
      return 'Чтобы я мог помочь точнее: вы гражданин Эстонии, гражданин ЕС из '
          'другой страны, или у вас вид на жительство (ВНЖ)?';
    case 'et':
      return 'Et saaksin täpsemalt aidata: kas oled Eesti kodanik, mõne '
          'teise EL riigi kodanik, või on sul elamisluba?';
    case 'fi':
      return 'Jotta voin auttaa tarkemmin: oletko Viron kansalainen, toisen '
          'EU-maan kansalainen, vai onko sinulla oleskelulupa?';
    case 'de':
      return 'Damit ich genauer helfen kann: Bist du estnischer '
          'Staatsbürger, EU-Bürger aus einem anderen Land, oder hast du '
          'einen Aufenthaltstitel?';
    default:
      return 'So I can help more precisely, what is your legal status: are '
          'you an Estonian citizen, an EU citizen from another country, or '
          'do you have a residence permit?';
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class QuickProfileIntake extends StatelessWidget {
  const QuickProfileIntake({
    super.key,
    required this.locale,
    required this.onAnswer,
    required this.onSkip,
  });

  /// Active locale code, e.g. `'ru'`, `'et'`, `'en'`. Drives both the
  /// prompt text and chip labels.
  final String locale;

  /// Fired when the user taps one of the three status chips.
  final void Function(QuickProfileAnswer answer) onAnswer;

  /// Fired when the user taps Skip.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final chips = <QuickProfileAnswer>[
      QuickProfileAnswer.estonianCitizen,
      QuickProfileAnswer.euCitizen,
      QuickProfileAnswer.residencePermit,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Intake prompt — rendered as a soft-background paragraph that
          // visually reads as part of the assistant's first turn.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              quickProfilePrompt(locale),
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _QuickProfileChip(
              label: quickProfileAnswerLabel(chips[i], locale),
              onTap: () => onAnswer(chips[i]),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onSkip,
              child: Text(
                quickProfileAnswerLabel(QuickProfileAnswer.skip, locale),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chip card — same visual shape as welcome_chips' suggestion card.
// ---------------------------------------------------------------------------

class _QuickProfileChip extends StatelessWidget {
  const _QuickProfileChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.5),
            ),
            color: AppColors.accent.withValues(alpha: 0.06),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
