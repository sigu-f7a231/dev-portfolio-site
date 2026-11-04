// YAML / Markdown の見分けと、Markdown → YAML として読める形への変換のテスト
// 対象：lib/utils/data_format.dart
//
// 実行：flutter test test/data_format_test.dart（dev_portfolio/ で）
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/utils/data_format.dart';
import 'package:dev_portfolio/utils/projects_yaml_validator.dart';
import 'package:dev_portfolio/utils/profile_bundle.dart';

import 'test_assets.dart';

String _asset(String name) => File('assets/data/$name').readAsStringSync();

/// YAML として読み、比べやすい形（JSON 相当）にする。details は前後の空白・改行を除く
List<Map<String, dynamic>> _projects(String text) {
  final list = jsonDecode(jsonEncode(loadYaml(text)))['projects'] as List;
  return [
    for (final p in list.cast<Map<String, dynamic>>())
      {
        ...p,
        if (p['details'] != null) 'details': (p['details'] as String).trim(),
        'period': [for (final e in (p['period'] as List?) ?? const []) '$e'],
        'link': p['link'] ?? '',
      },
  ];
}

NormalizedData _md(String text, DataKind kind) => normalizeInput(text, kind: kind, fileName: 'x.md');

void main() {
  group('テンプレート：Markdown 版は YAML 版と同じ中身になる', () {
    for (final kind in [DataKind.work, DataKind.private]) {
      test('format_${kind.name}.md', () {
        final n = normalizeInput(
          _asset('format_${kind.name}.md'),
          kind: kind,
          fileName: 'format_${kind.name}.md',
        );
        expect(n.errors, isEmpty);
        expect(n.format, DataFormat.markdown);
        expect(isValidProjectsYaml(n.text!, kind.name), isTrue);
        expect(_projects(n.text!), _projects(_asset('format_${kind.name}.yaml')));
      });
    }

    test('format_profile.md（Work / Private も一緒に書いてある）', () {
      final md = readProfileBundle(_asset('format_profile.md'), fileName: 'format_profile.md');
      final yaml = readProfileBundle(_asset('format_profile.yaml'), fileName: 'format_profile.yaml');
      expect(md.errors, isEmpty);
      expect(yaml.errors, isEmpty);
      // 一緒に書いた Work / Private も、YAML 版・単独のテンプレートと同じ中身
      expect(_projects(md.workText!), _projects(yaml.workText!));
      expect(_projects(md.privateText!), _projects(yaml.privateText!));
      expect(_projects(md.workText!), _projects(_asset('format_work.yaml')));
      expect(_projects(md.privateText!), _projects(_asset('format_private.yaml')));

      final fromMd = md.profile!;
      final fromYaml = yaml.profile!;
      expect(fromMd.name, fromYaml.name);
      expect(fromMd.role, fromYaml.role);
      expect(fromMd.tagline, fromYaml.tagline);
      expect(fromMd.card, fromYaml.card);
      expect(fromMd.intro, fromYaml.intro);
      expect(fromMd.domains, fromYaml.domains);
      expect(fromMd.strengths, fromYaml.strengths);
      expect(fromMd.style, fromYaml.style);
      expect(fromMd.closing, fromYaml.closing);
    });
  });

  group('テンプレートがアセットとして登録されている（pubspec.yaml の書き忘れを見つける）', () {
    // ここは本物の rootBundle で読む（testWidgets ではない普通の test なので、読み込みを待てる）
    setUp(TestWidgetsFlutterBinding.ensureInitialized);

    for (final path in allTemplateAssets) {
      test(path, () async {
        // rootBundle から読めて、ファイルの中身と同じ
        final text = await rootBundle.loadString(path);
        expect(text, File(path).readAsStringSync());
      });
    }
  });

  group('形式の見分け', () {
    test('拡張子があればそれに従う', () {
      expect(detectFormat('x', fileName: 'a.md'), DataFormat.markdown);
      expect(detectFormat('x', fileName: 'a.MARKDOWN'), DataFormat.markdown);
      expect(detectFormat('# x', fileName: 'a.yaml'), DataFormat.yaml);
      expect(detectFormat('# x', fileName: 'a.yml'), DataFormat.yaml);
    });

    test('貼り付け（拡張子なし）は中身で見分ける', () {
      expect(detectFormat(_asset('format_work.yaml')), DataFormat.yaml);
      expect(detectFormat(_asset('format_profile.yaml')), DataFormat.yaml); // 「# ---」のコメント付き
      expect(detectFormat(_asset('format_work.md')), DataFormat.markdown);
      expect(detectFormat(_asset('format_profile.md')), DataFormat.markdown);
    });

    test('書き間違いのある YAML は YAML のまま（YAML のエラーを出すため）', () {
      const broken = '# ---- コメント ----\nprojects:\n  - title: [閉じていない\n';
      expect(detectFormat(broken), DataFormat.yaml);
      final n = normalizeInput(broken, kind: DataKind.work);
      expect(n.format, DataFormat.yaml);
      expect(n.text, broken);
      expect(n.errors, isEmpty);
    });

    test('YAML はそのまま返す（コメントも残る）', () {
      final yaml = _asset('format_profile.yaml');
      final n = normalizeInput(yaml, kind: DataKind.profile);
      expect(n.text, yaml);
    });

    test('使える拡張子', () {
      for (final ok in ['a.yaml', 'a.yml', 'a.md', 'a.markdown', 'A.MD']) {
        expect(hasAcceptedExtension(ok), isTrue, reason: ok);
      }
      for (final ng in ['a.txt', 'a.json', 'md', 'a.md.txt']) {
        expect(hasAcceptedExtension(ng), isFalse, reason: ng);
      }
    });

    test('テンプレートのファイル名', () {
      expect(templateFileName(DataKind.work, DataFormat.yaml), 'format_work.yaml');
      expect(templateFileName(DataKind.private, DataFormat.markdown), 'format_private.md');
      expect(templateAssetPath(DataKind.profile, DataFormat.markdown), 'assets/data/format_profile.md');
      expect(projectKind('work'), DataKind.work);
      expect(projectKind('private'), DataKind.private);
    });
  });

  group('Markdown（Work / Private）', () {
    test('複数のプロジェクト・カンマ区切り（, と 、）・期間の書き方', () {
      const md = '''
# 案件A
- period: 2024-01 ~ 現在
- skills: Dart, Flutter、TypeScript
- workflow: requirements, 基本設計

# 案件B
- period: 2023-01〜2023-03
- workflow: 保守・運用

# 案件C
- period: 2022-01 → 2022-02
- workflow: 要件定義

# 案件D
- period: 2021-01 - 2021-12
- workflow: 要件定義
''';
      final n = _md(md, DataKind.work);
      expect(n.errors, isEmpty);
      final ps = _projects(n.text!);
      expect(ps.map((p) => p['title']), ['案件A', '案件B', '案件C', '案件D']);
      expect(ps[0]['skills'], ['Dart', 'Flutter', 'TypeScript']);
      expect(ps[0]['period'], ['2024-01', '現在']);
      expect(ps[1]['period'], ['2023-01', '2023-03']);
      expect(ps[2]['period'], ['2022-01', '2022-02']);
      expect(ps[3]['period'], ['2021-01', '2021-12']);
      // workflow は 7 工程すべてが入り、書いたものだけ true
      expect(ps[0]['workflow'], {
        'requirements': true,
        'basic_design': true,
        'detailed_design': false,
        'implementation_unit_test': false,
        'integration_test': false,
        'system_test': false,
        'maintenance_operation': false,
      });
      expect(isValidProjectsYaml(n.text!, 'work'), isTrue);
    });

    test('## details は複数行のまま、コメントとコードブロックの囲みは読み飛ばす', () {
      const md = '''
<!-- メモ
# これは見出しではない
-->
```
# 案件A
- description: 説明
## details
1 行目
2 行目
```
''';
      final n = _md(md, DataKind.private);
      expect(n.errors, isEmpty);
      final p = _projects(n.text!).single;
      expect(p['title'], '案件A');
      expect(p['description'], '説明');
      expect(p['details'], '1 行目\n2 行目');
      expect(isValidProjectsYaml(n.text!, 'private'), isTrue);
    });

    test('Private に workflow を書くと Private としては通らない', () {
      final n = _md('# 案件\n- workflow: 要件定義\n', DataKind.private);
      expect(n.errors, isEmpty);
      expect(isValidProjectsYaml(n.text!, 'private'), isFalse);
    });

    test('書き方の誤りは行番号付きで知らせる', () {
      const md = '''
最初の見出しより前の行
# 案件A
- skils: Dart
- workflow: 設計
ただの文章
## memo
メモ
''';
      final n = _md(md, DataKind.work);
      expect(n.text, isNull);
      // 行の形の誤り（見出しの前・「- キー: 値」でない行）→ 項目の中身の誤り、の順に並ぶ
      expect(n.errors, [
        MarkdownTexts.beforeFirstHeading(1, '最初の見出しより前の行'),
        MarkdownTexts.strayLine(5, 'ただの文章'),
        MarkdownTexts.unknownKey(3, 'skils'),
        MarkdownTexts.unknownWorkflow(4, '設計'),
        MarkdownTexts.unknownSection(6, 'memo'),
      ]);
    });

    test('コメント・コードブロックの囲みがあっても、行番号は元のファイルのまま', () {
      const md = '''
<!--
  メモ 1
  メモ 2
-->
```
# 案件A
- skils: Dart
```
<!-- 1 行のコメント --># 案件B
- tools: Git
- colour: 赤
''';
      final n = _md(md, DataKind.work);
      expect(n.errors, [
        MarkdownTexts.unknownKey(7, 'skils'), // 1〜4 行目がコメント、5 行目が ```
        MarkdownTexts.unknownKey(11, 'colour'),
      ]);
    });

    test('テンプレート（先頭にコメントあり）に書き間違いを入れると、その行の番号を出す', () {
      final lines = _asset('format_work.md').split('\n');
      final at = lines.indexWhere((l) => l.startsWith('- skills:'));
      lines[at] = '- skils: Python'; // at は 0 始まりなので、行番号は at + 1
      final n = _md(lines.join('\n'), DataKind.work);
      expect(n.errors, [MarkdownTexts.unknownKey(at + 1, 'skils')]);
    });

    test('見出しが 1 つもない', () {
      final n = _md('- skills: Dart\n', DataKind.work);
      expect(n.errors.last, MarkdownTexts.noProjects);
      expect(n.text, isNull);
    });
  });

  group('Markdown（プロフィール）', () {
    test('見出しの大文字・小文字は問わず、card のカンマ区切りは箇条書きになる', () {
      const md = '''
# Home
- name: 山田
- role: エンジニア
## tagline
紹介文
## card
- stack: Flutter, Dart
- role: Web / Mobile

# ABOUT
- domains: Web, モバイル
## intro
自己紹介
''';
      final n = _md(md, DataKind.profile);
      expect(n.errors, isEmpty);
      final p = Profile.parse(n.text!).profile!;
      expect(p.name, '山田');
      expect(p.card, {
        'stack': ['Flutter', 'Dart'],
        'role': 'Web / Mobile',
      });
      expect(p.domains, ['Web', 'モバイル']);
      expect(p.intro, '自己紹介');
    });

    test('必須項目がなければ Profile.parse が理由を出す', () {
      final n = _md('# home\n- name: 山田\n# about\n', DataKind.profile);
      expect(n.errors, isEmpty);
      final r = Profile.parse(n.text!);
      expect(r.isOk, isFalse);
      expect(
        r.errors,
        containsAll([
          ProfileTexts.errorRequired('home.role'),
          ProfileTexts.errorRequired('home.tagline'),
          ProfileTexts.errorRequired('about.intro'),
        ]),
      );
    });

    test('home / about 以外の見出しは「使えない項目」になる', () {
      final n = _md('# home\n- name: a\n- role: b\n- tagline: c\n# about\n- intro: d\n# hobby\n- x: y\n',
          DataKind.profile);
      final r = Profile.parse(n.text!);
      expect(r.errors, [ProfileTexts.errorUnknownKey('hobby')]);
    });

    test('## card の下が「- キー: 値」でなければ知らせる', () {
      final n = _md('# home\n## card\nただの文章\n', DataKind.profile);
      expect(n.errors, [MarkdownTexts.cardNeedsFields(2, 'card')]);
    });

    test('見出しが 1 つもない', () {
      final n = _md('- name: 山田\n', DataKind.profile);
      expect(n.errors.last, MarkdownTexts.noProfileSections);
    });
  });
}
