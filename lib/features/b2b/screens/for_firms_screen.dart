// =============================================================================
// for_firms_screen.dart
// =============================================================================
//
// One-page B2B contact form. Reachable only from:
//   * the B2B lead modal ("Learn more" CTA), and
//   * a single ghost-text link at the bottom of the Subscription screen.
//
// Intentionally NOT linked from the main pricing carousel — the spec is
// explicit: this is a silent-signal touch surface, not a B2C upsell.
//
// Submission posts to the existing `support-ticket` edge function via
// [B2BService.submitInquiry], category=`b2b_inquiry`. The structured
// payload (firm/team_size/practices) rides alongside the human-readable
// message body so the founders can triage from Telegram without parsing
// JSON.
//
// Localization: en/et/ru/fi/de inline (parity with b2b_lead_modal.dart).
// Everything else falls back to EN.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/b2b_service.dart';

/// Stable widget keys so tests can target form fields + the submit CTA
/// without coupling to localised labels.
class ForFirmsScreenKeys {
  static const Key root = Key('for_firms_screen');
  static const Key form = Key('for_firms_form');
  static const Key nameField = Key('for_firms_name');
  static const Key emailField = Key('for_firms_email');
  static const Key firmField = Key('for_firms_firm');
  static const Key teamSizeField = Key('for_firms_team_size');
  static const Key practicesField = Key('for_firms_practices');
  static const Key painField = Key('for_firms_pain');
  static const Key submit = Key('for_firms_submit');
  static const Key confirmation = Key('for_firms_confirmation');
}

/// Wire-format slugs for the team-size dropdown. Sent verbatim in the
/// `team_size` field of the inquiry payload.
const List<String> kTeamSizeBuckets = ['1', '2-5', '6-15', '15+'];

/// Wire-format slugs for practice areas. Sent as a list in `practices`.
/// Mirrors the founders' triage taxonomy (we add new ones rarely and only
/// after a sales-cycle insight).
const List<String> kPracticeAreas = [
  'immigration',
  'corporate',
  'litigation',
  'family',
  'criminal',
  'labor',
  'tax',
];

class ForFirmsScreen extends ConsumerStatefulWidget {
  const ForFirmsScreen({super.key});

  @override
  ConsumerState<ForFirmsScreen> createState() => _ForFirmsScreenState();
}

