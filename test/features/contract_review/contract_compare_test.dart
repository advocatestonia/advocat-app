@Tags(['fast'])
library;

// =============================================================================
// contract_compare_test.dart — unit + widget tests for Contract Version
// Compare (the v1-vs-v2 diff feature).
// =============================================================================
//
// Coverage:
//   1. ContractChangeView.fromJson maps + defaults enums correctly.
//   2. ContractCompareResultView.fromJson parses counts + nested changes and
//      tolerates a missing/garbled changes list.
//   3. ContractChangeCard renders the clause, explanation, direction label,
//      and before/after diff quotes.
//   4. Direction colour mapping is correct (favorable=green, adverse=red).
//
// We do NOT spin up Supabase: upload + edge-fn calls live inside the State
// class; the edge function itself is covered by the Deno tests under
// supabase/functions/contract-compare/__tests__.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/config/theme.dart';
import 'package:advocat/features/contract_review/screens/contract_compare_screen.dart';
import 'package:advocat/features/contract_review/widgets/contract_change_card.dart';

void main() {
  group('ContractChangeView.fromJson', () {
    test('maps a fully-populated change', () {
      final v = ContractChangeView.fromJson({
        'clause': 'Liability cap',
        'kind': 'modified',
        'direction': 'adverse',
        'severity': 'High',
        'explanation': 'Cap removed; unlimited liability now.',
        'before_quote': 'Liability capped at fees paid.',
        'after_quote': 'No limitation of liability applies.',
      });
      expect(v.clause, 'Liability cap');
      expect(v.kind, ContractChangeKind.modified);
      expect(v.direction, ContractChangeDirection.adverse);
      expect(v.severity, 'high'); // lower-cased
      expect(v.beforeQuote, isNotNull);
      expect(v.afterQuote, isNotNull);
    });

    test('defaults unknown enums + drops empty quotes', () {
      final v = ContractChangeView.fromJson({
        'clause': 'X',
        'kind': 'weird',
        'direction': 'weird',
        'explanation': 'e',
        'before_quote': '   ',
      });
      expect(v.kind, ContractChangeKind.modified);
      expect(v.direction, ContractChangeDirection.neutral);
      expect(v.severity, 'info');
      expect(v.beforeQuote, isNull);
    });
  });

  group('ContractCompareResultView.fromJson', () {
    test('parses counts + nested changes', () {
      final r = ContractCompareResultView.fromJson({
        'summary': 'Net worse for tenant.',
        'overall_direction': 'adverse',
        'adverse_count': 2,
        'favorable_count': 1,
        'truncated': true,
        'changes': [
          {
            'clause': 'Rent',
            'direction': 'adverse',
            'explanation': 'CPI-indexed.',
          },
          {
            'clause': 'Notice',
            'direction': 'favorable',
            'explanation': 'Longer notice.',
          },
        ],
      });
      expect(r.summary, 'Net worse for tenant.');
      expect(r.overallDirection, ContractChangeDirection.adverse);
      expect(r.adverseCount, 2);
      expect(r.favorableCount, 1);
      expect(r.truncated, isTrue);
      expect(r.changes.length, 2);
    });

    test('tolerates missing/garbled changes list', () {
      final r = ContractCompareResultView.fromJson({
        'summary': 's',
        'changes': 'not a list',
      });
      expect(r.changes, isEmpty);
      expect(r.overallDirection, ContractChangeDirection.neutral);
      expect(r.adverseCount, 0);
    });
  });

  group('direction colour mapping', () {
    test('favorable -> success, adverse -> error, neutral -> secondary', () {
      expect(
        contractChangeDirectionColor(ContractChangeDirection.favorable),
        AppColors.success,
      );
      expect(
        contractChangeDirectionColor(ContractChangeDirection.adverse),
        AppColors.error,
      );
      expect(
        contractChangeDirectionColor(ContractChangeDirection.neutral),
        AppColors.textSecondary,
      );
    });
  });

  group('ContractChangeCard widget', () {
    testWidgets('renders clause, explanation, label, and diff quotes',
        (tester) async {
      const change = ContractChangeView(
        clause: 'Termination notice',
        kind: ContractChangeKind.modified,
        direction: ContractChangeDirection.adverse,
        severity: 'high',
        explanation: 'Notice period cut from 90 to 30 days.',
        beforeQuote: '90 days written notice.',
        afterQuote: '30 days written notice.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ContractChangeCard(
                change: change,
                adverseLabel: 'Adverse',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Termination notice'), findsOneWidget);
      expect(
        find.text('Notice period cut from 90 to 30 days.'),
        findsOneWidget,
      );
      expect(find.text('Adverse'), findsOneWidget);
      expect(find.text('90 days written notice.'), findsOneWidget);
      expect(find.text('30 days written notice.'), findsOneWidget);
    });

    testWidgets('hides quote rows when absent', (tester) async {
      const change = ContractChangeView(
        clause: 'New audit clause',
        kind: ContractChangeKind.added,
        direction: ContractChangeDirection.favorable,
        severity: 'good',
        explanation: 'Adds an audit right in your favour.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContractChangeCard(
              change: change,
              favorableLabel: 'Favorable',
            ),
          ),
        ),
      );

      expect(find.text('New audit clause'), findsOneWidget);
      expect(find.text('Favorable'), findsOneWidget);
      // No before/after labels should appear.
      expect(find.text('BEFORE'), findsNothing);
      expect(find.text('AFTER'), findsNothing);
    });
  });
}
