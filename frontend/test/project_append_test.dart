// プロジェクトの追加（読み取り・今の一覧に足す・候補）の正常系・異常系のテスト
// 対象：lib/utils/project_append.dart
// 画面からの流れは project_data_test.dart にある。ここでは関数ごとに、境界と壊れた入力を見る
//
// 実行：flutter test test/project_append_test.dart（frontend/ で）
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/utils/project_append.dart';

const _workItem = '''
  - title: A
    workflow:
      requirements: true
''';

void main() {
  group('readProjectsInput：正常系', () {
    test('projects: の下（Work）', () {
      final r = readProjectsInput('projects:\n$_workItem', dataType: 'work');
      expect(r.isOk, isTrue);
      expect(r.errors, isEmpty);
      expect(r.projects.single['title'], 'A');
      expect(r.projects.single['workflow'], {'requirements': true});
    });

    test('トップに並べる・1 件だけ（Private）', () {
      expect(readProjectsInput('- title: A\n- title: B\n', dataType: 'private').projects, hasLength(2));
      expect(readProjectsInput('title: A\n', dataType: 'private').projects.single, {'title': 'A'});
    });

    test('読み取った値は普通の Map（YamlMap ではない）。数・真偽・入れ子もそのまま', () {
      final r = readProjectsInput('title: A\nyear: 2024\nflag: true\nskills: [Dart]\n', dataType: 'private');
      final p = r.projects.single;
      expect(p, isNot(isA<YamlMap>()));
      expect(p, {'title': 'A', 'year': 2024, 'flag': true, 'skills': ['Dart']});
    });
  });

  group('readProjectsInput：異常系', () {
    test('YAML の書き方の誤り', () {
      final r = readProjectsInput('projects: [\n', dataType: 'work');
      expect(r.isOk, isFalse);
      expect(r.projects, isEmpty);
      expect(r.errors.single, startsWith('YAML の書き方に誤りがあります'));
    });

    // （入力, 説明）：どれも「プロジェクトが見つかりません」
    const notFound = [
      ('', '空'),
      ('   \n  ', '空白だけ'),
      ('hello', '文字だけ'),
      ('42', '数だけ'),
      ('projects: []', 'projects が空'),
      ('projects: hello', 'projects が並びでない'),
      ('name: x\nrole: y', 'title も projects もない'),
      ('[]', '空の並び'),
    ];
    for (final (input, why) in notFound) {
      test('$why → 見つからない', () {
        final r = readProjectsInput(input, dataType: 'private');
        expect(r.isOk, isFalse);
        expect(r.projects, isEmpty);
        expect(r.errors, [DataTexts.noProjectsFound]);
      });
    }

    test('項目の形でないもの（文字・数・並び）は何件目かを付けて知らせる', () {
      final r = readProjectsInput('- just text\n- 3\n- [a, b]\n- title: OK\n', dataType: 'private');
      expect(r.errors, [DataTexts.itemNotMap(1), DataTexts.itemNotMap(2), DataTexts.itemNotMap(3)]);
      expect(r.projects, isEmpty, reason: '1 件でも誤りがあれば何も追加しない');
    });

    test('title が空・空白だけ・ない', () {
      final r = readProjectsInput("- title: ''\n- title: '   '\n- skills: [Dart]\n", dataType: 'private');
      expect(r.errors, [DataTexts.itemNoTitle(1), DataTexts.itemNoTitle(2), DataTexts.itemNoTitle(3)]);
    });

    test('Work で workflow がない・Private で workflow がある', () {
      expect(readProjectsInput('- title: A\n', dataType: 'work').errors, [DataTexts.itemNoWorkflow(1)]);
      expect(
        readProjectsInput('- title: A\n  workflow: {requirements: true}\n', dataType: 'private').errors,
        [DataTexts.itemHasWorkflow(1)],
      );
    });

    test('1 件に複数の誤りがあれば全部、件ごとの順に並べる', () {
      final r = readProjectsInput(
        '- skills: [Dart]\n- title: B\n  workflow: {requirements: true}\n- title: C\n',
        dataType: 'work',
      );
      expect(r.errors, [DataTexts.itemNoTitle(1), DataTexts.itemNoWorkflow(1), DataTexts.itemNoWorkflow(3)]);
    });

    test('Markdown で読み取れなければ、エラーを返す（追加しない）', () {
      final r = readProjectsInput('# 見出しだけ\n本文\n', dataType: 'private', fileName: 'x.md');
      expect(r.isOk, isFalse);
      expect(r.projects, isEmpty);
      expect(r.errors, isNotEmpty);
    });
  });

  group('ProjectsInput.isOk', () {
    test('エラーがなく、1 件以上あるときだけ true', () {
      expect(const ProjectsInput([], []).isOk, isFalse);
      expect(const ProjectsInput([{'title': 'A'}], ['e']).isOk, isFalse);
      expect(const ProjectsInput([], ['e']).isOk, isFalse);
      expect(const ProjectsInput([{'title': 'A'}], []).isOk, isTrue);
    });
  });

  group('projectsOf：今の YAML のプロジェクト', () {
    test('正常系：projects の Map だけを普通の Map で返す（項目でないものは飛ばす）', () {
      final r = projectsOf('projects:\n  - title: A\n  - text\n  - title: B\n');
      expect(r, [
        {'title': 'A'},
        {'title': 'B'},
      ]);
    });

    // 読めない・形が違う → 空（今の一覧がないものとして扱う）
    const broken = [
      ('', '空'),
      ('projects: [', 'YAML の誤り'),
      ('- title: A', 'トップが並び'),
      ('projects: x', 'projects が並びでない'),
      ('title: A', 'projects がない'),
    ];
    for (final (input, why) in broken) {
      test('異常系：$why → 空', () => expect(projectsOf(input), isEmpty));
    }
  });

  group('appendProjects：今の一覧の後ろに足す', () {
    List<String> titles(String json) => [for (final p in (loadYaml(json) as YamlMap)['projects']) '${p['title']}'];

    test('正常系：今の一覧の後ろに足し、JSON（＝YAML として読める）で返す', () {
      final r = appendProjects('projects:\n  - title: A\n', [
        {'title': 'B'},
      ], dataType: 'private');
      expect(r, isNotNull);
      expect(jsonDecode(r!), isA<Map>());
      expect(titles(r), ['A', 'B']);
    });

    test('keepCurrent: false なら今の一覧は使わない', () {
      final r = appendProjects('projects:\n  - title: A\n', [
        {'title': 'B'},
      ], dataType: 'private', keepCurrent: false);
      expect(titles(r!), ['B']);
    });

    test('今の YAML が壊れていても、足すものだけで作る', () {
      final r = appendProjects('projects: [', [
        {'title': 'B'},
      ], dataType: 'private');
      expect(titles(r!), ['B']);
    });

    test('異常系：足したあとに Work / Private として正しくなければ null', () {
      expect(appendProjects('', [{'title': 'B'}], dataType: 'work'), isNull); // workflow がない
      expect(
        appendProjects('', [
          {'title': 'B', 'workflow': {'requirements': true}},
        ], dataType: 'private'),
        isNull,
      );
      expect(appendProjects('', [], dataType: 'private'), isNull); // 0 件
      expect(appendProjects('', [{'name': 'title なし'}], dataType: 'private'), isNull);
    });
  });

  group('duplicateTitles：今の一覧と同じ名前', () {
    test('前後の空白は無視して比べ、足す順に返す', () {
      final r = duplicateTitles("projects:\n  - title: ' A '\n  - title: C\n", [
        {'title': 'C'},
        {'title': 'B'},
        {'title': 'A'},
      ]);
      expect(r, ['C', 'A']);
    });

    test('同じ名前がない・今の YAML が壊れている → 空', () {
      expect(duplicateTitles('projects:\n  - title: A\n', [{'title': 'B'}]), isEmpty);
      expect(duplicateTitles('projects: [', [{'title': 'A'}]), isEmpty);
    });
  });

  group('tagSuggestions：入力フォームの候補', () {
    test('何もなければ、全項目が空の候補', () {
      final r = tagSuggestions([]);
      for (final key in [...projectListKeys, 'role']) {
        expect(r[key], isEmpty, reason: key);
      }
    });

    test('表記ゆれ・「利用なし」・空はまとめて除く。文字（カンマ区切り）でも読む', () {
      final r = tagSuggestions([
        "projects:\n  - db: [MySQL, 利用なし, mysql, '']\n    role: 'PM, PL'\n",
        'projects:\n  - db: Redis, MYSQL\n',
      ]);
      expect(r['db'], ['MySQL', 'Redis']);
      expect(r['role'], ['PM', 'PL']);
    });

    test('壊れた YAML は飛ばして、読めるものだけで作る', () {
      final r = tagSuggestions(['projects: [', 'projects:\n  - db: [MySQL]\n']);
      expect(r['db'], ['MySQL']);
    });
  });
}
