// スキルシートの PDF（ヘッダーの［ダウンロード］→ PDF）のテスト
// 対象：lib/utils/skill_sheet_pdf.dart（SkillSheetPdfGeometry・skillSheetFooterText・skillSheetPdf）
//
// 実行：flutter test test/skill_sheet_pdf_test.dart（frontend/ で）
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/utils/skill_sheet.dart';
import 'package:dev_portfolio/utils/skill_sheet_pdf.dart';
import 'package:dev_portfolio/utils/skill_sheet_writer.dart';
import 'package:dev_portfolio/utils/xlsx_layout.dart';

Uint8List _template() => File(skillSheetTemplateAsset).readAsBytesSync();
ByteData _font() => ByteData.sublistView(File(skillSheetPdfFontAsset).readAsBytesSync());

Map<String, dynamic> _project(String title, {String details = '詳細'}) => {
      'title': title,
      'description': '$title の説明',
      'details': details,
      'period': ['2024-01', '2024-06'],
      'skills': ['Dart'],
      'workflow': {'requirements': true},
    };

SkillSheetData _data(int work, {String details = '詳細'}) => SkillSheetData(
      name: '鈴木 一郎',
      experience: '直近の開発経験\n\nWeb開発：テスト',
      work: [for (var i = 0; i < work; i++) _project('案件$i', details: details)],
      private: const [],
    );

SkillSheetPdfGeometry _geo(SkillSheetData data) =>
    SkillSheetPdfGeometry(readXlsxLayout(fillSkillSheet(_template(), data)));

