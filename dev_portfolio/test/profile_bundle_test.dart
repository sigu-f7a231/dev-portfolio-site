// プロフィールのファイルに Work / Private も一緒に書いたときのテスト
// 対象：lib/utils/profile_bundle.dart（readProfileBundle）・lib/utils/data_format.dart（normalizeProfileBundle）
//
// 実行：flutter test test/profile_bundle_test.dart（dev_portfolio/ で）
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/utils/data_format.dart';
import 'package:dev_portfolio/utils/profile_bundle.dart';
import 'package:dev_portfolio/utils/projects_yaml_validator.dart';

String _asset(String name) => File('assets/data/$name').readAsStringSync();

const _profileYaml = '''
home:
  name: 山田 太郎
  role: エンジニア
  tagline: 紹介文
about:
  intro: 自己紹介
''';

const _profileMd = '''
# home
- name: 山田 太郎
- role: エンジニア
## tagline
紹介文

# about
## intro
自己紹介
''';

/// YAML として読み、プロジェクトのタイトルの一覧を返す
List<String> _titles(String text) => [
      for (final p in (loadYaml(text) as YamlMap)['projects'] as YamlList) '${p['title']}',
    ];

/// 比べやすい形（JSON 相当、details は前後の空白を除く、period は文字列）
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

