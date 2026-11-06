// 小さな共通の処理のテスト
// 対象：lib/utils/string_utils.dart、lib/utils/language_utils.dart、lib/utils/graph_utils.dart
//
// 実行：flutter test test/small_utils_test.dart（frontend/ で）
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/utils/graph_utils.dart';
import 'package:dev_portfolio/utils/language_utils.dart';
import 'package:dev_portfolio/utils/string_utils.dart';

void main() {
  group('parseToList（文字・並びを List<String> に）', () {
    test('null は空', () => expect(parseToList(null), isEmpty));

    test('並び：前後の空白を外し、空の項目は入れない。数などは文字にする', () {
      expect(parseToList([' Dart ', '', '  ', 'Go', 3]), ['Dart', 'Go', '3']);
    });

    // （文字, 結果）
    const strings = [
      ('Dart,Go', ['Dart', 'Go']),
      ('Dart, Go', ['Dart', 'Go']),
      ('Dart、Go', ['Dart', 'Go']), // 読点
      ('Dart Go', ['Dart', 'Go']), // 空白
      ('Dart,,  ,Go', ['Dart', 'Go']), // 区切りが続く
      (' , Dart , ', ['Dart']), // 前後の区切り
      ('', <String>[]),
      ('   ', <String>[]),
    ];
    for (final (text, expected) in strings) {
      test('文字「$text」→ $expected', () => expect(parseToList(text), expected));
    }

    test('文字・並び以外（Map・数）は空', () {
      expect(parseToList({'a': 1}), isEmpty);
      expect(parseToList(42), isEmpty);
    });
  });

  group('splitSkills', () {
    test('カンマ・読点・空白で分ける', () {
      expect(splitSkills('Dart, Go、Python Rust'), ['Dart', 'Go', 'Python', 'Rust']);
    });

    test('空・空白だけなら空', () {
      expect(splitSkills(''), isEmpty);
      expect(splitSkills(' 、, '), isEmpty);
    });
  });

  group('LanguageUtils.translateWorkflowData', () {
    test('工程のキーを日本語にし、合計 100 にそろえる', () {
      final r = LanguageUtils.translateWorkflowData({'requirements': 1.0, 'basic_design': 3.0});
      expect(r, {'要件定義': 25, '基本設計': 75});
    });

    test('7 工程すべてに日本語の名前がある', () {
      final r = LanguageUtils.translateWorkflowData({
        for (final key in LanguageUtils.workflowLabels['ja']!.keys) key: 1.0,
      });
      expect(r.keys, ['要件定義', '基本設計', '詳細設計', '実装・単体テスト', '結合テスト', '総合テスト', '保守・運用']);
      expect(r.values.fold<double>(0, (a, b) => a + b), closeTo(100, 1e-9));
    });

    test('知らないキーはそのままの名前で残す', () {
      final r = LanguageUtils.translateWorkflowData({'requirements': 50.0, 'custom': 50.0});
      expect(r, {'要件定義': 50, 'custom': 50});
    });

    test('合計が 0 なら割らずに名前だけ変える', () {
      expect(LanguageUtils.translateWorkflowData({'requirements': 0.0}), {'要件定義': 0});
    });

    test('空なら空', () {
      expect(LanguageUtils.translateWorkflowData({}), isEmpty);
    });

    test('知らない言語なら何も変えない', () {
      final data = {'requirements': 1.0};
      expect(LanguageUtils.translateWorkflowData(data, locale: 'en'), same(data));
    });
  });

  group('mapIndexed（MapEntry の並びに番号を付ける）', () {
    test('0 から順に番号が付く', () {
      final r = {'a': 1, 'b': 2, 'c': 3}.entries.mapIndexed((e, i) => '$i:${e.key}=${e.value}').toList();
      expect(r, ['0:a=1', '1:b=2', '2:c=3']);
    });

    test('空なら空', () {
      expect(<String, int>{}.entries.mapIndexed((e, i) => i).toList(), isEmpty);
    });
  });
}
