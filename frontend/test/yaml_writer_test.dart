// YAML の書き出し（Excel から作ったプロフィールの保存用）のテスト
// 対象：lib/utils/yaml_writer.dart
// 見るところ：書いた YAML を読み直すと元と同じになるか（正常系）／誤読されうる文字列を必ず "…" で囲むか（異常系）
//
// 実行：flutter test test/yaml_writer_test.dart（frontend/ で）
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/utils/yaml_writer.dart';

/// YamlMap / YamlList を普通の Map / List にする（比べやすくする）
Object? _plain(Object? node) {
  if (node is YamlMap) return {for (final e in node.entries) '${e.key}': _plain(e.value)};
  if (node is YamlList) return [for (final v in node) _plain(v)];
  return node;
}

Object? _roundTrip(Map<String, Object?> data) => _plain(loadYaml(toYaml(data)));

void main() {
  group('正常系：読み直すと元と同じ', () {
    test('入れ子の Map・List・List の中の Map・数・真偽', () {
      final data = <String, Object?>{
        'home': {
          'name': '山田 太郎',
          'stack': ['Flutter', 'Dart'],
        },
        'projects': [
          {
            'title': 'A',
            'skills': ['Dart', 'Go'],
            'workflow': {'requirements': true, 'basic_design': false},
          },
          {'title': 'B'},
        ],
        'count': 3,
        'ratio': 1.5,
        'negative': -2,
        'flag': false,
      };
      expect(_roundTrip(data), data);
    });

    test('そのまま書ける文字列は囲まない', () {
      for (final s in ['Dart', '山田 太郎', '_private', '(注) 補足', '（注）', 'a#b', 'C++', 'Node.js', 'C#']) {
        final yaml = toYaml({'v': s});
        expect(yaml, 'v: $s\n', reason: s);
        expect(_roundTrip({'v': s}), {'v': s}, reason: s);
      }
    });

    test('複数行の文章は「|-」のブロックで書く（途中の空行も残る）', () {
      const text = '1 行目\n\n3 行目';
      final yaml = toYaml({'details': text});
      expect(yaml, 'details: |-\n  1 行目\n\n  3 行目\n');
      expect(_roundTrip({'details': text}), {'details': text});
    });

    test('List の中の複数行・List の中の List', () {
      final data = <String, Object?>{
        'notes': ['1 行目\n2 行目', '1 行'],
        'matrix': [
          ['a', 'b'],
          'c',
        ],
      };
      expect(_roundTrip(data), data);
      expect(toYaml(data), contains('  - |-\n'));
    });

    test('List の中の Map の 2 つ目以降のキーは、最初のキーにそろえる', () {
      final yaml = toYaml({
        'projects': [
          {'title': 'A', 'details': '1\n2'},
        ],
      });
      expect(yaml, 'projects:\n  - title: A\n    details: |-\n      1\n      2\n');
    });

    test('先頭のコメント（空行は「#」だけ）', () {
      final yaml = toYaml({'a': 1}, header: '説明\n\n2 行目');
      expect(yaml, '# 説明\n#\n# 2 行目\n\na: 1\n');
      expect(_plain(loadYaml(yaml)), {'a': 1});
    });

    test('文字でないキー（数）は文字にする', () {
      final data = <String, Object?>{
        'm': {1: 'a', 2: 'b'},
      };
      expect(_roundTrip(data), {
        'm': {'1': 'a', '2': 'b'},
      });
    });
  });

  group('異常系：誤読されうる文字列は "…" で囲み、読み直しても文字列のまま', () {
    // （理由, 文字列）
    const risky = [
      ('真偽として読まれる', 'true'),
      ('真偽（大文字）', 'False'),
      ('yes / no', 'yes'),
      ('yes / no', 'No'),
      ('on / off', 'on'),
      ('null', 'null'),
      ('y / n', 'y'),
      ('y / n', 'N'),
      ('数として読まれる', '123'),
      ('小数', '1.5'),
      ('年月（数字で始まる）', '2024-04'),
      ('並びの記号', '- x'),
      ('コメントの記号', '# x'),
      ('途中のコメント', 'a #b'),
      ('「キー: 値」', 'a: b'),
      ('末尾の「:」', 'end:'),
      ('前の空白', '  lead'),
      ('後ろの空白', 'trail  '),
      ('空文字', ''),
      ('アンカー', '&x'),
      ('参照', '*x'),
      ('タグ', '!x'),
      ('予約の記号', '@x'),
      ('流れの並び', '[x]'),
      ('流れの Map', '{x}'),
      ('ブロックの記号', '|x'),
      ('ブロックの記号', '>x'),
      ('引用符', '"x"'),
      ('引用符', "'x'"),
      ('ディレクティブ', '%x'),
      ('制御文字', 'a\u0007b'),
    ];
    for (final (why, s) in risky) {
      test('$why：${s.isEmpty ? '（空）' : s}', () {
        final yaml = toYaml({'v': s});
        expect(yaml, startsWith('v: "'), reason: yaml);
        expect(_roundTrip({'v': s}), {'v': s});
      });
    }

    test('キーも誤読されうるなら囲む', () {
      // 値の y は予約語（真偽）として囲まれるので、キーだけを見るため値はふつうの文字にする
      final data = <String, Object?>{'1st': 'x', 'a: b': 'value', 'true': 'z'};
      final yaml = toYaml(data);
      expect(yaml, contains('"1st": x'));
      expect(yaml, contains('"a: b": value'));
      expect(yaml, contains('"true": z'));
      expect(_roundTrip(data), data);
    });

    // ブロックにすると中身が変わってしまう複数行は、ブロックにせず囲む
    const notBlock = [
      ('1 行目が空白で始まる', ' a\nb'),
      ('改行で始まる', '\na'),
      ('改行で終わる', 'a\nb\n'),
      ('タブを含む', 'a\tb\nc'),
      ('制御文字を含む', 'a\u0007\nb'),
    ];
    for (final (why, s) in notBlock) {
      test('複数行でも $why ならブロックにしない', () {
        final yaml = toYaml({'v': s});
        expect(yaml, isNot(contains('|-')));
        expect(_roundTrip({'v': s}), {'v': s});
      });
    }
  });

  group('空・null', () {
    test('null は空文字として書く（読み直すと ""）', () {
      expect(toYaml({'a': null}), 'a: ""\n');
      expect(_roundTrip({'a': null}), {'a': ''});
    });

    test('空の Map は {}、空の List は []', () {
      expect(toYaml({'a': <String, Object?>{}, 'b': <Object?>[]}), 'a: {}\nb: []\n');
      expect(_roundTrip({'a': <String, Object?>{}, 'b': <Object?>[]}), {'a': {}, 'b': []});
    });

    test('List の中の null・空の Map・空の List', () {
      final yaml = toYaml({
        'l': ['x', null, <String, Object?>{}, <Object?>[]],
      });
      expect(yaml, 'l:\n  - x\n  - ""\n  - {}\n  - []\n');
    });

    test('中身のない Map 全体は空の文字列', () {
      expect(toYaml({}), '');
    });
  });
}
