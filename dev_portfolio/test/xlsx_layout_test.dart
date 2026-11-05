// Excel の見た目の読み取り（PDF にするとき・書き込むときに使う）のテスト
// 対象：lib/utils/xlsx_layout.dart（parseCellRef・readXlsxLayout・XlsxMerge・XlsxBorderSide）
// テンプレート assets/data/format_skill_sheet.xlsx の実際の設定で確かめる
//
// 実行：flutter test test/xlsx_layout_test.dart（dev_portfolio/ で）
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/utils/skill_sheet.dart';
import 'package:dev_portfolio/utils/xlsx_layout.dart';

void main() {
  final template = File(skillSheetTemplateAsset).readAsBytesSync();
  final layout = readXlsxLayout(template);

  group('セル番地', () {
    test('「A1」→ (行, 列)。2 文字の列も', () {
      expect(parseCellRef('A1'), (1, 1));
      expect(parseCellRef('Z9'), (9, 26));
      expect(parseCellRef('AA10'), (10, 27));
      expect(parseCellRef('AT23'), (23, 46));
      expect(parseCellRef('AV4'), (4, 48));
    });

    test('番地でないものは null', () {
      expect(parseCellRef(''), isNull);
      expect(parseCellRef('12'), isNull);
      expect(parseCellRef('ABC'), isNull);
    });

    test('1 枚目のシートの場所（workbook.xml と rels から）', () {
      expect(firstSheetPath(ZipDecoder().decodeBytes(template)), 'xl/worksheets/sheet1.xml');
    });
  });

  group('結合・罫線', () {
    test('XlsxMerge.contains：両端を含む', () {
      const m = XlsxMerge(12, 5, 15, 21); // E12:U15
      expect(m.contains(12, 5), isTrue);
      expect(m.contains(15, 21), isTrue);
      expect(m.contains(13, 10), isTrue);
      expect(m.contains(11, 5), isFalse);
      expect(m.contains(16, 5), isFalse);
      expect(m.contains(12, 22), isFalse);
    });

    test('罫線の太さと破線の模様', () {
      expect(const XlsxBorderSide('thin', 0).width, 0.5);
      expect(const XlsxBorderSide('medium', 0).width, 1.0);
      expect(const XlsxBorderSide('thick', 0).width, 1.5);
      expect(const XlsxBorderSide('hair', 0).width, 0.25);
      expect(const XlsxBorderSide('thin', 0).dash, isEmpty);
      expect(const XlsxBorderSide('dashed', 0).dash, [3, 2]);
      expect(const XlsxBorderSide('dotted', 0).dash, [1, 1]);
      expect(const XlsxBorderSide('dashDotDot', 0).dash, [4, 2, 1, 2, 1, 2]);
    });
  });

  group('テンプレートのシート', () {
    test('余白（0.3937 インチ＝約 28.35pt）・横の中央寄せ・フッターの右（&P/）', () {
      for (final m in [layout.marginLeft, layout.marginRight, layout.marginTop, layout.marginBottom]) {
        expect(m, closeTo(28.35, 0.01));
      }
      expect(layout.horizontalCentered, isTrue);
      expect(layout.footerRight, '&P/');
    });

    test('列の幅：Excel と同じ px → pt の計算（2.43 文字 → 17px → 12.75pt）。隠した列（AV）は 0', () {
      expect(layout.colWidthPt(1), 12.75);
      expect(layout.colWidthPt(21), 7.5); // 1.43 文字 → 10px
      expect(layout.hiddenCols, contains(48));
      expect(layout.colWidthPt(48), 0);
    });

    test('行の高さ：プロジェクトの 1 件目は 16.5pt × 4 行＋384pt', () {
      for (var r = 11; r <= 14; r++) {
        expect(layout.rowHeightPt(r), 16.5);
      }
      expect(layout.rowHeightPt(15), 384);
    });

    test('結合（氏名の欄・業務概要・作業工程の見出し）', () {
      bool has(int r1, int c1, int r2, int c2) =>
          layout.merges.any((m) => m.r1 == r1 && m.c1 == c1 && m.r2 == r2 && m.c2 == c2);
      expect(has(5, 1, 5, 4), isTrue); // A5:D5
      expect(has(12, 5, 15, 21), isTrue); // E12:U15
      expect(has(11, 1, 15, 1), isTrue); // A11:A15
      expect(has(12, 22, 15, 24), isTrue); // V12:X15
    });

    test('値：文字・共有文字列・数式の計算結果', () {
      expect(layout.cells[(5, 1)]!.value, '氏名');
      expect(layout.cells[(5, 5)]!.value, '山田 太郎');
      expect(layout.cells[(12, 22)]!.value, 'PG');
      expect(layout.cells[(4, 39)]!.value, '1990年04月01日'); // AM4（数式）
      expect(layout.cells[(8, 5)]!.value, 'プロジェクト名\n業務概要');
    });

    test('書式：文字の大きさ・太字・下線・寄せ方・折り返し・縮小・罫線', () {
      final title = layout.styleAt(1, 1); // A1
      expect(title.fontSize, 21);
      expect(title.bold, isTrue);
      expect(title.underline, isTrue);
      expect(title.hAlign, 'center');
      expect(title.vAlign, 'center');

      final exp = layout.styleAt(7, 1); // A7（開発経験）
      expect(exp.fontSize, 8);
      expect(exp.wrap, isTrue);
      expect(exp.hAlign, 'left');
      expect(exp.left?.style, 'thin');
      expect(exp.top?.style, 'thin');
      expect(exp.bottom?.style, 'thin');
      expect(exp.right, isNull);

      expect(layout.styleAt(12, 5).vAlign, 'top'); // E12（業務概要）
      final period = layout.styleAt(11, 2); // B11（期間）
      expect(period.shrink, isTrue);
      expect(period.wrap, isFalse);
      expect(layout.styleAt(5, 1).fontColor, 0xFFFFFFFF); // A5（白い文字）
      expect(layout.styleAt(3, 40).hAlign, 'right'); // AN3
    });

    test('値のないセルは、ブックの標準の書式（書式の 0 番。テンプレートは 10pt）', () {
      final s = layout.styleAt(900, 900);
      expect(s.fontSize, layout.styles.first.fontSize);
      expect(s.fontSize, 10);
    });

    test('印刷する範囲：右端は AT（46 列目。隠した AV は数えない）、下はプロジェクトの枠より下', () {
      final (maxR, maxC) = layout.usedRange;
      expect(maxC, 46);
      expect(maxR, greaterThanOrEqualTo(23));
    });
  });
}
