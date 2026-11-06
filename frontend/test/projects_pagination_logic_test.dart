// Projects のページ分けのテスト
// 対象：lib/sections/projects/pagination/projects_pagination_logic.dart
//
// 実行：flutter test test/projects_pagination_logic_test.dart（frontend/ で）
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/sections/config/projects/projects_pagination_config.dart';
import 'package:dev_portfolio/sections/projects/models/projects_model.dart';
import 'package:dev_portfolio/sections/projects/pagination/projects_pagination_logic.dart';

List<Project> _projects(int n) => [for (var i = 1; i <= n; i++) Project.fromMap({'title': 'P$i'})];

List<String> _titles(List<Project> ps) => [for (final p in ps) p.title];

void main() {
  const per = ProjectsPaginationConfig.itemsPerPage;

  group('getTotalPages（総ページ数）', () {
    test('0 件でも 1 ページ', () {
      expect(ProjectsPaginationLogic.getTotalPages([]), 1);
      expect(ProjectsPaginationLogic.getTotalPages([], perPage: 3), 1);
    });

    // （件数, 1 ページの件数, ページ数）
    const cases = [
      (1, 3, 1),
      (2, 3, 1),
      (3, 3, 1), // ちょうど埋まる
      (4, 3, 2), // 1 件はみ出す
      (6, 3, 2),
      (7, 3, 3),
      (10, 1, 10), // 1 件ずつ
      (5, 100, 1), // 1 ページが件数より大きい
    ];
    for (final (n, size, pages) in cases) {
      test('$n 件・1 ページ $size 件 → $pages ページ', () {
        expect(ProjectsPaginationLogic.getTotalPages(_projects(n), perPage: size), pages);
      });
    }

    test('perPage を省略すると設定の件数（$per 件）で分ける', () {
      expect(ProjectsPaginationLogic.getTotalPages(_projects(per)), 1);
      expect(ProjectsPaginationLogic.getTotalPages(_projects(per + 1)), 2);
      expect(ProjectsPaginationLogic.getTotalPages(_projects(per * 2 + 1)), 3);
    });
  });

  group('getPaginatedProjects（ページの中身）', () {
    final seven = _projects(7);

    test('1 ページ目・途中・最後（端数）', () {
      expect(_titles(ProjectsPaginationLogic.getPaginatedProjects(seven, 1, perPage: 3)), ['P1', 'P2', 'P3']);
      expect(_titles(ProjectsPaginationLogic.getPaginatedProjects(seven, 2, perPage: 3)), ['P4', 'P5', 'P6']);
      expect(_titles(ProjectsPaginationLogic.getPaginatedProjects(seven, 3, perPage: 3)), ['P7']);
    });

    test('最後のページがちょうど埋まるとき', () {
      final six = _projects(6);
      expect(_titles(ProjectsPaginationLogic.getPaginatedProjects(six, 2, perPage: 3)), ['P4', 'P5', 'P6']);
      expect(ProjectsPaginationLogic.getPaginatedProjects(six, 3, perPage: 3), isEmpty);
    });

    test('ページ数より先のページは空', () {
      expect(ProjectsPaginationLogic.getPaginatedProjects(seven, 4, perPage: 3), isEmpty);
      expect(ProjectsPaginationLogic.getPaginatedProjects(seven, 100, perPage: 3), isEmpty);
    });

    test('0 件なら 1 ページ目も空', () {
      expect(ProjectsPaginationLogic.getPaginatedProjects([], 1, perPage: 3), isEmpty);
    });

    test('perPage を省略すると設定の件数（$per 件）', () {
      final many = _projects(per * 2);
      expect(ProjectsPaginationLogic.getPaginatedProjects(many, 1), hasLength(per));
      expect(_titles(ProjectsPaginationLogic.getPaginatedProjects(many, 2)).first, 'P${per + 1}');
    });

    test('全ページをつなぐと元の並びと同じ（抜け・重なりがない）', () {
      for (final size in [1, 2, 3, 4, 7, 8]) {
        final pages = ProjectsPaginationLogic.getTotalPages(seven, perPage: size);
        final joined = [
          for (var page = 1; page <= pages; page++)
            ...ProjectsPaginationLogic.getPaginatedProjects(seven, page, perPage: size),
        ];
        expect(_titles(joined), _titles(seven), reason: '1 ページ $size 件');
      }
    });

    test('返したリストを変えても元のリストは変わらない', () {
      final page = ProjectsPaginationLogic.getPaginatedProjects(seven, 1, perPage: 3);
      page.clear();
      expect(seven, hasLength(7));
    });
  });
}
