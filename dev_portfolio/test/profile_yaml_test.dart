// プロフィール YAML（Home / About）の読み込みと検証のテスト
// 対象：lib/models/profile.dart の Profile.parse
//
// 実行：flutter test test/profile_yaml_test.dart（dev_portfolio/ で）
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/models/profile.dart';

/// 必須項目だけを書いた最小の YAML
const _minimal = '''
home:
  name: 山田 太郎
  role: エンジニア
  tagline: 紹介文です
about:
  intro: 自己紹介です
''';

/// [_minimal] の一部を書き換えた YAML を作る
String _with({String home = '', String about = ''}) => '''
home:
  name: 山田 太郎
  role: エンジニア
  tagline: 紹介文です
$home
about:
  intro: 自己紹介です
$about
''';

void main() {
  group('テンプレート（assets/data）', () {
    test('format_profile.yaml はそのまま読み込める', () {
      final text = File('assets/data/format_profile.yaml').readAsStringSync();
      final result = Profile.parse(text);

      expect(result.errors, isEmpty);
      final p = result.profile!;
      expect(p.name, '山田 太郎');
      expect(p.role, isNotEmpty);
      expect(p.tagline, isNotEmpty);
      expect(p.intro, isNotEmpty);
      expect(p.card['stack'], ['Flutter', 'Dart', 'TypeScript']);
      expect(p.domains, contains('Flutter'));
      expect(p.strengths, isNotEmpty);
      expect(p.style, isNotEmpty);
      expect(p.closing, isNotEmpty);
    });

    test('Work / Private の YAML はプロフィールとして読み込めない', () {
      for (final f in ['format_work.yaml', 'format_private.yaml']) {
        final text = File('assets/data/$f').readAsStringSync();
        final result = Profile.parse(text);
        expect(result.isOk, isFalse, reason: f);
        expect(result.errors, contains(ProfileTexts.errorUnknownKey('projects')), reason: f);
        expect(result.errors, contains(ProfileTexts.errorMissingSection('home')), reason: f);
        expect(result.errors, contains(ProfileTexts.errorMissingSection('about')), reason: f);
      }
    });
  });

  group('正しい YAML', () {
    test('必須項目だけでも読み込め、任意項目は空になる', () {
      final result = Profile.parse(_minimal);

      expect(result.isOk, isTrue);
      final p = result.profile!;
      expect(p.name, '山田 太郎');
      expect(p.role, 'エンジニア');
      expect(p.tagline, '紹介文です');
      expect(p.intro, '自己紹介です');
      expect(p.card, isEmpty);
      expect(p.domains, isEmpty);
      expect(p.strengths, '');
      expect(p.style, '');
      expect(p.closing, '');
    });

    test('複数行の文章（|）は前後の空白・改行を除いて読み込む', () {
      final result = Profile.parse('''
home:
  name: 山田
  role: エンジニア
  tagline: |
    1 行目
    2 行目
about:
  intro: 自己紹介
''');
      expect(result.profile!.tagline, '1 行目\n2 行目');
    });

    test('card は文字列・数値・箇条書きを受け付ける（数値は文字列にする）', () {
      final result = Profile.parse(_with(home: '''
  card:
    role: Engineer
    since: 2020
    stack:
      - Flutter
      - Dart
'''));
      expect(result.errors, isEmpty);
      expect(result.profile!.card, {
        'role': 'Engineer',
        'since': '2020',
        'stack': ['Flutter', 'Dart'],
      });
    });

    test('domains は空の要素を除き、[a, b] の形でも読める', () {
      final r1 = Profile.parse(_with(about: '''
  domains:
    - Web
    -
    - "  "
    - モバイル
'''));
      expect(r1.profile!.domains, ['Web', 'モバイル']);

      final r2 = Profile.parse(_with(about: '  domains: [Web, Flutter]'));
      expect(r2.profile!.domains, ['Web', 'Flutter']);
    });
  });

  group('読み込めない YAML', () {
    test('YAML の書き方の誤り', () {
      final result = Profile.parse('home:\n  name: [閉じていない');
      expect(result.isOk, isFalse);
      expect(result.errors.single, startsWith('YAML の書き方に誤りがあります'));
    });

    test('空のファイル・「キー: 値」の形でない', () {
      for (final text in ['', '- a\n- b\n', 'ただの文字']) {
        final result = Profile.parse(text);
        expect(result.errors, [ProfileTexts.errorNotMap], reason: text);
      }
    });

    test('home: / about: がない', () {
      final noAbout = Profile.parse('''
home:
  name: 山田
  role: エンジニア
  tagline: 紹介文
''');
      expect(noAbout.errors, [ProfileTexts.errorMissingSection('about')]);

      final homeIsText = Profile.parse('home: 山田\nabout:\n  intro: 自己紹介\n');
      expect(homeIsText.errors, [ProfileTexts.errorMissingSection('home')]);
    });

    test('必須項目がない・空', () {
      final result = Profile.parse('''
home:
  name: ""
  tagline: 紹介文
about:
  intro: "   "
''');
      expect(result.isOk, isFalse);
      expect(
        result.errors,
        containsAll([
          ProfileTexts.errorRequired('home.name'),
          ProfileTexts.errorRequired('home.role'),
          ProfileTexts.errorRequired('about.intro'),
        ]),
      );
      expect(result.errors, hasLength(3));
    });

    test('使えない項目（打ち間違いなど）', () {
      final yaml = _with(home: '  nmae: 打ち間違い', about: '  hobby: 読書');
      final result = Profile.parse('${yaml}extra: 1\n');
      expect(
        result.errors,
        containsAll([
          ProfileTexts.errorUnknownKey('home.nmae'),
          ProfileTexts.errorUnknownKey('about.hobby'),
          ProfileTexts.errorUnknownKey('extra'),
        ]),
      );
    });

    test('文章の場所に箇条書き・「キー: 値」を書いた', () {
      final result = Profile.parse(_with(about: '''
  strengths:
    - チーム開発
  style:
    a: b
'''));
      expect(
        result.errors,
        containsAll([
          ProfileTexts.errorNotText('about.strengths'),
          ProfileTexts.errorNotText('about.style'),
        ]),
      );
    });

    test('domains を箇条書きにしていない', () {
      final result = Profile.parse(_with(about: '  domains: Web, モバイル'));
      expect(result.errors, [ProfileTexts.errorNotList('about.domains')]);
    });

    test('card を「キー: 値」にしていない・値に入れ子の「キー: 値」がある', () {
      final notMap = Profile.parse(_with(home: '''
  card:
    - a
'''));
      expect(notMap.errors, [ProfileTexts.errorNotMapField('home.card')]);

      final nested = Profile.parse(_with(home: '''
  card:
    links:
      github: https://example.com
'''));
      expect(nested.errors, [ProfileTexts.errorCardValue('home.card.links')]);
    });

    test('エラーのときは profile が null', () {
      final result = Profile.parse('');
      expect(result.profile, isNull);
      expect(result.isOk, isFalse);
    });
  });
}
