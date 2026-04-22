import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../models/case_model.dart';
import 'action_chip.dart';

// ---------------------------------------------------------------------------
// Post-launch BUG 3 fix (2026-04-22): first-conversation category prompt
// ---------------------------------------------------------------------------
//
// Problem: new users land on the chat screen with a generic "Hello!"
// message and no hint about how to start the conversation.
//
// Fix: render this widget below the first assistant welcome message when
// the conversation is empty. It gives the user five tappable categories
// that pre-fill the input with a natural-language starter in their
// current locale ("Мне нужна помощь с депортацией", "Pean saama abi
// tööalaste vaidluste puhul", etc.).
//
// The widget is stateless and unopinionated about sending — it fires
// [onCategorySelected] with the category + the pre-filled text, and the
// parent decides whether to immediately send or let the user edit.

enum WelcomeCategory {
  deportation,
  workDispute,
  familyLaw,
  housing,
  other;

  /// Corresponding CaseType for auto-created cases.
  CaseType get caseType {
    switch (this) {
      case WelcomeCategory.deportation:
        return CaseType.deportation;
      case WelcomeCategory.workDispute:
        return CaseType.laborDispute;
      case WelcomeCategory.familyLaw:
        // Closest existing type — family reunification covers divorce,
        // custody, reunification claims in the current domain model.
        return CaseType.familyReunification;
      case WelcomeCategory.housing:
        return CaseType.tenantRights;
      case WelcomeCategory.other:
        return CaseType.other;
    }
  }

  /// Short label rendered on the chip, localised.
  String chipLabel(String locale) {
    final l = locale.toLowerCase();
    switch (this) {
      case WelcomeCategory.deportation:
        return switch (l) {
          'ru' => 'Депортация',
          'et' => 'Väljasaatmine',
          'fi' => 'Maastakarkotus',
          'uk' => 'Депортація',
          'de' => 'Abschiebung',
          'sv' => 'Utvisning',
          'fr' => 'Expulsion',
          'es' => 'Deportación',
          'it' => 'Espulsione',
          'pl' => 'Deportacja',
          'ro' => 'Deportare',
          'lt' => 'Deportacija',
          'lv' => 'Deportācija',
          'tr' => 'Sınır dışı',
          'ar' => 'الترحيل',
          'fa' => 'اخراج',
          _ => 'Deportation',
        };
      case WelcomeCategory.workDispute:
        return switch (l) {
          'ru' => 'Трудовой спор',
          'et' => 'Tööalane vaidlus',
          'fi' => 'Työriita',
          'uk' => 'Трудовий спір',
          'de' => 'Arbeitsstreit',
          'sv' => 'Arbetstvist',
          'fr' => 'Conflit du travail',
          'es' => 'Conflicto laboral',
          'it' => 'Controversia di lavoro',
          'pl' => 'Spór pracowniczy',
          'ro' => 'Conflict de muncă',
          'lt' => 'Darbo ginčas',
          'lv' => 'Darba strīds',
          'tr' => 'İş anlaşmazlığı',
          'ar' => 'نزاع عمل',
          'fa' => 'اختلاف کاری',
          _ => 'Work dispute',
        };
      case WelcomeCategory.familyLaw:
        return switch (l) {
          'ru' => 'Семейное право',
          'et' => 'Perekonnaõigus',
          'fi' => 'Perheoikeus',
          'uk' => 'Сімейне право',
          'de' => 'Familienrecht',
          'sv' => 'Familjerätt',
          'fr' => 'Droit familial',
          'es' => 'Derecho familiar',
          'it' => 'Diritto di famiglia',
          'pl' => 'Prawo rodzinne',
          'ro' => 'Dreptul familiei',
          'lt' => 'Šeimos teisė',
          'lv' => 'Ģimenes tiesības',
          'tr' => 'Aile hukuku',
          'ar' => 'قانون الأسرة',
          'fa' => 'حقوق خانواده',
          _ => 'Family law',
        };
      case WelcomeCategory.housing:
        return switch (l) {
          'ru' => 'Аренда жилья',
          'et' => 'Eluaseme üür',
          'fi' => 'Asuntoasia',
          'uk' => 'Оренда житла',
          'de' => 'Wohnen / Miete',
          'sv' => 'Bostad / Hyra',
          'fr' => 'Logement / Location',
          'es' => 'Alquiler / Vivienda',
          'it' => 'Affitto / Alloggio',
          'pl' => 'Najem / Mieszkanie',
          'ro' => 'Închiriere locuință',
          'lt' => 'Būsto nuoma',
          'lv' => 'Mājokļa īre',
          'tr' => 'Kira / Konut',
          'ar' => 'الإيجار / السكن',
          'fa' => 'اجاره / مسکن',
          _ => 'Housing',
        };
      case WelcomeCategory.other:
        return switch (l) {
          'ru' => 'Другое',
          'et' => 'Muu',
          'fi' => 'Muu',
          'uk' => 'Інше',
          'de' => 'Anderes',
          'sv' => 'Annat',
          'fr' => 'Autre',
          'es' => 'Otro',
          'it' => 'Altro',
          'pl' => 'Inne',
          'ro' => 'Altul',
          'lt' => 'Kita',
          'lv' => 'Cits',
          'tr' => 'Diğer',
          'ar' => 'آخر',
          'fa' => 'سایر',
          _ => 'Other',
        };
    }
  }