class _ForFirmsScreenState extends ConsumerState<ForFirmsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _firmCtrl;
  late final TextEditingController _painCtrl;
  String _teamSize = kTeamSizeBuckets.first;
  final Set<String> _practices = <String>{};

  bool _submitting = false;
  bool _submitted = false;

  /// Cached locale code (en/et/ru/fi/de + fallback). Read once in
  /// didChangeDependencies so build() can stay sync.
  String _locale = 'en';

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _firmCtrl = TextEditingController();
    _painCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.localeOf(context).languageCode.toLowerCase();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _firmCtrl.dispose();
    _painCtrl.dispose();
    super.dispose();
  }

  String _t(String key) => _strings(_locale)[key] ?? _strings('en')[key]!;

  Future<void> _onSubmit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    final service = ref.read(b2bServiceProvider);
    final result = await service.submitInquiry(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      firmName: _firmCtrl.text.trim(),
      teamSize: _teamSize,
      practices: _practices.toList()..sort(),
      biggestPainToday: _painCtrl.text.trim(),
      language: _locale,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      setState(() => _submitted = true);
    } else {
      // Surface the failure with a retry affordance. We do NOT clear the
      // form so the user can retry without re-typing everything.
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(_t('error_generic')),
          action: SnackBarAction(
            label: _t('error_retry'),
            onPressed: _onSubmit,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ForFirmsScreenKeys.root,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_t('heading')),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _submitted ? _buildConfirmation() : _buildForm(),
      ),
    );
  }

  // ── Confirmation panel ─────────────────────────────────────────────
  Widget _buildConfirmation() {
    return Padding(
      key: ForFirmsScreenKeys.confirmation,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 36,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _t('confirmation_title'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _t('confirmation_body'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Form ────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          // Re-key on the form sentinel so the test can find the Form.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Sub-heading ────────────────────────────────────────
              Text(
                _t('subhead'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── 3 "what's included" cards (no prices) ──────────────
              _IncludedCard(
                icon: Icons.groups_2_rounded,
                title: _t('inc_seats_title'),
                body: _t('inc_seats_body'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _IncludedCard(
                icon: Icons.folder_shared_rounded,
                title: _t('inc_shared_title'),
                body: _t('inc_shared_body'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _IncludedCard(
                icon: Icons.fact_check_rounded,
                title: _t('inc_audit_title'),
                body: _t('inc_audit_body'),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Form fields ────────────────────────────────────────
              TextFormField(
                key: ForFirmsScreenKeys.nameField,
                controller: _nameCtrl,
                decoration: _fieldDeco(_t('field_name')),
                textInputAction: TextInputAction.next,
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSpacing.sm),

              TextFormField(
                key: ForFirmsScreenKeys.emailField,
                controller: _emailCtrl,
                decoration: _fieldDeco(_t('field_email')),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _emailValidator,
              ),
              const SizedBox(height: AppSpacing.sm),

              TextFormField(
                key: ForFirmsScreenKeys.firmField,
                controller: _firmCtrl,
                decoration: _fieldDeco(_t('field_firm')),
                textInputAction: TextInputAction.next,
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSpacing.sm),

              DropdownButtonFormField<String>(
                key: ForFirmsScreenKeys.teamSizeField,
                initialValue: _teamSize,
                decoration: _fieldDeco(_t('field_team_size')),
                items: kTeamSizeBuckets
                    .map((b) =>
                        DropdownMenuItem<String>(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _teamSize = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Practices — multi-select via filter chips. Wraps onto
              // multiple lines on narrow viewports.
              Text(
                _t('field_practices'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                key: ForFirmsScreenKeys.practicesField,
                spacing: 6,
                runSpacing: 6,
                children: kPracticeAreas.map((slug) {
                  final selected = _practices.contains(slug);
                  return FilterChip(
                    label: Text(_t('practice_$slug')),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _practices.add(slug);
                        } else {
                          _practices.remove(slug);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                key: ForFirmsScreenKeys.painField,
                controller: _painCtrl,
                decoration: _fieldDeco(_t('field_pain')),
                maxLines: 4,
                minLines: 3,
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  key: ForFirmsScreenKeys.submit,
                  onPressed: _submitting ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_t('submit')),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  InputDecoration _fieldDeco(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    );
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return _t('error_required');
    return null;
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return _t('error_required');
    final trimmed = v.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed)) {
      return _t('error_email');
    }
    return null;
  }

  // ── i18n table ──────────────────────────────────────────────────────

  static Map<String, Map<String, String>> get _table => {
        'en': {
          'heading': 'Advocat for Law Firms',
          'subhead':
              'Multi-seat, shared cases, audit log, white-label options.',
          'inc_seats_title': 'Multi-seat workspace',
          'inc_seats_body':
              "Invite your team — every lawyer keeps their own thread "
                  'history.',
          'inc_shared_title': 'Shared cases & dossiers',
          'inc_shared_body':
              'Hand off a matter mid-stream. Your colleagues see the full '
                  'AI history.',
          'inc_audit_title': 'Audit log & SSO',
          'inc_audit_body':
              'Every AI action timestamped. SSO + DPA included by default.',
          'field_name': 'Your name',
          'field_email': 'Work email',
          'field_firm': 'Firm name',
          'field_team_size': 'Team size',
          'field_practices': 'Practice areas (pick any)',
          'field_pain': "What's your biggest pain today?",
          'submit': 'Send',
          'error_required': 'Required',
          'error_email': 'Enter a valid email',
          'error_generic':
              "We couldn't send your message — please try again.",
          'error_retry': 'Retry',
          'confirmation_title': 'Thank you!',
          'confirmation_body': "We'll get back to you within 24 hours.",
          'practice_immigration': 'Immigration',
          'practice_corporate': 'Corporate',
          'practice_litigation': 'Litigation',
          'practice_family': 'Family',
          'practice_criminal': 'Criminal',
          'practice_labor': 'Labor',
          'practice_tax': 'Tax',
        },
        'et': {
          'heading': 'Advocat advokaadibüroodele',
          'subhead':
              'Mitu kontot, jagatud juhtumid, auditi logi, white-label valikud.',
          'inc_seats_title': 'Mitme kasutaja töökoht',
          'inc_seats_body':
              'Kutsuge oma meeskond — igal juristil oma vestluste ajalugu.',
          'inc_shared_title': 'Jagatud juhtumid ja toimikud',
          'inc_shared_body':
              'Andke asi keset menetlust üle. Kolleegid näevad kogu AI ajalugu.',
          'inc_audit_title': 'Auditi logi ja SSO',
          'inc_audit_body':
              'Iga AI-toiming ajatempliga. SSO ja DPA kuuluvad vaikimisi.',
          'field_name': 'Teie nimi',
          'field_email': 'Tööe-post',
          'field_firm': 'Büroo nimi',
          'field_team_size': 'Meeskonna suurus',
          'field_practices': 'Praktika valdkonnad (valige mitu)',
          'field_pain': 'Mis on Teie suurim valupunkt täna?',
          'submit': 'Saada',
          'error_required': 'Kohustuslik',
          'error_email': 'Sisestage kehtiv e-posti aadress',
          'error_generic':
              'Sõnumit ei õnnestunud saata — proovige uuesti.',
          'error_retry': 'Proovi uuesti',
          'confirmation_title': 'Aitäh!',
          'confirmation_body': 'Võtame ühendust 24 tunni jooksul.',
          'practice_immigration': 'Migratsioon',
          'practice_corporate': 'Äriõigus',
          'practice_litigation': 'Kohtuvaidlused',
          'practice_family': 'Perekonnaõigus',
          'practice_criminal': 'Kriminaalõigus',
          'practice_labor': 'Tööõigus',
          'practice_tax': 'Maksuõigus',
        },
        'ru': {
          'heading': 'Advocat для юридических фирм',
          'subhead':
              'Multi-seat, общие дела, журнал аудита, white-label опции.',
          'inc_seats_title': 'Multi-seat workspace',
          'inc_seats_body':
              'Пригласите команду — у каждого юриста своя история диалогов.',
          'inc_shared_title': 'Общие дела и досье',
          'inc_shared_body':
              'Передавайте дело по ходу — коллеги видят всю историю AI.',
          'inc_audit_title': 'Журнал аудита и SSO',
          'inc_audit_body':
              'Все действия AI с временными метками. SSO + DPA включены.',
          'field_name': 'Ваше имя',
          'field_email': 'Рабочий e-mail',
          'field_firm': 'Название фирмы',
          'field_team_size': 'Размер команды',
          'field_practices': 'Направления (выберите несколько)',
          'field_pain': 'Какая ваша главная боль сегодня?',
          'submit': 'Отправить',
          'error_required': 'Обязательное поле',
          'error_email': 'Введите корректный e-mail',
          'error_generic':
              'Не удалось отправить сообщение — попробуйте ещё раз.',
          'error_retry': 'Повторить',
          'confirmation_title': 'Спасибо!',
          'confirmation_body': 'Свяжемся в течение 24 часов.',
          'practice_immigration': 'Миграция',
          'practice_corporate': 'Корпоративное',
          'practice_litigation': 'Судебные споры',
          'practice_family': 'Семейное',
          'practice_criminal': 'Уголовное',
          'practice_labor': 'Трудовое',
          'practice_tax': 'Налоговое',
        },
        'fi': {
          'heading': 'Advocat asianajotoimistoille',
          'subhead':
              'Useita käyttäjiä, jaetut tapaukset, auditointiloki, '
                  'white-label-vaihtoehdot.',
          'inc_seats_title': 'Monikäyttäjäympäristö',
          'inc_seats_body':
              'Kutsu tiimisi — jokaisella juristilla oma keskusteluhistoria.',
          'inc_shared_title': 'Jaetut tapaukset ja kansiot',
          'inc_shared_body':
              'Siirrä asia kesken — kollegat näkevät koko AI-historian.',
          'inc_audit_title': 'Auditointiloki ja SSO',
          'inc_audit_body':
              'Jokainen AI-toimi aikaleimattu. SSO + DPA mukana oletuksena.',
          'field_name': 'Nimesi',
          'field_email': 'Työ­sähköposti',
          'field_firm': 'Toimiston nimi',
          'field_team_size': 'Tiimin koko',
          'field_practices': 'Käytännön alat (valitse useita)',
          'field_pain': 'Mikä on suurin kipupisteesi tänään?',
          'submit': 'Lähetä',
          'error_required': 'Pakollinen kenttä',
          'error_email': 'Syötä kelvollinen sähköpostiosoite',
          'error_generic':
              'Viestin lähetys epäonnistui — yritä uudelleen.',
          'error_retry': 'Yritä uudelleen',
          'confirmation_title': 'Kiitos!',
          'confirmation_body': 'Olemme yhteydessä 24 tunnin sisällä.',
          'practice_immigration': 'Maahanmuutto',
          'practice_corporate': 'Yhtiöoikeus',
          'practice_litigation': 'Oikeudenkäynnit',
          'practice_family': 'Perheoikeus',
          'practice_criminal': 'Rikosoikeus',
          'practice_labor': 'Työoikeus',
          'practice_tax': 'Vero-oikeus',
        },
        'de': {
          'heading': 'Advocat für Kanzleien',
          'subhead':
              'Multi-Seat, geteilte Fälle, Audit-Log, White-Label-Optionen.',
          'inc_seats_title': 'Multi-Seat-Arbeitsbereich',
          'inc_seats_body':
              'Laden Sie Ihr Team ein — jede Anwältin behält ihren eigenen '
                  'Verlauf.',
          'inc_shared_title': 'Gemeinsame Fälle & Dossiers',
          'inc_shared_body':
              'Geben Sie einen Fall mittendrin ab. Kollegen sehen die '
                  'gesamte KI-Historie.',
          'inc_audit_title': 'Audit-Log & SSO',
          'inc_audit_body':
              'Jede KI-Aktion mit Zeitstempel. SSO + DPA standardmäßig dabei.',
          'field_name': 'Ihr Name',
          'field_email': 'Geschäftliche E-Mail',
          'field_firm': 'Kanzleiname',
          'field_team_size': 'Teamgröße',
          'field_practices': 'Rechtsgebiete (Mehrfachauswahl)',
          'field_pain': 'Was ist heute Ihr größtes Problem?',
          'submit': 'Senden',
          'error_required': 'Pflichtfeld',
          'error_email': 'Bitte gültige E-Mail eingeben',
          'error_generic':
              'Nachricht konnte nicht gesendet werden — bitte erneut versuchen.',
          'error_retry': 'Erneut versuchen',
          'confirmation_title': 'Vielen Dank!',
          'confirmation_body':
              'Wir melden uns innerhalb von 24 Stunden bei Ihnen.',
          'practice_immigration': 'Migration',
          'practice_corporate': 'Gesellschaftsrecht',
          'practice_litigation': 'Streitbeilegung',
          'practice_family': 'Familienrecht',
          'practice_criminal': 'Strafrecht',
          'practice_labor': 'Arbeitsrecht',
          'practice_tax': 'Steuerrecht',
        },
      };

  static Map<String, String> _strings(String code) {
    return _table[code.toLowerCase()] ?? _table['en']!;
  }
}

/// Single "what's included" card. Three of these stack at the top of the
/// form so the user sees concrete value props (no prices) before reaching
/// the first field.
class _IncludedCard extends StatelessWidget {
  const _IncludedCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
