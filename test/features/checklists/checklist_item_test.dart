// Tests for the pure Case Checklist model logic — parsing the RPC
// payload, computing progress, and applying optimistic toggles. No
// Supabase / widget dependencies, so these run fast and isolated.
//
// ignore_for_file: prefer_const_literals_to_create_immutables
// (test fixtures intentionally use plain list/map literals for clarity.)

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/checklists/models/checklist_item.dart';

void main() {
  group('ChecklistItem.fromJson', () {
    test('parses a full row', () {
      final item = ChecklistItem.fromJson({
        'item_id': 'aaaa-1111',
        'step_order': 2,
        'title': 'Request decision in writing',
        'description': 'Ask for the grounds.',
        'deadline_days': 30,
        'done': true,
      });

      expect(item.itemId, 'aaaa-1111');
      expect(item.stepOrder, 2);
      expect(item.title, 'Request decision in writing');
      expect(item.description, 'Ask for the grounds.');
      expect(item.deadlineDays, 30);
      expect(item.done, isTrue);
    });

    test('tolerates missing optional fields', () {
      final item = ChecklistItem.fromJson({
        'item_id': 'bbbb-2222',
        'step_order': 1,
        'title': 'Gather documents',
        'description': null,
        'deadline_days': null,
        'done': false,
      });

      expect(item.description, isNull);
      expect(item.deadlineDays, isNull);
      expect(item.done, isFalse);
    });

    test('treats non-true done as false', () {
      final item = ChecklistItem.fromJson({
        'item_id': 'cccc-3333',
        'step_order': 1,
        'title': 'Step',
        'done': null,
      });
      expect(item.done, isFalse);
    });
  });

  group('CaseChecklist.fromRpc', () {
    test('returns empty for a non-list payload', () {
      expect(CaseChecklist.fromRpc(null).isEmpty, isTrue);
      expect(CaseChecklist.fromRpc('oops').isEmpty, isTrue);
      expect(CaseChecklist.fromRpc(42).isEmpty, isTrue);
    });

    test('parses and sorts by step_order', () {
      final checklist = CaseChecklist.fromRpc([
        {'item_id': 'b', 'step_order': 3, 'title': 'Third', 'done': false},
        {'item_id': 'a', 'step_order': 1, 'title': 'First', 'done': true},
        {'item_id': 'c', 'step_order': 2, 'title': 'Second', 'done': false},
      ]);

      expect(checklist.total, 3);
      expect(checklist.items.map((i) => i.stepOrder), [1, 2, 3]);
      expect(checklist.items.first.title, 'First');
    });

    test('skips malformed (non-map) entries', () {
      final checklist = CaseChecklist.fromRpc([
        {'item_id': 'a', 'step_order': 1, 'title': 'Ok', 'done': false},
        'garbage',
        123,
      ]);
      expect(checklist.total, 1);
    });
  });

  group('progress math', () {
    CaseChecklist make(List<bool> dones) => CaseChecklist(
          items: [
            for (var i = 0; i < dones.length; i++)
              ChecklistItem(
                itemId: 'item-$i',
                stepOrder: i + 1,
                title: 'Step ${i + 1}',
                done: dones[i],
              ),
          ],
        );

    test('completed counts done items', () {
      expect(make([true, false, true]).completed, 2);
    });

    test('progress is completed / total', () {
      expect(make([true, false, true, false]).progress, 0.5);
    });

    test('empty checklist has 0 progress and is not allDone', () {
      const empty = CaseChecklist.empty;
      expect(empty.progress, 0);
      expect(empty.allDone, isFalse);
      expect(empty.isEmpty, isTrue);
    });

    test('allDone only when every step is checked', () {
      expect(make([true, true, true]).allDone, isTrue);
      expect(make([true, false, true]).allDone, isFalse);
    });
  });

  group('withToggled', () {
    test('flips the targeted item and leaves others untouched', () {
      final base = CaseChecklist.fromRpc([
        {'item_id': 'a', 'step_order': 1, 'title': 'A', 'done': false},
        {'item_id': 'b', 'step_order': 2, 'title': 'B', 'done': false},
      ]);

      final next = base.withToggled('b', true);

      expect(next.items.firstWhere((i) => i.itemId == 'a').done, isFalse);
      expect(next.items.firstWhere((i) => i.itemId == 'b').done, isTrue);
      expect(next.completed, 1);
      // Original is unchanged (immutability).
      expect(base.completed, 0);
    });

    test('toggling an unknown id is a no-op', () {
      final base = CaseChecklist.fromRpc([
        {'item_id': 'a', 'step_order': 1, 'title': 'A', 'done': false},
      ]);
      final next = base.withToggled('zzz', true);
      expect(next.completed, 0);
      expect(next.total, 1);
    });
  });

  group('ChecklistItem equality', () {
    test('differs when done changes', () {
      const a = ChecklistItem(
          itemId: 'x', stepOrder: 1, title: 'X', done: false);
      final b = a.copyWith(done: true);
      expect(a == b, isFalse);
    });

    test('equal when id/order/done match', () {
      const a = ChecklistItem(
          itemId: 'x', stepOrder: 1, title: 'X', done: false);
      const b = ChecklistItem(
          itemId: 'x', stepOrder: 1, title: 'different title', done: false);
      expect(a == b, isTrue);
    });
  });
}
