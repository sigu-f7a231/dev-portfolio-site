// lib/utils/xlsx_layout.dart
//
// Excel（.xlsx）の 1 枚目のシートの「見た目」を読む（スキルシートを PDF にするとき・書き込むときに使う）
// - 列の幅・行の高さ（隠した列・行も）・結合したセル・セルの値と書式（文字の大きさ・太字・色・塗り・罫線・寄せ方・折り返し）
// - フッター（ページ番号）・余白・中央寄せの指定
// 値は「セルに表示される文字」（数式は保存されている計算結果）。xlsx_reader.dart と同じ読み方
//
// Flutter に依存しない。
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// 罫線の 1 辺（style は thin / medium / thick / dashed / dotted / double / hair など）
class XlsxBorderSide {
  final String style;
  final int color; // 0xAARRGGBB

  const XlsxBorderSide(this.style, this.color);

  /// 線の太さ（pt）
  double get width => switch (style) {
        'medium' || 'mediumDashed' || 'mediumDashDot' || 'mediumDashDotDot' => 1.0,
        'thick' => 1.5,
        'double' => 1.5,
        'hair' => 0.25,
        _ => 0.5,
      };

  /// 破線の模様（実線は空）
  List<num> get dash => switch (style) {
        'dashed' || 'mediumDashed' => const [3, 2],
        'dotted' || 'hair' => const [1, 1],
        'dashDot' || 'mediumDashDot' || 'slantDashDot' => const [4, 2, 1, 2],
        'dashDotDot' || 'mediumDashDotDot' => const [4, 2, 1, 2, 1, 2],
        _ => const [],
      };
}

class XlsxCellStyle {
  final double fontSize;
  final bool bold;
  final bool italic;
  final bool underline;
  final int fontColor;

  /// 塗りつぶし（なければ null）
  final int? fill;

  final XlsxBorderSide? left, right, top, bottom;

  /// left / center / right / general など（なければ general）
  final String hAlign;

  /// top / center / bottom（なければ bottom）
  final String vAlign;
  final bool wrap;
  final bool shrink;

  const XlsxCellStyle({
    this.fontSize = 11,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.fontColor = 0xFF000000,
    this.fill,
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.hAlign = 'general',
    this.vAlign = 'bottom',
    this.wrap = false,
    this.shrink = false,
  });
}

/// 結合したセルの範囲（行・列とも 1 始まり、両端を含む）
class XlsxMerge {
  final int r1, c1, r2, c2;
  const XlsxMerge(this.r1, this.c1, this.r2, this.c2);

  bool contains(int r, int c) => r >= r1 && r <= r2 && c >= c1 && c <= c2;
}

class XlsxLayoutCell {
  final String value;
  final int style;
  const XlsxLayoutCell(this.value, this.style);
}

class XlsxLayout {
  /// 列の幅（Excel の文字数の単位）。書いていない列は [defaultColWidth]
  final Map<int, double> colWidths;
  final double defaultColWidth;
  final Set<int> hiddenCols;

  /// 行の高さ（pt）。書いていない行は [defaultRowHeight]
  final Map<int, double> rowHeights;
  final double defaultRowHeight;
  final Set<int> hiddenRows;

  /// (行, 列) → 値と書式の番号
  final Map<(int, int), XlsxLayoutCell> cells;
  final List<XlsxMerge> merges;
  final List<XlsxCellStyle> styles;

  /// 余白（pt）・用紙の横の中央寄せ・フッターの右（「&P」＝ページ番号）
  final double marginLeft, marginRight, marginTop, marginBottom;
  final bool horizontalCentered;
  final String? footerRight;

  const XlsxLayout({
    required this.colWidths,
    required this.defaultColWidth,
    required this.hiddenCols,
    required this.rowHeights,
    required this.defaultRowHeight,
    required this.hiddenRows,
    required this.cells,
    required this.merges,
    required this.styles,
    required this.marginLeft,
    required this.marginRight,
    required this.marginTop,
    required this.marginBottom,
    required this.horizontalCentered,
    required this.footerRight,
  });