  /// Natural-language starter that gets pre-filled in the message input.
  /// Uses a friendly first-person phrasing — the AI receives this as if
  /// the user typed it.
  String prefillMessage(String locale) {
    final l = locale.toLowerCase();
    switch (this) {
      case WelcomeCategory.deportation:
        return switch (l) {
          'ru' => 'Мне нужна помощь с депортацией. Что делать?',
          'et' =>
            'Vajan abi väljasaatmismenetlusega. Mida teha?',
          'fi' =>
            'Tarvitsen apua maastakarkotus- tai käännytysasiassa. Mitä tehdä?',
          'uk' => 'Мені потрібна допомога з депортацією. Що робити?',
          _ => 'I need help with a deportation case. What should I do?',
        };
      case WelcomeCategory.workDispute:
        return switch (l) {
          'ru' =>
            'У меня трудовой спор с работодателем. Помогите разобраться.',
          'et' =>
            'Mul on vaidlus tööandjaga. Palun aita mul olukord lahendada.',
          'fi' =>
            'Minulla on työriita työnantajani kanssa. Auta minua selvittämään asia.',
          'uk' =>
            'У мене трудовий спір з роботодавцем. Допоможіть розібратися.',
          _ =>
            'I have an employment dispute with my employer. Please help me.',
        };
      case WelcomeCategory.familyLaw:
        return switch (l) {
          'ru' =>
            'Мне нужна консультация по семейному праву (развод, дети, алименты).',
          'et' =>
            'Vajan nõu perekonnaõiguse küsimuses (lahutus, lapsed, elatis).',
          'fi' =>
            'Tarvitsen neuvoa perheoikeudellisissa asioissa (avioero, lapset, elatusapu).',
          'uk' =>
            'Мені потрібна консультація з сімейного права (розлучення, діти, аліменти).',
          _ =>
            'I need family-law advice (divorce, children, maintenance).',
        };
      case WelcomeCategory.housing:
        return switch (l) {
          'ru' =>
            'У меня проблема с арендой жилья (депозит, договор, выселение).',
          'et' =>
            'Mul on probleem eluaseme üürilepinguga (tagatisraha, leping, väljaajamine).',
          'fi' =>
            'Minulla on ongelma vuokra-asunnon kanssa (vakuus, sopimus, häätö).',
          'uk' =>
            'У мене проблема з орендою житла (застава, договір, виселення).',
          _ =>
            'I have a housing / rental problem (deposit, contract, eviction).',
        };
      case WelcomeCategory.other:
        return switch (l) {
          'ru' =>
            'У меня другой юридический вопрос. Расскажу ситуацию ниже.',
          'et' =>
            'Mul on muu õigusküsimus. Selgitan olukorda allpool.',
          'fi' =>
            'Minulla on muu oikeudellinen kysymys. Kerron tilanteesta alla.',
          'uk' =>
            'У мене інше правове питання. Опишу ситуацію нижче.',
          _ =>
            'I have a different legal question. Let me describe the situation below.',
        };
    }
  }

  /// Icon shown inside the chip for quick visual scanning.
  IconData get icon {
    switch (this) {
      case WelcomeCategory.deportation:
        return Icons.flight_takeoff_rounded;
      case WelcomeCategory.workDispute:
        return Icons.work_outline_rounded;
      case WelcomeCategory.familyLaw:
        return Icons.family_restroom_rounded;
      case WelcomeCategory.housing:
        return Icons.home_outlined;
      case WelcomeCategory.other:
        return Icons.help_outline_rounded;
    }
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class ChatWelcomeChips extends StatelessWidget {
  const ChatWelcomeChips({
    super.key,
    required this.locale,
    required this.onCategorySelected,
    required this.onSkip,
  });

  /// Active locale code, e.g. `'ru'`, `'et'`, `'en'`.
  final String locale;

  /// Fired when the user taps a category chip.  [prefill] is the
  /// pre-built message in the current locale that the parent should
  /// insert into the text field (and optionally send immediately).
  final void Function(WelcomeCategory category, String prefill)
      onCategorySelected;

  /// Fired when the user taps the "skip" link below the chips.
  final VoidCallback onSkip;

  String _skipLabel() {
    switch (locale.toLowerCase()) {
      case 'ru':
        return 'Пропустить';
      case 'et':
        return 'Jäta vahele';
      case 'fi':
        return 'Ohita';
      case 'uk':
        return 'Пропустити';
      case 'de':
        return 'Überspringen';
      case 'sv':
        return 'Hoppa över';
      case 'fr':
        return 'Passer';
      case 'es':
        return 'Omitir';
      case 'it':
        return 'Salta';
      case 'pl':
        return 'Pomiń';
      case 'ro':
        return 'Sari peste';
      case 'lt':
        return 'Praleisti';
      case 'lv':
        return 'Izlaist';
      case 'tr':
        return 'Atla';
      case 'ar':
        return 'تخطي';
      case 'fa':
        return 'رد کردن';
      default:
        return 'Skip';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in WelcomeCategory.values)
                ChatActionChip(
                  label: cat.chipLabel(locale),
                  icon: cat.icon,
                  onTap: () => onCategorySelected(
                    cat,
                    cat.prefillMessage(locale),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onSkip,
              child: Text(
                _skipLabel(),
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
