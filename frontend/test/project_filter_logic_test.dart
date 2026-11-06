// Projects のフィルター（条件で絞り込む）のテスト
// 対象：lib/sections/projects/filters/logic/project_filter_logic.dart
// 役割・規模の絞り込みは project_role_scale_test.dart にある。ここではそれ以外の分類・期間・進行中・組み合わせを見る
//
// 実行：flutter test test/project_filter_logic_test.dart（frontend/ で）
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/sections/projects/filters/logic/project_filter_logic.dart';
import 'package:dev_portfolio/sections/projects/filters/state/project_filter_state.dart';
import 'package:dev_portfolio/sections/projects/models/projects_model.dart';

Project _p(String title, [Map<String, dynamic> fields = const {}]) =>
    Project.fromMap({'title': title, ...fields});

/// はじめの状態（全分類が空）に [selected] を重ねた条件
ProjectFilterState _filter(
  Map<String, List<String>> selected, {
  int? from,
  int? to,
  bool ongoing = false,
}) =>
    ProjectFilterState(
      selectedFilters: ProjectFilterState.initial().copyFilters()..addAll(selected),
      fromYear: from,
      toYear: to,
      ongoingOnly: ongoing,
    );

List<String> _apply(List<Project> projects, ProjectFilterState state) =>
    [for (final p in ProjectFilterLogic.apply(projects, state)) p.title];