  XlsxCellStyle styleAt(int r, int c) {
    final i = cells[(r, c)]?.style ?? 0;
    return i < styles.length ? styles[i] : const XlsxCellStyle();
  }

  /// 列の幅（pt）。Excel と同じく、標準の文字幅 7px として px にしてから pt（×0.75）にする
  double colWidthPt(int c) {
    if (hiddenCols.contains(c)) return 0;
    final w = colWidths[c] ?? defaultColWidth;
    const mdw = 7;
    final px = (((256 * w + (128 / mdw).truncate()) / 256) * mdw).truncate();
    return px * 0.75;
  }

  double rowHeightPt(int r) => hiddenRows.contains(r) ? 0 : (rowHeights[r] ?? defaultRowHeight);

  /// 印刷する範囲：値のあるセル・結合・罫線のあるセルが入る、いちばん右の列といちばん下の行（隠した列は数えない）
  (int, int) get usedRange {
    var maxR = 0, maxC = 0;
    void take(int r, int c) {
      if (hiddenCols.contains(c)) return;
      if (r > maxR) maxR = r;
      if (c > maxC) maxC = c;
    }

    for (final m in merges) {
      take(m.r2, m.c2);
    }
    for (final e in cells.entries) {
      final (r, c) = e.key;
      final s = e.value.style < styles.length ? styles[e.value.style] : null;
      final hasBorder =
          s != null && (s.left != null || s.right != null || s.top != null || s.bottom != null);
      if (e.value.value.trim().isNotEmpty || hasBorder) take(r, c);
    }
    return (maxR, maxC);
  }
}

// ------------------------------------------------------------
// 読み取り
// ------------------------------------------------------------
Iterable<XmlElement> _els(XmlNode node, String local) =>
    node.descendants.whereType<XmlElement>().where((e) => e.name.local == local);

XmlElement? _child(XmlElement node, String local) =>
    node.childElements.where((e) => e.name.local == local).firstOrNull;

final _cellRef = RegExp(r'^([A-Za-z]+)(\d+)$');

int _colNumber(String letters) {
  var n = 0;
  for (final code in letters.toUpperCase().codeUnits) {
    n = n * 26 + (code - 0x40);
  }
  return n;
}

/// 「A1」→（行, 列）
(int, int)? parseCellRef(String ref) {
  final m = _cellRef.firstMatch(ref);
  if (m == null) return null;
  return (int.parse(m.group(2)!), _colNumber(m.group(1)!));
}

/// 色（rgb="FF112233" / theme="0" など）→ 0xAARRGGBB。テーマは 0 = 白、それ以外 = 黒（スキルシートで使う範囲）
int? _color(XmlElement? e, {int? fallback}) {
  if (e == null) return fallback;
  final rgb = e.getAttribute('rgb');
  if (rgb != null && rgb.length >= 6) {
    final v = int.tryParse(rgb.length == 6 ? 'FF$rgb' : rgb, radix: 16);
    if (v != null) return v;
  }
  final theme = int.tryParse(e.getAttribute('theme') ?? '');
  if (theme != null) return theme == 0 ? 0xFFFFFFFF : 0xFF000000;
  final indexed = int.tryParse(e.getAttribute('indexed') ?? '');
  if (indexed != null) return indexed == 9 ? 0xFFFFFFFF : 0xFF000000;
  return fallback;
}

