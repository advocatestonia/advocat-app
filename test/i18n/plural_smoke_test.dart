@Tags(['fast'])
library;

// =============================================================================
// plural_smoke_test.dart — ICU MessageFormat plural pinning
// =============================================================================
//
// Hardcoded English plural forms ("in X days", "X messages") break for
// languages with more than one/other plural categories. The 17 pluralized
// ARB keys touched in this wave each carry CLDR plural categories per
// locale; this test pins the per-count output for EN + RU so a future
// translation refresh cannot silently regress, e.g. by collapsing all
// non-1 forms into `other` ("через 5 дня" instead of "через 5 дней").
//
// We assert against the generated AppLocalizations classes directly —
// no Flutter widget tree, no BuildContext. The `lookupAppLocalizations`
// factory the codegen emits returns a fully constructed instance per
// locale, which is exactly what we want here.
// =============================================================================

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/l10n/app_localizations.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations ru;

  setUpAll(() async {
    en = lookupAppLocalizations(const Locale('en'));
    ru = lookupAppLocalizations(const Locale('ru'));
  });

  group('EN plural smoke — high-impact count strings', () {
    test('deadlineCardDaysLeft: 0/1/2/5/100', () {
      expect(en.deadlineCardDaysLeft(0), 'today');
      expect(en.deadlineCardDaysLeft(1), 'in 1 day');
      expect(en.deadlineCardDaysLeft(2), 'in 2 days');
      expect(en.deadlineCardDaysLeft(5), 'in 5 days');
      expect(en.deadlineCardDaysLeft(100), 'in 100 days');
    });

    test('deadlineCardOverdue: 1/2/5', () {
      expect(en.deadlineCardOverdue(1), '1 day overdue');
      expect(en.deadlineCardOverdue(2), '2 days overdue');
      expect(en.deadlineCardOverdue(5), '5 days overdue');
    });

    test('issuesFound: 0/1/2/5', () {
      expect(en.issuesFound(0), 'no issues found');
      expect(en.issuesFound(1), '1 issue found');
      expect(en.issuesFound(2), '2 issues found');
      expect(en.issuesFound(5), '5 issues found');
    });

    test('contractReviewsLeft: 0/1/3', () {
      expect(en.contractReviewsLeft(0), 'No contract reviews left this month');
      expect(en.contractReviewsLeft(1), '1 contract review left this month');
      expect(en.contractReviewsLeft(3), '3 contract reviews left this month');
    });

    test('consiliumExpertsAgreed: 1/3', () {
      expect(en.consiliumExpertsAgreed(1), '1 expert agreed');
      expect(en.consiliumExpertsAgreed(3), '3 experts agreed');
    });

    test('pageCount: 0/1/2/5', () {
      expect(en.pageCount(0), 'no pages');
      expect(en.pageCount(1), '1 page');
      expect(en.pageCount(2), '2 pages');
      expect(en.pageCount(5), '5 pages');
    });

    test('citationFooterSummaryTotal: 1/5', () {
      expect(en.citationFooterSummaryTotal(1), '1 citation');
      expect(en.citationFooterSummaryTotal(5), '5 citations');
    });
  });

  group('RU plural smoke — one/few/many categories', () {
    // CLDR Russian:
    //   one  -> 1, 21, 31, ...        (n%10==1 && n%100!=11)
    //   few  -> 2-4, 22-24, ...       (n%10 in 2-4 && n%100 not in 12-14)
    //   many -> 0, 5-20, 25-30, ...   (everything else integer)
    test('deadlineCardDaysLeft RU: 1 день / 2 дня / 5 дней / 21 день', () {
      expect(ru.deadlineCardDaysLeft(0), 'сегодня');
      expect(ru.deadlineCardDaysLeft(1), 'через 1 день');
      expect(ru.deadlineCardDaysLeft(2), 'через 2 дня');
      expect(ru.deadlineCardDaysLeft(3), 'через 3 дня');
      expect(ru.deadlineCardDaysLeft(4), 'через 4 дня');
      expect(ru.deadlineCardDaysLeft(5), 'через 5 дней');
      expect(ru.deadlineCardDaysLeft(11), 'через 11 дней');
      expect(ru.deadlineCardDaysLeft(14), 'через 14 дней');
      expect(ru.deadlineCardDaysLeft(21), 'через 21 день');
      expect(ru.deadlineCardDaysLeft(22), 'через 22 дня');
      expect(ru.deadlineCardDaysLeft(25), 'через 25 дней');
      expect(ru.deadlineCardDaysLeft(100), 'через 100 дней');
    });

    test('deadlineCardOverdue RU: одинаковые правила', () {
      expect(ru.deadlineCardOverdue(1), 'просрочено на 1 день');
      expect(ru.deadlineCardOverdue(2), 'просрочено на 2 дня');
      expect(ru.deadlineCardOverdue(5), 'просрочено на 5 дней');
      expect(ru.deadlineCardOverdue(21), 'просрочено на 21 день');
    });

    test('issuesFound RU: 1 проблема / 2 проблемы / 5 проблем', () {
      expect(ru.issuesFound(0), 'проблем не найдено');
      expect(ru.issuesFound(1), 'Найдена 1 проблема');
      expect(ru.issuesFound(2), 'Найдено 2 проблемы');
      expect(ru.issuesFound(3), 'Найдено 3 проблемы');
      expect(ru.issuesFound(5), 'Найдено 5 проблем');
      expect(ru.issuesFound(21), 'Найдена 21 проблема');
    });

    test('contractReviewsLeft RU: 0/1/2/5/21', () {
      expect(
        ru.contractReviewsLeft(0),
        'В этом месяце проверок договоров не осталось',
      );
      expect(
        ru.contractReviewsLeft(1),
        'Осталась 1 проверка договоров в этом месяце',
      );
      expect(
        ru.contractReviewsLeft(2),
        'Осталось 2 проверки договоров в этом месяце',
      );
      expect(
        ru.contractReviewsLeft(5),
        'Осталось 5 проверок договоров в этом месяце',
      );
      expect(
        ru.contractReviewsLeft(21),
        'Осталась 21 проверка договоров в этом месяце',
      );
    });

    test('consiliumExpertsAgreed RU: 1/3/5', () {
      expect(ru.consiliumExpertsAgreed(1), '1 эксперт согласен');
      expect(ru.consiliumExpertsAgreed(3), '3 эксперта согласны');
      expect(ru.consiliumExpertsAgreed(5), '5 экспертов согласны');
    });

    test('pageCount RU: 0/1/2/5/21', () {
      expect(ru.pageCount(0), 'нет страниц');
      expect(ru.pageCount(1), '1 страница');
      expect(ru.pageCount(2), '2 страницы');
      expect(ru.pageCount(5), '5 страниц');
      expect(ru.pageCount(21), '21 страница');
    });

    test('citationFooterSummaryTotal RU: 1/2/5', () {
      expect(ru.citationFooterSummaryTotal(1), '1 ссылка');
      expect(ru.citationFooterSummaryTotal(2), '2 ссылки');
      expect(ru.citationFooterSummaryTotal(5), '5 ссылок');
    });
  });

  group('Polish plural smoke — one/few/many', () {
    late AppLocalizations pl;
    setUpAll(() => pl = lookupAppLocalizations(const Locale('pl')));

    test('issuesFound PL: 1/2/5', () {
      expect(pl.issuesFound(0), 'nie znaleziono problemów');
      expect(pl.issuesFound(1), 'Znaleziono 1 problem');
      expect(pl.issuesFound(2), 'Znaleziono 2 problemy');
      expect(pl.issuesFound(5), 'Znaleziono 5 problemów');
    });
  });

  group('Ukrainian plural smoke — one/few/many', () {
    late AppLocalizations uk;
    setUpAll(() => uk = lookupAppLocalizations(const Locale('uk')));

    test('deadlineCardDaysLeft UK: 1 день / 2 дні / 5 днів', () {
      expect(uk.deadlineCardDaysLeft(0), 'сьогодні');
      expect(uk.deadlineCardDaysLeft(1), 'через 1 день');
      expect(uk.deadlineCardDaysLeft(2), 'через 2 дні');
      expect(uk.deadlineCardDaysLeft(5), 'через 5 днів');
      expect(uk.deadlineCardDaysLeft(21), 'через 21 день');
    });
  });
}