void main() {
  group('プロフィールだけ（これまでどおり）', () {
    test('YAML：Work / Private はなし、プロフィールのテキストはそのまま', () {
      final b = readProfileBundle(_profileYaml);
      expect(b.isOk, isTrue);
      expect(b.profileText, _profileYaml);
      expect(b.workText, isNull);
      expect(b.privateText, isNull);
      expect(b.workCount, isNull);
    });

    test('プロフィールだけの Markdown：Work / Private はなし', () {
      final b = readProfileBundle(_profileMd, fileName: 'me.md');
      expect(b.isOk, isTrue);
      expect(b.workText, isNull);
      expect(b.privateText, isNull);
    });
  });

  group('テンプレート（format_profile.yaml / .md）', () {
    test('Work / Private も単独のテンプレートと同じ内容（全項目）で書いてある', () {
      for (final name in ['format_profile.yaml', 'format_profile.md']) {
        final b = readProfileBundle(_asset(name), fileName: name);
        expect(b.errors, isEmpty, reason: name);
        expect(b.profile!.name, '山田 太郎', reason: name);
        expect(_projects(b.workText!), _projects(_asset('format_work.yaml')), reason: name);
        expect(_projects(b.privateText!), _projects(_asset('format_private.yaml')), reason: name);
      }
    });

    test('Work / Private の見出し（区切り）ごと消せば、プロフィールだけになる', () {
      final yaml = _asset('format_profile.yaml');
      final profileOnly = yaml.substring(0, yaml.indexOf('# ---------- Work / Private'));
      final b = readProfileBundle(profileOnly);
      expect(b.isOk, isTrue);
      expect(b.workText, isNull);
      expect(b.privateText, isNull);
    });
  });

  group('YAML：work / private も一緒に', () {
    test('プロジェクトの並びで書ける', () {
      const yaml = '''
$_profileYaml
work:
  - title: 業務A
    workflow:
      requirements: true
  - title: 業務B
    workflow:
      requirements: false
private:
  - title: 個人A
''';
      final b = readProfileBundle(yaml);
      expect(b.errors, isEmpty);
      expect(b.profile!.name, '山田 太郎');
      expect(_titles(b.workText!), ['業務A', '業務B']);
      expect(_titles(b.privateText!), ['個人A']);
      expect(b.workCount, 2);
      expect(b.privateCount, 1);
      expect(isValidProjectsYaml(b.workText!, 'work'), isTrue);
      expect(isValidProjectsYaml(b.privateText!, 'private'), isTrue);
      // プロフィールのテキストには work / private を含めない
      final profile = loadYaml(b.profileText!) as YamlMap;
      expect(profile.keys, unorderedEquals(['home', 'about']));
    });

    test('「projects:」を持つ形（Work / Private のファイルと同じ形）でも書ける', () {
      const yaml = '''
$_profileYaml
private:
  projects:
    - title: 個人A
''';
      final b = readProfileBundle(yaml);
      expect(b.errors, isEmpty);
      expect(_titles(b.privateText!), ['個人A']);
      expect(b.workText, isNull);
    });

    test('プロジェクトの並びでなければ知らせる', () {
      final b = readProfileBundle('$_profileYaml\nwork: 業務A\n');
      expect(b.isOk, isFalse);
      expect(b.errors, contains(BundleTexts.notProjects('work')));
    });

    test('Work に workflow がない・Private に workflow がある', () {
      const yaml = '''
$_profileYaml
work:
  - title: 業務A
private:
  - title: 個人A
    workflow:
      requirements: true
''';
      final b = readProfileBundle(yaml);
      expect(b.isOk, isFalse);
      expect(b.errors, containsAll([BundleTexts.workInvalid, BundleTexts.privateInvalid]));
      expect(b.profile, isNull);
    });

    test('プロフィールの誤りも一緒に知らせる', () {
      final b = readProfileBundle('home:\n  name: 山田\nabout:\n  intro: 自己紹介\nwork:\n  - title: 業務A\n');
      expect(b.isOk, isFalse);
      expect(b.errors, contains(ProfileTexts.errorRequired('home.role')));
      expect(b.errors, contains(BundleTexts.workInvalid)); // workflow がない
    });
  });

  group('Markdown：# work / # private も一緒に', () {
    test('「## プロジェクト名」「### details」で書ける', () {
      const md = '''
$_profileMd
# work

## 業務A
- period: 2024-04 ~ 現在
- skills: Python, SQL
- workflow: 基本設計, 詳細設計

### details
1 行目
2 行目

## 業務B
- workflow: 保守・運用

# private

## 個人A
- skills: Dart
''';
      final b = readProfileBundle(md, fileName: 'me.md');
      expect(b.errors, isEmpty);
      expect(b.format, DataFormat.markdown);
      expect(b.profile!.name, '山田 太郎');
      expect(b.profile!.intro, '自己紹介');
      final work = _projects(b.workText!);
      expect(work.map((p) => p['title']), ['業務A', '業務B']);
      expect(work[0]['skills'], ['Python', 'SQL']);
      expect(work[0]['details'], '1 行目\n2 行目');
      expect(work[0]['workflow']['basic_design'], true);
      expect(_titles(b.privateText!), ['個人A']);
    });

    test('Work / Private のテンプレートの見出しを 1 段深くして足すと、単独のファイルと同じ中身になる', () {
      String deeper(String md) => md.replaceAllMapped(RegExp(r'^(#+) ', multiLine: true), (m) => '#${m[1]} ');
      final md = '$_profileMd\n# work\n${deeper(_asset('format_work.md'))}\n'
          '# private\n${deeper(_asset('format_private.md'))}';
      final b = readProfileBundle(md, fileName: 'me.md');
      expect(b.errors, isEmpty);
      expect(_projects(b.workText!), _projects(_asset('format_work.yaml')));
      expect(_projects(b.privateText!), _projects(_asset('format_private.yaml')));
    });

    test('書き方の誤りは、元のファイルの行番号で知らせる', () {
      const md = '''
# home
- name: 山田
- role: エンジニア
- tagline: 紹介文
# about
- intro: 自己紹介
# work
## 業務A
- skils: Dart
''';
      final b = readProfileBundle(md, fileName: 'me.md');
      expect(b.isOk, isFalse);
      expect(b.errors, contains(MarkdownTexts.unknownKey(9, 'skils')));
    });

    test('テンプレート（コメントあり）の Work 部分に書き間違いを入れると、元のファイルの行番号を出す', () {
      final lines = _asset('format_profile.md').split('\n');
      final work = lines.indexOf('# work');
      final at = lines.indexWhere((l) => l.startsWith('- skills:'), work);
      lines[at] = '- skils: Python';
      final b = readProfileBundle(lines.join('\n'), fileName: 'me.md');
      expect(b.errors, [MarkdownTexts.unknownKey(at + 1, 'skils')]);
    });

    test('「# work」の下にプロジェクトがない', () {
      final b = readProfileBundle('$_profileMd\n# work\n- skills: Dart\n', fileName: 'me.md');
      expect(b.errors, contains(BundleTexts.noProjectsIn('work')));
    });
  });

  test('件数の表示', () {
    expect(BundleTexts.includes(19, 1), 'Work 19 件・Private 1 件');
    expect(BundleTexts.includes(null, 1), 'Private 1 件');
    expect(BundleTexts.includes(null, null), '');
  });
}