List<XlsxCellStyle> _readStyles(XmlDocument? doc) {
  if (doc == null) return const [XlsxCellStyle()];
  final fonts = <(double, bool, bool, bool, int)>[];
  for (final f in _els(doc, 'fonts').firstOrNull?.childElements ?? const <XmlElement>[]) {
    final sz = double.tryParse(_child(f, 'sz')?.getAttribute('val') ?? '') ?? 11;
    fonts.add((
      sz,
      _child(f, 'b') != null,
      _child(f, 'i') != null,
      _child(f, 'u') != null,
      _color(_child(f, 'color'), fallback: 0xFF000000)!,
    ));
  }

  final fills = <int?>[];
  for (final f in _els(doc, 'fills').firstOrNull?.childElements ?? const <XmlElement>[]) {
    final p = _child(f, 'patternFill');
    fills.add(p?.getAttribute('patternType') == 'solid' ? _color(_child(p!, 'fgColor')) : null);
  }

  final borders = <List<XlsxBorderSide?>>[];
  for (final b in _els(doc, 'borders').firstOrNull?.childElements ?? const <XmlElement>[]) {
    XlsxBorderSide? side(String name) {
      final e = _child(b, name);
      final style = e?.getAttribute('style');
      if (e == null || style == null || style == 'none') return null;
      return XlsxBorderSide(style, _color(_child(e, 'color'), fallback: 0xFF000000)!);
    }

    borders.add([side('left'), side('right'), side('top'), side('bottom')]);
  }

  final xfs = _els(doc, 'cellXfs').firstOrNull?.childElements ?? const <XmlElement>[];
  return [
    for (final xf in xfs)
      () {
        final font = fonts.elementAtOrNull(int.tryParse(xf.getAttribute('fontId') ?? '') ?? 0) ??
            (11.0, false, false, false, 0xFF000000);
        final fill = fills.elementAtOrNull(int.tryParse(xf.getAttribute('fillId') ?? '') ?? 0);
        final border = borders.elementAtOrNull(int.tryParse(xf.getAttribute('borderId') ?? '') ?? 0) ??
            const [null, null, null, null];
        final al = _child(xf, 'alignment');
        return XlsxCellStyle(
          fontSize: font.$1,
          bold: font.$2,
          italic: font.$3,
          underline: font.$4,
          fontColor: font.$5,
          fill: fill,
          left: border[0],
          right: border[1],
          top: border[2],
          bottom: border[3],
          hAlign: al?.getAttribute('horizontal') ?? 'general',
          vAlign: al?.getAttribute('vertical') ?? 'bottom',
          wrap: al?.getAttribute('wrapText') == '1' || al?.getAttribute('wrapText') == 'true',
          shrink: al?.getAttribute('shrinkToFit') == '1' || al?.getAttribute('shrinkToFit') == 'true',
        );
      }(),
  ];
}

String _richText(XmlElement node) {
  final b = StringBuffer();
  for (final t in _els(node, 't')) {
    if (!t.ancestors.whereType<XmlElement>().any((a) => a.name.local == 'rPh')) b.write(t.innerText);
  }
  return b.toString();
}

/// 1 枚目のシートの場所（xl/_rels/workbook.xml.rels から。なければ sheet1.xml）
String firstSheetPath(Archive archive) {
  String? text(String p) {
    final f = archive.findFile(p);
    return f == null ? null : utf8.decode(f.content, allowMalformed: true);
  }

  final wb = text('xl/workbook.xml');
  final rels = text('xl/_rels/workbook.xml.rels');
  if (wb != null && rels != null) {
    final sheet = _els(XmlDocument.parse(wb), 'sheet').firstOrNull;
    final id = sheet?.attributes.where((a) => a.name.local == 'id').map((a) => a.value).firstOrNull;
    for (final r in _els(XmlDocument.parse(rels), 'Relationship')) {
      if (r.getAttribute('Id') == id) {
        final t = r.getAttribute('Target')!;
        return t.startsWith('/') ? t.substring(1) : 'xl/$t';
      }
    }
  }
  return 'xl/worksheets/sheet1.xml';
}

