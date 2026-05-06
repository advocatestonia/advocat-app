// =====================================================================
// IntakeWizardScreen — Pkg 3 host. 5-step PageView with Next/Back +
// Урент-shortcut + AI greeting on finish.
//
// Replaces the minimal /cases-v2/new placeholder shipped in Pkg 1.D.
//
// State:
//   - Wizard fields live in `intakeWizardProvider` (persisted in
//     SharedPreferences).
//   - Staged docs live in `stagedDocumentsProvider` (in-memory,
//     non-persisted).
//   - Active case is set via `activeCaseProvider` once the row is
//     created.
//
// Finish flow:
//   1. createCase() with required step 1 + step 2 fields, plus a title
//      derived from the case type / authority for now (the user can
//      always rename later in /cases-v2/:id/edit).
//   2. Upload each staged doc → case_documents row (parsed_text=null;
//      Pkg 2 fills it asynchronously).
//   3. Set the new case active.
//   4. Generate the AI greeting (with 8 s timeout fallback to a
//      deterministic template) and persist as the first assistant
//      chat message for the case.
//   5. Navigate to /chat/:caseId — the user sees the greeting waiting.
//
// Урент flow:
//   - From step 1-4, the top-right "У меня горит" button creates a
//     draft case with whatever fields are populated, marks it active,
//     persists the urgent fallback greeting, navigates to chat.
//   - The wizard can be resumed later from the case detail screen.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/case_repository.dart';
import '../../models/user_case.dart';
import '../../services/intake_greeting_service.dart';
import '../../state/active_case_provider.dart';
import '../../state/cases_list_provider.dart';
import '../../state/intake_wizard_state.dart';
import 'step1_where_screen.dart';
import 'step2_what_screen.dart';
import 'step3_parties_screen.dart';
import 'step4_dates_numbers_screen.dart';
import 'step5_documents_screen.dart';

class IntakeWizardScreen extends ConsumerStatefulWidget {
  const IntakeWizardScreen({super.key});

  @override
  ConsumerState<IntakeWizardScreen> createState() => _IntakeWizardScreenState();
}

