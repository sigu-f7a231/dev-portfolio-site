// Projects の並び替えのテスト
// 対象：lib/sections/projects/sort/project_sort.dart
//
// 実行：flutter test test/project_sort_test.dart（dev_portfolio/ で）
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/sections/projects/models/projects_model.dart';
import 'package:dev_portfolio/sections/projects/sort/project_sort.dart';

Project _p(String title, Object? period) =>
    Project.fromMap({'title': title, if (period != null) 'period': period});

final _projects = [
  _p('B 短い', ['2023-01', '2023-02']), // 2 か月
  _p('A 長い', ['2020-04', '2022-03']), // 24 か月
  _p('期間なし', null),
  _p('C 進行中', ['2024-06', '現在']),
  _p('D 新しい', ['2024-01', '2024-06']), // 6 か月
];

List<String> _titles(ProjectSort sort) => [for (final p in sort.apply(_projects)) p.title];

void main() {
  test('開始が古い順（これまでの並び）。期間がないものは最後', () {
    expect(_titles(ProjectSort.startOldest), ['A 長い', 'B 短い', 'D 新しい', 'C 進行中', '期間なし']);
  });

  test('開始が新しい順', () {
    expect(_titles(ProjectSort.startNewest), ['C 進行中', 'D 新しい', 'B 短い', 'A 長い', '期間なし']);
  });

  test('終了が新しい順（進行中がいちばん上）', () {
    expect(_titles(ProjectSort.endNewest), ['C 進行中', 'D 新しい', 'B 短い', 'A 長い', '期間なし']);
  });

  test('期間が長い順・短い順', () {
    // 進行中は今日までの長さなので、日付に左右されない A・D・B の順だけを見る
    final longest = _titles(ProjectSort.durationLongest);
    expect(longest.indexOf('A 長い'), lessThan(longest.indexOf('D 新しい')));
    expect(longest.indexOf('D 新しい'), lessThan(longest.indexOf('B 短い')));
    expect(longest.last, '期間なし');
    expect(_titles(ProjectSort.durationShortest).first, 'B 短い');
    expect(_titles(ProjectSort.durationShortest).last, '期間なし');
  });

  test('名前順（期間がなくても名前で並べる）', () {
    expect(_titles(ProjectSort.title), ['A 長い', 'B 短い', 'C 進行中', 'D 新しい', '期間なし']);
  });

  test('元のリストは変えない', () {
    final before = [for (final p in _projects) p.title];
    ProjectSort.startNewest.apply(_projects);
    expect([for (final p in _projects) p.title], before);
  });
}
