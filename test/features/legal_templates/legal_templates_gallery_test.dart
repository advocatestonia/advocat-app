@Tags(['fast'])
library;

// Widget tests for the Legal Template Library gallery (Feature #5).
// -----------------------------------------------------------------------------
// Uses a FakeLegalTemplateService so no Supabase instance is needed.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/legal_templates/models/legal_template.dart';
import 'package:advocat/features/legal_templates/screens/legal_templates_gallery_screen.dart';
import 'package:advocat/features/legal_templates/services/legal_template_service.dart';
import 'package:advocat/l10n/app_localizations.dart';

class _FakeService implements LegalTemplateService {
  _FakeService(this._all);
  final List<LegalTemplate> _all;
  String? lastJurisdiction;

  @override
  Future<List<LegalTemplate>> listTemplates({
    String? jurisdiction,
    String? category,
  }) async {
    lastJurisdiction = jurisdiction;
    return _all
        .where((t) => jurisdiction == null || t.jurisdiction == jurisdiction)
        .toList();
  }

  @override
  Future<FilledTemplate> fillTemplate({
    required String templateId,
    String? caseId,
    Map<String, String> fields = const <String, String>{},
  }) async =>
      const FilledTemplate(
        filled: 'x',
        title: 't',
        slug: 's',
        jurisdiction: 'FI',
        locale: 'fi',
      );
}

LegalTemplate _t(String slug, String juris, {String cat = 'complaint'}) =>
    LegalTemplate(
      id: 'id_$slug',
      slug: slug,
      category: cat,
      jurisdiction: juris,
      locale: juris == 'FI' ? 'fi' : 'et',
      title: 'Title $slug',
      description: 'Desc $slug',
    );

Widget _wrap(_FakeService svc) {
  return ProviderScope(
    overrides: <Override>[
      legalTemplateServiceProvider.overrideWithValue(svc),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LegalTemplatesGalleryScreen(),
    ),
  );
}

void main() {
  testWidgets('renders a card per template + disclaimer', (tester) async {
    final svc = _FakeService(<LegalTemplate>[
      _t('fi_kantelu', 'FI'),
      _t('ee_kaebus', 'EE'),
    ]);
    await tester.pumpWidget(_wrap(svc));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('legal_templates_disclaimer')), findsOneWidget);
    expect(find.byKey(const Key('legal_template_card_fi_kantelu')),
        findsOneWidget);
    expect(find.byKey(const Key('legal_template_card_ee_kaebus')),
        findsOneWidget);
  });

  testWidgets('jurisdiction filter narrows the list', (tester) async {
    final svc = _FakeService(<LegalTemplate>[
      _t('fi_kantelu', 'FI'),
      _t('ee_kaebus', 'EE'),
    ]);
    await tester.pumpWidget(_wrap(svc));
    await tester.pumpAndSettle();

    // Tap the EE filter chip.
    await tester.tap(find.byKey(const Key('legal_templates_filter_EE')));
    await tester.pumpAndSettle();

    expect(svc.lastJurisdiction, 'EE');
    expect(find.byKey(const Key('legal_template_card_ee_kaebus')),
        findsOneWidget);
    expect(
        find.byKey(const Key('legal_template_card_fi_kantelu')), findsNothing);
  });

  testWidgets('empty result shows empty state', (tester) async {
    final svc = _FakeService(<LegalTemplate>[]);
    await tester.pumpWidget(_wrap(svc));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('legal_templates_list')), findsNothing);
  });
}