void main() {
  group('紙の上の配置', () {
    test('幅は余白の内側にぴったり縮める（大きくはしない）・横の中央寄せ', () {
      final g = SkillSheetPdfGeometry(readXlsxLayout(_template()));
      expect(g.scale, lessThan(1));
      expect(g.xs.last * g.scale, closeTo(g.printableW, 0.01));
      expect(g.offsetX, closeTo(g.layout.marginLeft, 0.01));
      expect(g.printableW, closeTo(SkillSheetPdfGeometry.paper.width - 2 * 28.35, 0.05));
    });

    test('ページは切れ目なく続き、最後は表の下端。どのページも紙に入る', () {
      final g = _geo(_data(6));
      final pageH = g.printableH / g.scale;
      expect(g.pages.first.$1, 0);
      expect(g.pages.last.$2, closeTo(g.ys.last, 0.01));
      for (var i = 0; i < g.pages.length; i++) {
        final (y0, y1) = g.pages[i];
        expect(y1, greaterThan(y0));
        expect(y1 - y0, lessThanOrEqualTo(pageH + 0.02));
        if (i > 0) expect(y0, g.pages[i - 1].$2);
      }
    });

    test('ふつうは行の切れ目で分ける', () {
      final g = _geo(_data(6));
      expect(g.pages.length, greaterThan(1));
      for (final (_, y1) in g.pages) {
        expect(g.ys.any((y) => (y - y1).abs() < 0.02), isTrue, reason: '$y1 は行の下端');
      }
    });

    test('案件が増えるとページも増える', () {
      expect(_geo(_data(8)).pages.length, greaterThan(_geo(_data(1)).pages.length));
    });

    test('1 行がページより高いときだけ、行の途中で分ける', () {
      final long = List.filled(700, 'とても長い詳細の行です').join('\n');
      final g = _geo(_data(1, details: long));
      final pageH = g.printableH / g.scale;
      expect(g.ys.last, greaterThan(pageH * 2));
      final midRow = g.pages.where((p) => !g.ys.any((y) => (y - p.$2).abs() < 0.02));
      expect(midRow, isNotEmpty);
    });
  });

  group('折り返し（skillSheetWrap）', () {
    // 1 文字の幅を 1 として、幅 4 で折り返す
    List<String> wrap(String s, [double max = 4]) => skillSheetWrap(s, max, (_) => 1);

    test('幅で折り返す', () {
      expect(wrap('あいうえおかきく'), ['あいうえ', 'おかきく']);
      expect(wrap(''), ['']);
    });

    test('「、」「。」は行の先頭に置かず、前の行の末尾に付ける', () {
      expect(wrap('あいうえ、おかき。'), ['あいうえ、', 'おかき。']);
      expect(wrap('あいうえ。'), ['あいうえ。']);
      for (final line in wrap('設計、実装、テスト、運用、保守を担当しました。', 5)) {
        expect('、。'.contains(line[0]), isFalse, reason: line);
      }
    });

    test('閉じかっこ・小さい仮名・長音も行の先頭に置かない', () {
      expect(wrap('あいうえ）か'), ['あいうえ）', 'か']);
      expect(wrap('あいうえっか'), ['あいうえっ', 'か']);
      expect(wrap('あいうえーか'), ['あいうえー', 'か']);
    });

    test('開きかっこは行の最後に置かず、次の行へ送る', () {
      expect(wrap('あいう（えお）'), ['あいう', '（えお）']);
    });

    test('英数字の単語は空白で切る', () {
      expect(wrap('ab cdef', 5), ['ab', 'cdef']);
    });
  });

  test('空白（半角・全角スペース・タブ）は描かずに幅だけ空ける（全角スペースが「、」の形で出ないように）', () {
    expect(isSkillSheetBlank(' '), isTrue);
    expect(isSkillSheetBlank('　'), isTrue);
    expect(isSkillSheetBlank('\t'), isTrue);
    expect(isSkillSheetBlank('、'), isFalse);
    expect(isSkillSheetBlank('a'), isFalse);
    // テンプレートのタイトルは「（全角スペース）Skill Sheet（全角スペース）」
    expect(readXlsxLayout(_template()).cells[(1, 1)]!.value, '　Skill Sheet　');
  });

  group('フッター', () {
    test('&P はページ番号、&N は総ページ数。「&P/」なら総ページ数を足す', () {
      expect(skillSheetFooterText('&P/', 2, 5), '2/5');
      expect(skillSheetFooterText('&P / &N', 1, 3), '1 / 3');
      expect(skillSheetFooterText('Page &P', 4, 4), 'Page 4');
    });

    test('フォントなどの指定は外す。なければ null', () {
      expect(skillSheetFooterText('&"ＭＳ Ｐゴシック,標準"&8&P/', 1, 2), '1/2');
      expect(skillSheetFooterText(null, 1, 1), isNull);
      expect(skillSheetFooterText('', 1, 1), isNull);
    });
  });

  group('PDF', () {
    test('テンプレートのまま（サンプル）でも出せる', () async {
      final pdf = await skillSheetPdf(_template(), _font());
      expect(ascii.decode(pdf.sublist(0, 5)), '%PDF-');
      expect(latin1.decode(pdf.sublist(pdf.length - 8)).trim(), endsWith('%%EOF'));
    });

    test('書き込んだもの（複数ページ・長い文章・0 件）も出せる。ページが多いほど大きい', () async {
      final one = await skillSheetPdf(fillSkillSheet(_template(), _data(1)), _font());
      final many = await skillSheetPdf(fillSkillSheet(_template(), _data(10)), _font());
      final none = await skillSheetPdf(fillSkillSheet(_template(), _data(0)), _font());
      final long = await skillSheetPdf(
          fillSkillSheet(_template(), _data(1, details: List.filled(300, '長い行').join('\n'))), _font());
      for (final pdf in [one, many, none, long]) {
        expect(ascii.decode(pdf.sublist(0, 5)), '%PDF-');
      }
      expect(many.length, greaterThan(one.length));
    });

    test('フォントはアセットとして登録されている（pubspec.yaml の書き忘れを見つける）', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final data = await rootBundle.load(skillSheetPdfFontAsset);
      expect(data.lengthInBytes, File(skillSheetPdfFontAsset).lengthSync());
    });
  });
}