class _IntakeWizardScreenState extends ConsumerState<IntakeWizardScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _busy = false;

  static const _pages = <Widget>[
    Step1WhereScreen(),
    Step2WhatScreen(),
    Step3PartiesScreen(),
    Step4DatesNumbersScreen(),
    Step5DocumentsScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _canAdvance(IntakeDraft draft) {
    switch (_currentPage) {
      case 0:
        return draft.step1Complete;
      case 1:
        return draft.step2Complete;
      default:
        return true;
    }
  }

  Future<void> _next() async {
    if (_currentPage < kIntakeWizardStepCount - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _finish();
    }
  }

  Future<void> _back() async {
    if (_currentPage == 0) {
      if (mounted) context.pop();
      return;
    }
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Computes a sensible default title from whatever the user filled
  /// in. Pkg 1.D's edit screen lets the user rename freely later.
  String _autoTitle(IntakeDraft draft, AppLocalizations? l10n) {
    final pieces = <String>[];
    if (draft.caseType != null) {
      pieces.add(draft.caseType!.dbValue);
    }
    if (draft.jurisdiction != null && draft.jurisdiction!.isNotEmpty) {
      pieces.add(draft.jurisdiction!);
    }
    if (draft.authorityName.isNotEmpty) {
      pieces.add(draft.authorityName);
    } else if (draft.authorityType != null) {
      pieces.add(draft.authorityType!.dbValue);
    }
    if (pieces.isEmpty) return l10n?.newCase ?? 'New case';
    return pieces.join(' / ');
  }

  String _appLanguageFromLocale(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    const supported = {'ru', 'en', 'et', 'fi', 'uk'};
    return supported.contains(code) ? code : 'ru';
  }

  Future<void> _onUrgent() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.intakeUrgentDialogTitle ?? 'Open chat now?'),
        content: Text(l10n?.intakeUrgentDialogBody ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.intakeUrgentCancel ?? 'Cancel'),
          ),
          ElevatedButton(
            key: const Key('intake-urgent-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.intakeUrgentConfirm ?? 'Open chat'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Mark the draft urgent so the greeting service uses the urgent
    // fallback template.
    ref
        .read(intakeWizardProvider.notifier)
        .update((d) => d.copyWith(urgentShortcutTaken: true));

    await _materializeCaseAndGo();
  }

  Future<void> _finish() async => _materializeCaseAndGo();

  /// The single create-and-go path. Used by both the Finish button on
  /// step 5 and the urgent shortcut from any step.
  Future<void> _materializeCaseAndGo() async {
    if (_busy) return;
    setState(() => _busy = true);

    final l10n = AppLocalizations.of(context);
    final draft = ref.read(intakeWizardProvider);
    final repo = ref.read(caseRepositoryProvider);
    final greetSvc = ref.read(intakeGreetingServiceProvider);
    final language = _appLanguageFromLocale(context);

    UserCase? created;
    try {
      created = await repo.createCase(
        title: _autoTitle(draft, l10n),
        jurisdiction: draft.jurisdiction ?? 'EE',
        caseType: draft.caseType?.dbValue,
        language: language,
      );

      // Upload staged docs (best-effort — failures don't abort the
      // wizard, the user still gets to chat).
      final staged = ref.read(stagedDocumentsProvider);
      final filenames = <String>[];
      for (final doc in staged) {
        try {
          await repo.uploadDocument(
            caseId: created.id,
            filename: doc.filename,
            bytes: doc.bytes,
            mimeType: doc.mimeType,
          );
          filenames.add(doc.filename);
        } catch (_) {/* skip — surfaced via snackbar below if any fail */}
      }

      // Mark active before greeting so claude-proxy injects this case
      // on the first user message.
      await ref.read(activeCaseProvider.notifier).setActiveCase(created);

      // Invalidate list cache so /cases-v2 shows the new row.
      ref.invalidate(casesListProvider);

      // Greeting — bounded, never throws.
      await greetSvc.generateAndPersist(
        userCase: created,
        draft: draft,
        uploadedFilenames: filenames,
      );

      // Wipe the wizard draft + staged docs now that we're done.
      await ref.read(intakeWizardProvider.notifier).clearDraft();
      ref.read(stagedDocumentsProvider.notifier).state = const [];

      if (!mounted) return;
      context.go('/chat/${created.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(intakeWizardProvider);
    final canAdvance = _canAdvance(draft);
    final isLastStep = _currentPage == kIntakeWizardStepCount - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.newCase ?? 'New case'),
        actions: [
          if (_currentPage < kIntakeWizardStepCount - 1)
            TextButton(
              key: const Key('intake-urgent-btn'),
              onPressed: _busy ? null : _onUrgent,
              child: Text(
                l10n?.intakeUrgentBtn ?? 'Urgent — ask now',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Column(
          children: [
            _StepIndicator(
              current: _currentPage + 1,
              total: kIntakeWizardStepCount,
            ),
            Expanded(
              child: PageView(
                key: const Key('intake-wizard-pageview'),
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: _pages,
              ),
            ),
            if (_busy)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n?.intakePreparingCase ?? 'Preparing your case…'),
                  ],
                ),
              ),
            _NavBar(
              onBack: _busy ? null : _back,
              onNext: _busy || !canAdvance ? null : _next,
              nextLabel: isLastStep
                  ? (l10n?.intakeFinishBtn ?? 'Finish')
                  : (l10n?.intakeNextBtn ?? 'Next'),
              backLabel: l10n?.intakeBackBtn ?? 'Back',
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 1; i <= total; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.symmetric(
                      horizontal: i == 1 || i == total ? 0 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: i <= current
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n?.intakeStepIndicator(current, total) ??
                  'Step $current of $total',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
    required this.backLabel,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('intake-back-btn'),
                onPressed: onBack,
                child: Text(backLabel),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                key: const Key('intake-next-btn'),
                onPressed: onNext,
                child: Text(nextLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