/// .xlsx のバイト列から、1 枚目のシートの見た目を読む
XlsxLayout readXlsxLayout(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  XmlDocument? xml(String p) {
    final f = archive.findFile(p);
    return f == null ? null : XmlDocument.parse(utf8.decode(f.content, allowMalformed: true));
  }

  final shared = [
    for (final si in _els(xml('xl/sharedStrings.xml') ?? XmlDocument(), 'si')) _richText(si),
  ];
  final styles = _readStyles(xml('xl/styles.xml'));
  final sheet = xml(firstSheetPath(archive))!;

  final fmt = _els(sheet, 'sheetFormatPr').firstOrNull;
  final colWidths = <int, double>{};
  final hiddenCols = <int>{};
  for (final col in _els(sheet, 'col')) {
    final min = int.parse(col.getAttribute('min') ?? '1');
    final max = int.parse(col.getAttribute('max') ?? '$min');
    final w = double.tryParse(col.getAttribute('width') ?? '');
    final hidden = col.getAttribute('hidden') == '1' || col.getAttribute('hidden') == 'true';
    for (var c = min; c <= max; c++) {
      if (w != null) colWidths[c] = w;
      if (hidden) hiddenCols.add(c);
    }
  }

  final rowHeights = <int, double>{};
  final hiddenRows = <int>{};
  final cells = <(int, int), XlsxLayoutCell>{};
  for (final row in _els(sheet, 'row')) {
    final r = int.tryParse(row.getAttribute('r') ?? '');
    if (r == null) continue;
    final ht = double.tryParse(row.getAttribute('ht') ?? '');
    if (ht != null) rowHeights[r] = ht;
    if (row.getAttribute('hidden') == '1') hiddenRows.add(r);
    for (final c in row.childElements.where((e) => e.name.local == 'c')) {
      final ref = parseCellRef(c.getAttribute('r') ?? '');
      if (ref == null) continue;
      final style = int.tryParse(c.getAttribute('s') ?? '') ?? 0;
      final v = _child(c, 'v')?.innerText;
      final value = switch (c.getAttribute('t')) {
        's' => shared.elementAtOrNull(int.tryParse(v ?? '') ?? -1) ?? '',
        'inlineStr' => _child(c, 'is') == null ? '' : _richText(_child(c, 'is')!),
        'b' => v == '1' ? 'TRUE' : (v == null ? '' : 'FALSE'),
        _ => v ?? '',
      };
      cells[ref] = XlsxLayoutCell(value.replaceAll('\r\n', '\n').replaceAll('\r', '\n'), style);
    }
  }

  final merges = <XlsxMerge>[];
  for (final m in _els(sheet, 'mergeCell')) {
    final parts = (m.getAttribute('ref') ?? '').split(':');
    final a = parseCellRef(parts.first);
    final b = parseCellRef(parts.last);
    if (a != null && b != null) merges.add(XlsxMerge(a.$1, a.$2, b.$1, b.$2));
  }

  final margins = _els(sheet, 'pageMargins').firstOrNull;
  double inch(String name, double def) =>
      (double.tryParse(margins?.getAttribute(name) ?? '') ?? def) * 72;
  final footer = _els(sheet, 'oddFooter').firstOrNull?.innerText;
  final right = footer == null ? null : RegExp(r'&R(.*?)(?=&[LC]|$)').firstMatch(footer)?.group(1);

  return XlsxLayout(
    colWidths: colWidths,
    defaultColWidth: double.tryParse(fmt?.getAttribute('defaultColWidth') ?? '') ?? 8.43,
    hiddenCols: hiddenCols,
    rowHeights: rowHeights,
    defaultRowHeight: double.tryParse(fmt?.getAttribute('defaultRowHeight') ?? '') ?? 15,
    hiddenRows: hiddenRows,
    cells: cells,
    merges: merges,
    styles: styles,
    marginLeft: inch('left', 0.7),
    marginRight: inch('right', 0.7),
    marginTop: inch('top', 0.75),
    marginBottom: inch('bottom', 0.75),
    horizontalCentered: _els(sheet, 'printOptions').firstOrNull?.getAttribute('horizontalCentered') == '1',
    footerRight: right,
  );
}