void main() {
  group('条件がないとき', () {
    test('全件をそのままの順で返す', () {
      final projects = [_p('B'), _p('A'), _p('C')];
      expect(_apply(projects, ProjectFilterState.initial()), ['B', 'A', 'C']);
    });

    test('0 件なら 0 件', () {
      expect(_apply([], _filter({'skills': ['Dart']})), isEmpty);
    });

    test('知らない分類のキーは無視する', () {
      expect(_apply([_p('A')], _filter({'unknown': ['x']})), ['A']);
    });
  });

  group('分類ごとに、その項目だけを見る', () {
    // （フィルターのキー, YAML のキー, 値）。値はどれも本来の分類の名前（Skills・Tools からの振り分けが起きない）
    const cases = [
      ('serverOS', 'server_os', 'Linux'),
      ('db', 'db', 'MySQL'),
      ('tools', 'tools', 'Git'),
      ('backendFrameworks', 'backend_frameworks', 'Django'),
      ('frontendFrameworks', 'frontend_frameworks', 'React'),
      ('uiFrameworks', 'ui_frameworks', 'Bootstrap'),
      ('testingFrameworks', 'testing_frameworks', 'Jest'),
      ('cloudPlatforms', 'cloud_platforms', 'AWS'),
      ('awsServices', 'aws_services', 'Lambda'),
      ('azureServices', 'azure_services', 'Functions'),
      ('gcpServices', 'gcp_services', 'Cloud Run'),
      ('container', 'container', 'Docker'),
      ('containerOrchestration', 'container_orchestration', 'Kubernetes'),
      ('aiServices', 'ai_services', 'Claude'),
      ('skills', 'skills', 'Dart'),
      ('role', 'role', 'PM'),
    ];

    for (final (filterKey, yamlKey, value) in cases) {
      test('$filterKey：$yamlKey に「$value」がある案件だけ', () {
        final projects = [
          _p('ある', {yamlKey: [value]}),
          _p('ない', {yamlKey: ['Zzz']}),
          _p('項目なし'),
        ];
        expect(_apply(projects, _filter({filterKey: [value]})), ['ある']);
      });
    }

    test('ほかの分類に同じ名前があっても残さない（Docker を Skills で探しても、Container の Docker は対象外）', () {
      final projects = [_p('container', {'container': ['Docker']})];
      expect(_apply(projects, _filter({'skills': ['Docker']})), isEmpty);
      expect(_apply(projects, _filter({'container': ['Docker']})), ['container']);
    });
  });

  group('複数の条件（AND）', () {
    final projects = [
      _p('Dart と Python', {'skills': ['Dart', 'Python'], 'db': ['MySQL']}),
      _p('Dart だけ', {'skills': ['Dart'], 'db': ['PostgreSQL']}),
      _p('Python だけ', {'skills': ['Python'], 'db': ['MySQL']}),
    ];

    test('同じ分類で 2 つ選ぶと、両方ある案件だけ', () {
      expect(_apply(projects, _filter({'skills': ['Dart', 'Python']})), ['Dart と Python']);
    });

    test('分類をまたいでも、すべて満たす案件だけ', () {
      expect(_apply(projects, _filter({'skills': ['Python'], 'db': ['MySQL']})), ['Dart と Python', 'Python だけ']);
      expect(_apply(projects, _filter({'skills': ['Dart'], 'db': ['MySQL']})), ['Dart と Python']);
    });

    test('どれにも当てはまらなければ 0 件', () {
      expect(_apply(projects, _filter({'skills': ['Dart'], 'db': ['Oracle']})), isEmpty);
    });
  });

  group('名前の比べ方', () {
    test('部分一致（Java を選ぶと JavaScript の案件も残る）', () {
      final projects = [
        _p('Java', {'skills': ['Java']}),
        _p('JavaScript', {'skills': ['JavaScript']}),
        _p('Go', {'skills': ['Go']}),
      ];
      expect(_apply(projects, _filter({'skills': ['Java']})), ['Java', 'JavaScript']);
      expect(_apply(projects, _filter({'skills': ['JavaScript']})), ['JavaScript']);
    });

    // （選んだ名前, 案件に書かれた名前）
    const variants = [
      ('mysql', 'MySQL'), // 大文字・小文字
      ('MYSQL', 'MySQL'),
      ('ＭｙＳＱＬ', 'MySQL'), // 全角
      ('MySQL', 'ＭｙＳＱＬ'),
      ('MySQL;', 'MySQL'), // 末尾の記号
      ('My SQL', 'MySQL'), // 空白
    ];
    for (final (selected, written) in variants) {
      test('表記ゆれを無視する：「$selected」で「$written」が残る', () {
        expect(_apply([_p('hit', {'db': [written]})], _filter({'db': [selected]})), ['hit']);
      });
    }

    test('区切り（_・-・空白）の違いを無視する：github_actions で GitHub Actions', () {
      expect(
        _apply([_p('hit', {'tools': ['GitHub Actions']})], _filter({'tools': ['github_actions']})),
        ['hit'],
      );
    });

    test('クラウドのサービスは先頭の AWS / Amazon / Azure / GCP を無視する', () {
      expect(_apply([_p('hit', {'aws_services': ['Lambda']})], _filter({'awsServices': ['AWS Lambda']})), ['hit']);
      expect(_apply([_p('hit', {'aws_services': ['Amazon S3']})], _filter({'awsServices': ['S3']})), ['hit']);
      expect(_apply([_p('hit', {'azure_services': ['Azure Functions']})], _filter({'azureServices': ['Functions']})), ['hit']);
      expect(_apply([_p('hit', {'gcp_services': ['Cloud Run']})], _filter({'gcpServices': ['GCP Cloud Run']})), ['hit']);
    });

    test('値が文字（カンマ区切り）でも並びでも同じ', () {
      final projects = [
        _p('並び', {'skills': ['Dart', 'Python']}),
        _p('文字', {'skills': 'Dart, Python'}),
      ];
      expect(_apply(projects, _filter({'skills': ['Python']})), ['並び', '文字']);
    });
  });

  group('工程（workflow）', () {
    final projects = [
      _p('要件と基本', {'workflow': {'requirements': true, 'basic_design': true, 'system_test': false}}),
      _p('要件だけ', {'workflow': {'requirements': true, 'basic_design': false}}),
      _p('工程なし'),
    ];

    test('日本語の名前で選べる。false の工程は担当していない扱い', () {
      expect(_apply(projects, _filter({'workflow': ['要件定義']})), ['要件と基本', '要件だけ']);
      expect(_apply(projects, _filter({'workflow': ['基本設計']})), ['要件と基本']);
      expect(_apply(projects, _filter({'workflow': ['総合テスト']})), isEmpty);
    });

    test('英語のキーでも選べる', () {
      expect(_apply(projects, _filter({'workflow': ['basic_design']})), ['要件と基本']);
    });

    test('2 つ選ぶと両方担当した案件だけ', () {
      expect(_apply(projects, _filter({'workflow': ['要件定義', '基本設計']})), ['要件と基本']);
    });

    test('日本語の名前は 7 工程すべて英語のキーに対応している', () {
      expect(WorkflowKeyMapper.jaToKey, hasLength(7));
      final all = {for (final key in WorkflowKeyMapper.jaToKey.values) key: true};
      final full = [_p('全部', {'workflow': all})];
      for (final ja in WorkflowKeyMapper.jaToKey.keys) {
        expect(_apply(full, _filter({'workflow': [ja]})), ['全部'], reason: ja);
      }
    });
  });

  group('期間（年）：範囲に少しでも重なれば残す', () {
    final projects = [
      _p('2020 年', {'period': ['2020-01', '2020-12']}),
      _p('2021 前半', {'period': ['2021-01', '2021-06']}),
      _p('2019〜2021 をまたぐ', {'period': ['2019-06', '2021-03']}),
      _p('2020 年 12 月に始まる', {'period': ['2020-12', '2021-02']}),
      _p('2020 年 1 月に終わる', {'period': ['2019-01', '2020-01']}),
      _p('2018 年', {'period': ['2018-01', '2018-12']}),
    ];

    test('1 年だけ（2021〜2021）', () {
      expect(_apply(projects, _filter({}, from: 2021, to: 2021)), ['2021 前半', '2019〜2021 をまたぐ', '2020 年 12 月に始まる']);
    });

    test('境目：範囲の最後の月に始まる案件・最初の月に終わる案件も残す（2020〜2020）', () {
      expect(
        _apply(projects, _filter({}, from: 2020, to: 2020)),
        ['2020 年', '2019〜2021 をまたぐ', '2020 年 12 月に始まる', '2020 年 1 月に終わる'],
      );
    });

    test('複数年（2018〜2019）', () {
      expect(_apply(projects, _filter({}, from: 2018, to: 2019)), ['2019〜2021 をまたぐ', '2020 年 1 月に終わる', '2018 年']);
    });

    test('どれにも重ならない年なら 0 件', () {
      expect(_apply(projects, _filter({}, from: 2010, to: 2012)), isEmpty);
    });

    test('始まりか終わりの片方だけでは絞り込まない', () {
      expect(_apply(projects, _filter({}, from: 2010)), hasLength(projects.length));
      expect(_apply(projects, _filter({}, to: 2010)), hasLength(projects.length));
    });

    test('進行中の案件は今年まで続いているとみなす', () {
      final now = DateTime.now().year;
      final ongoing = [_p('進行中', {'period': ['2022-04', '現在']})];
      expect(_apply(ongoing, _filter({}, from: now, to: now)), ['進行中']);
      expect(_apply(ongoing, _filter({}, from: now + 1, to: now + 2)), isEmpty);
    });
  });

  group('進行中のみ', () {
    final projects = [
      _p('現在', {'period': ['2022-04', '現在']}),
      _p('present', {'period': '2023-01 ~ present'}),
      _p('Present', {'period': '2023-01 ~ Present'}),
      _p('終了', {'period': ['2020-01', '2020-12']}),
      _p('期間なし'),
    ];

    test('終わりが「現在」/ present（大文字・小文字は問わない）の案件だけ', () {
      expect(_apply(projects, _filter({}, ongoing: true)), ['現在', 'present', 'Present']);
    });

    test('ほかの条件と組み合わせられる', () {
      final mixed = [
        _p('進行中・Dart', {'period': ['2022-04', '現在'], 'skills': ['Dart']}),
        _p('進行中・Go', {'period': ['2022-04', '現在'], 'skills': ['Go']}),
        _p('終了・Dart', {'period': ['2020-01', '2020-12'], 'skills': ['Dart']}),
      ];
      expect(_apply(mixed, _filter({'skills': ['Dart']}, ongoing: true)), ['進行中・Dart']);
    });
  });

  test('元のリストは変えない', () {
    final projects = [_p('A', {'skills': ['Dart']}), _p('B')];
    final result = ProjectFilterLogic.apply(projects, _filter({'skills': ['Dart']}));
    expect(result, hasLength(1));
    expect(projects, hasLength(2));
  });
}
