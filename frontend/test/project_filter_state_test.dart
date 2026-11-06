// Projects のフィルターの状態のテスト
// 対象：lib/sections/projects/filters/state/project_filter_state.dart
//
// 実行：flutter test test/project_filter_state_test.dart（frontend/ で）
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/sections/projects/filters/state/project_filter_state.dart';

ProjectFilterState _state({
  Map<String, List<String>>? filters,
  int? from,
  int? to,
  bool ongoing = false,
}) =>
    ProjectFilterState(
      selectedFilters: filters ?? ProjectFilterState.initial().copyFilters(),
      fromYear: from,
      toYear: to,
      ongoingOnly: ongoing,
    );

void main() {
  group('はじめの状態', () {
    final s = ProjectFilterState.initial();

    test('全分類が空で、条件の数は 0', () {
      expect(s.selectedFilters.values.every((v) => v.isEmpty), isTrue);
      expect(s.activeCount, 0);
      expect(s.hasPeriod, isFalse);
      expect(s.ongoingOnly, isFalse);
    });

    test('フィルターで使う分類がすべてある', () {
      expect(
        s.selectedFilters.keys,
        unorderedEquals([
          'role', 'scale', 'serverOS', 'db', 'tools', 'backendFrameworks', 'frontendFrameworks',
          'uiFrameworks', 'testingFrameworks', 'cloudPlatforms', 'awsServices', 'azureServices',
          'gcpServices', 'container', 'containerOrchestration', 'aiServices', 'skills', 'workflow',
        ]),
      );
    });

    test('呼ぶたびに別の Map（前の状態を書き換えても次に影響しない）', () {
      final a = ProjectFilterState.initial();
      a.selectedFilters['skills']!.add('Dart');
      expect(ProjectFilterState.initial().selectedFilters['skills'], isEmpty);
    });
  });

  group('hasPeriod：始まりと終わりの両方があるときだけ', () {
    // （始まり, 終わり, 期待）
    const cases = [
      (null, null, false),
      (2020, null, false),
      (null, 2020, false),
      (2020, 2020, true),
      (2018, 2024, true),
    ];
    for (final (from, to, expected) in cases) {
      test('from=$from, to=$to → $expected', () {
        expect(_state(from: from, to: to).hasPeriod, expected);
      });
    }
  });

  group('activeCount：選んだ値の数＋期間（1）＋進行中のみ（1）', () {
    final filters = ProjectFilterState.initial().copyFilters()
      ..['skills'] = ['Dart', 'Python']
      ..['db'] = ['MySQL'];

    test('値だけ', () => expect(_state(filters: filters).activeCount, 3));
    test('＋期間', () => expect(_state(filters: filters, from: 2020, to: 2021).activeCount, 4));
    test('＋進行中のみ', () => expect(_state(filters: filters, ongoing: true).activeCount, 4));
    test('全部', () => expect(_state(filters: filters, from: 2020, to: 2021, ongoing: true).activeCount, 5));
    test('期間が片方だけなら数えない', () => expect(_state(filters: filters, from: 2020).activeCount, 3));
    test('期間と進行中のみだけ', () => expect(_state(from: 2020, to: 2021, ongoing: true).activeCount, 2));
  });

  test('copyFilters は中身まで複製する', () {
    final s = _state(filters: {'skills': ['Dart']});
    final copy = s.copyFilters();
    copy['skills']!.add('Python');
    copy['db'] = ['MySQL'];
    expect(s.selectedFilters, {'skills': ['Dart']});
  });

  group('without（条件を 1 つ外す）', () {
    final s = _state(filters: {'skills': ['Dart', 'Python'], 'db': ['MySQL']}, from: 2020, to: 2021, ongoing: true);

    test('その値だけ外し、ほかの値・分類・期間・進行中のみは残す', () {
      final next = s.without('skills', 'Dart');
      expect(next.selectedFilters, {'skills': ['Python'], 'db': ['MySQL']});
      expect((next.fromYear, next.toYear, next.ongoingOnly), (2020, 2021, true));
      expect(next.activeCount, s.activeCount - 1);
    });

    test('元の状態は変えない', () {
      s.without('skills', 'Dart');
      expect(s.selectedFilters['skills'], ['Dart', 'Python']);
    });

    test('選んでいない値・知らない分類を外しても変わらない（エラーにならない）', () {
      expect(s.without('skills', 'Go').selectedFilters, s.selectedFilters);
      expect(s.without('unknown', 'x').selectedFilters, s.selectedFilters);
    });
  });

  test('withoutPeriod：期間だけ外す', () {
    final s = _state(filters: {'skills': ['Dart']}, from: 2020, to: 2021, ongoing: true);
    final next = s.withoutPeriod();
    expect(next.hasPeriod, isFalse);
    expect((next.fromYear, next.toYear), (null, null));
    expect(next.ongoingOnly, isTrue);
    expect(next.selectedFilters, {'skills': ['Dart']});
    expect(s.hasPeriod, isTrue);
  });

  test('withoutOngoing：進行中のみだけ外す', () {
    final s = _state(filters: {'skills': ['Dart']}, from: 2020, to: 2021, ongoing: true);
    final next = s.withoutOngoing();
    expect(next.ongoingOnly, isFalse);
    expect((next.fromYear, next.toYear), (2020, 2021));
    expect(next.selectedFilters, {'skills': ['Dart']});
    expect(s.ongoingOnly, isTrue);
  });
}
