// lib/utils/skill_sheet_pdf.dart
//
// スキルシート（書き込んだ .xlsx）を、Excel の見た目のまま PDF にする（ヘッダーの［ダウンロード］→ PDF）
// - 列の幅・行の高さ・結合・罫線（太さ・色・破線）・塗り・文字（大きさ・太字・下線・色）・寄せ方・折り返し・
//   縮小して全体を表示、をシートの設定のとおりに描く
// - 用紙は A4 縦、余白はシートの設定。Excel の「シートを 1 ページの幅に合わせる」と同じく、幅に合わせて縮める
//   （横の中央寄せの指定があれば中央に）。ページは行の切れ目で分け、1 行がページより高いときだけ行の途中で分ける
// - フッターの右（&P＝ページ番号）も入れる
// - 文字は IPA P ゴシック（assets/fonts/ipagp.ttf。テンプレートの MS P ゴシックとほぼ同じ字の幅）
//
// Flutter に依存しない（pdf パッケージは Dart だけで動く）。
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import 'xlsx_layout.dart';

/// PDF の日本語フォント（アセット）
const String skillSheetPdfFontAsset = 'assets/fonts/ipagp.ttf';

/// [xlsx]（skill_sheet_writer.dart で書き込んだもの）を PDF にする。[font] は TrueType のフォント
Future<Uint8List> skillSheetPdf(Uint8List xlsx, ByteData font) async {
  final layout = readXlsxLayout(xlsx);
  final doc = PdfDocument();
  final ttf = PdfTtfFont(doc, font);
  _SheetPainter(layout, doc, ttf).paint();
  return doc.save();
}

/// PDF の紙の上の配置（縮める倍率・左端・ページの分け方）。描くのとは別にして、テストで確かめられるようにする
class SkillSheetPdfGeometry {
  final XlsxLayout layout;

  SkillSheetPdfGeometry(this.layout);

  static const PdfPageFormat paper = PdfPageFormat.a4;

  late final (int, int) range = layout.usedRange;

  /// 列・行の左端・上端（シートの pt）。[c] 列の左端は xs[c - 1]、右端は xs[c]
  late final List<double> xs = _edges(range.$2, layout.colWidthPt);
  late final List<double> ys = _edges(range.$1, layout.rowHeightPt);

  static List<double> _edges(int n, double Function(int) size) {
    final e = [0.0];
    for (var i = 1; i <= n; i++) {
      e.add(e.last + size(i));
    }
    return e;
  }

  late final double printableW = paper.width - layout.marginLeft - layout.marginRight;
  late final double printableH = paper.height - layout.marginTop - layout.marginBottom;

  /// 幅に合わせて縮める倍率（入るなら 1。大きくはしない）
  late final double scale = math.min(1, printableW / math.max(xs.last, 1));

  /// シートの左端の紙の上の位置（横の中央寄せなら中央に）
  late final double offsetX =
      layout.marginLeft + (layout.horizontalCentered ? (printableW - xs.last * scale) / 2 : 0);

  /// ページの範囲（シートの上からの pt）。行の切れ目で分け、1 行がページより高いときだけ行の途中で分ける
  late final List<(double, double)> pages = () {
    final pageH = printableH / scale;
    final result = <(double, double)>[];
    var y0 = 0.0;
    final total = ys.last;
    while (y0 < total - 0.01) {
      final limit = y0 + pageH;
      var y1 = limit;
      // 入りきる最後の行の下端
      for (var r = 1; r < ys.length; r++) {
        if (ys[r] > y0 + 0.01 && ys[r] <= limit + 0.01) y1 = ys[r];
      }
      if (y1 <= y0 + 0.01) y1 = limit; // 1 行がページより高い
      if (y1 > total) y1 = total;
      result.add((y0, y1));
      y0 = y1;
    }
    return result.isEmpty ? [(0.0, 0.0)] : result;
  }();
}

/// フッターの右の文字（「&P」はページ番号、「&N」は総ページ数。「&P/」のように総ページ数がなければ足す）
/// ほかの「&」の指定（フォントなど）は外す。なければ null
String? skillSheetFooterText(String? footer, int page, int total) {
  if (footer == null || footer.isEmpty) return null;
  // 「&"フォント名"」「&8」（文字の大きさ）「&B」などの指定は外し、&P・&N だけ数字にする
  var text = footer.replaceAllMapped(RegExp(r'&"[^"]*"|&\d+|&[A-Za-z&]'), (m) => switch (m[0]) {
        '&P' => '$page',
        '&N' => '$total',
        '&&' => '&',
        _ => '',
      });
  if (text.endsWith('/')) text = '$text$total';
  return text.isEmpty ? null : text;
}

/// 描かずに幅だけ空ける文字（半角・全角スペース、タブなど）
bool isSkillSheetBlank(String ch) => ch.trim().isEmpty;

/// 行の先頭に来てはいけない文字（句読点・閉じかっこ・小さい仮名・長音など。Excel の禁則処理と同じ考え方）
const String _noLineStart = '、。，．,.・：；:;！？!?）)」』】〕〉》］]｝}〙〗＞>ー‐－〜～ゝゞヽヾぁぃぅぇぉっゃゅょゎゕゖァィゥェォッャュョヮヵヶ％%’”';

/// 行の最後に来てはいけない文字（開きかっこなど）
const String _noLineEnd = '（(「『【〔〈《［[｛{〘〖＜<‘“';

/// 1 段落を幅 [max] で折り返す。[widthOf] は 1 文字の幅
/// - 英数字の単語はなるべく途中で切らない（空白で切る）
/// - 禁則処理：「、」「。」「）」などは行の先頭に置かず前の行の末尾に付ける（ぶら下げ）。
///   「（」「「」などは行の最後に置かず次の行へ送る
List<String> skillSheetWrap(String para, double max, double Function(String ch) widthOf) {
  if (para.isEmpty) return [''];
  final chars = para.runes.map(String.fromCharCode).toList();
  final lines = <String>[];
  var start = 0;
  var width = 0.0;
  int? lastSpace;
  for (var i = 0; i < chars.length; i++) {
    final cw = widthOf(chars[i]);
    if (width + cw > max && i > start) {
      if (_noLineStart.contains(chars[i])) {
        // 行の先頭に置けない文字は、はみ出してもこの行に付ける
        width += cw;
        continue;
      }
      var cut = (lastSpace != null && lastSpace > start) ? lastSpace + 1 : i;
      // 行の最後に開きかっこが来るなら、それも次の行へ
      while (cut - 1 > start && _noLineEnd.contains(chars[cut - 1])) {
        cut--;
      }
      lines.add(chars.sublist(start, cut).join().trimRight());
      start = cut;
      width = 0;
      for (var k = start; k < i; k++) {
        width += widthOf(chars[k]);
      }
      lastSpace = null;
    }
    if (chars[i] == ' ') lastSpace = i;
    width += cw;
  }
  lines.add(chars.sublist(start).join());
  return lines;
}

class _SheetPainter {
  final XlsxLayout layout;
  final PdfDocument doc;
  final PdfTtfFont font;

  _SheetPainter(this.layout, this.doc, this.font);

  late final SkillSheetPdfGeometry _geo = SkillSheetPdfGeometry(layout);

  static const PdfPageFormat _paper = SkillSheetPdfGeometry.paper;

  /// セルの中の文字の左右・上下の余白（pt。シートの大きさで）
  static const double _padX = 2;
  static const double _padY = 1;

  /// 1 行の高さ（文字の大きさの何倍か）・文字の上端から字の基準線まで（同じく）
  static const double _lineHeight = 1.25;
  static const double _ascent = 0.88;

  int get _maxR => _geo.range.$1;
  int get _maxC => _geo.range.$2;
  List<double> get _xs => _geo.xs;
  List<double> get _ys => _geo.ys;

  /// 結合の左上 →（範囲）、結合に入るほかのセル
  late final Map<(int, int), XlsxMerge> _mergeAt = {
    for (final m in layout.merges) (m.r1, m.c1): m,
  };
  late final Set<(int, int)> _covered = {
    for (final m in layout.merges)
      for (var r = m.r1; r <= m.r2; r++)
        for (var c = m.c1; c <= m.c2; c++)
          if (r != m.r1 || c != m.c1) (r, c),
  };
  XlsxMerge? _mergeOf(int r, int c) => layout.merges.where((m) => m.contains(r, c)).firstOrNull;

  double get _scale => _geo.scale;
  double get _offsetX => _geo.offsetX;
  List<(double, double)> _pages() => _geo.pages;

  void paint() {
    final pages = _pages();
    for (var i = 0; i < pages.length; i++) {
      final (y0, y1) = pages[i];
      final page = PdfPage(doc, pageFormat: _paper);
      final g = page.getGraphics();
      double px(double x) => _offsetX + x * _scale;
      double py(double y) => _paper.height - layout.marginTop - (y - y0) * _scale;

      g.saveContext();
      g.drawRect(px(0), py(y1), _xs.last * _scale, (y1 - y0) * _scale);
      g.clipPath();

      // このページにかかる行
      final rows = [
        for (var r = 1; r <= _maxR; r++)
          if (_ys[r] > y0 && _ys[r - 1] < y1) r,
      ];
      // 結合がページの上にはみ出しているものも描く（左上の行がこのページより上にある）
      final cells = <(int, int)>{
        for (final r in rows)
          for (var c = 1; c <= _maxC; c++) _covered.contains((r, c)) ? _topLeft(r, c) : (r, c),
      };

      _paintFills(g, cells, px, py);
      _paintBorders(g, rows, px, py);
      _paintTexts(g, cells, px, py);
      g.restoreContext();

      _paintFooter(g, i + 1, pages.length);
    }
  }

  (int, int) _topLeft(int r, int c) {
    final m = _mergeOf(r, c);
    return m == null ? (r, c) : (m.r1, m.c1);
  }

  /// セル（結合なら全体）の範囲（シートの pt）：左・上・右・下
  (double, double, double, double) _rect(int r, int c) {
    final m = _mergeAt[(r, c)];
    final r2 = math.min(m?.r2 ?? r, _maxR);
    final c2 = math.min(m?.c2 ?? c, _maxC);
    return (_xs[c - 1], _ys[r - 1], _xs[c2], _ys[r2]);
  }

  void _paintFills(PdfGraphics g, Set<(int, int)> cells, double Function(double) px,
      double Function(double) py) {
    for (final (r, c) in cells) {
      final fill = layout.styleAt(r, c).fill;
      if (fill == null) continue;
      final (x1, y1, x2, y2) = _rect(r, c);
      if (x2 <= x1 || y2 <= y1) continue;
      g.setFillColor(PdfColor.fromInt(fill));
      g.drawRect(px(x1), py(y2), (x2 - x1) * _scale, (y2 - y1) * _scale);
      g.fillPath();
    }
  }

  void _paintBorders(PdfGraphics g, List<int> rows, double Function(double) px,
      double Function(double) py) {
    void line(XlsxBorderSide side, double x1, double y1, double x2, double y2) {
      g.setStrokeColor(PdfColor.fromInt(side.color));
      g.setLineWidth(math.max(side.width * _scale, 0.25));
      g.setLineDashPattern(side.dash);
      g.moveTo(px(x1), py(y1));
      g.lineTo(px(x2), py(y2));
      g.strokePath();
      if (side.style == 'double') {
        // 二重線：少しずらしてもう 1 本
        final d = 1.0;
        final vertical = x1 == x2;
        g.moveTo(px(x1 + (vertical ? d : 0)), py(y1 + (vertical ? 0 : d)));
        g.lineTo(px(x2 + (vertical ? d : 0)), py(y2 + (vertical ? 0 : d)));
        g.strokePath();
      }
    }

    // 結合の中の境目は描かない（Excel と同じ）
    bool inside(int r, int c, int r2, int c2) {
      final m = _mergeOf(r, c);
      return m != null && m.contains(r2, c2);
    }

    for (final r in rows) {
      for (var c = 1; c <= _maxC; c++) {
        if (layout.colWidthPt(c) == 0 || layout.rowHeightPt(r) == 0) continue;
        final s = layout.styleAt(r, c);
        final x1 = _xs[c - 1], x2 = _xs[c], y1 = _ys[r - 1], y2 = _ys[r];
        if (s.top != null && !inside(r, c, r - 1, c)) line(s.top!, x1, y1, x2, y1);
        if (s.bottom != null && !inside(r, c, r + 1, c)) line(s.bottom!, x1, y2, x2, y2);
        if (s.left != null && !inside(r, c, r, c - 1)) line(s.left!, x1, y1, x1, y2);
        if (s.right != null && !inside(r, c, r, c + 1)) line(s.right!, x2, y1, x2, y2);
      }
    }
    g.setLineDashPattern();
  }

  double _width(String s, double size) {
    var w = 0.0;
    for (final rune in s.runes) {
      w += font.glyphMetrics(rune).advanceWidth;
    }
    return w * size;
  }

  /// 幅 [max] で折り返す（skillSheetWrap。日本語の禁則処理あり）
  List<String> _wrap(String para, double max, double size) =>
      skillSheetWrap(para, max, (ch) => _width(ch, size));

  void _paintTexts(PdfGraphics g, Set<(int, int)> cells, double Function(double) px,
      double Function(double) py) {
    for (final (r, c) in cells) {
      final cell = layout.cells[(r, c)];
      if (cell == null || cell.value.trim().isEmpty) continue;
      final s = layout.styleAt(r, c);
      var (x1, y1, x2, y2) = _rect(r, c);

      final isNumber = double.tryParse(cell.value.trim()) != null;
      final h = s.hAlign == 'general' ? (isNumber ? 'right' : 'left') : s.hAlign;

      // 折り返さない左寄せの文字は、右の空いたセルにはみ出して見える（Excel と同じ）
      var clipRight = x2;
      if (!s.wrap && h == 'left' && !_mergeAt.containsKey((r, c))) {
        for (var cc = c + 1; cc <= _maxC; cc++) {
          final next = layout.cells[(r, cc)];
          if (_covered.contains((r, cc)) || _mergeAt.containsKey((r, cc)) ||
              (next != null && next.value.trim().isNotEmpty)) {
            break;
          }
          clipRight = _xs[cc];
        }
      }

      final inner = (x2 - x1) - 2 * _padX;
      var size = s.fontSize;
      final paras = s.wrap ? cell.value.split('\n') : [cell.value.replaceAll('\n', ' ')];
      var lines = s.wrap
          ? [for (final p in paras) ..._wrap(p, inner, size)]
          : paras;
      if (s.shrink && !s.wrap) {
        final w = _width(lines.first, size);
        if (w > inner && w > 0) size = size * inner / w;
      }

      final lh = size * _lineHeight;
      final total = lines.length * lh;
      final top = switch (s.vAlign) {
        'top' => y1 + _padY,
        'center' || 'distributed' || 'justify' => y1 + ((y2 - y1) - total) / 2,
        _ => y2 - _padY - total,
      };

      g.saveContext();
      g.drawRect(px(x1), py(y2), (clipRight - x1) * _scale, (y2 - y1) * _scale);
      g.clipPath();
      final color = PdfColor.fromInt(s.fontColor);
      g.setFillColor(color);
      g.setStrokeColor(color);
      g.setLineWidth(size * 0.04 * _scale);
      g.setLineDashPattern();
      for (var i = 0; i < lines.length; i++) {
        final text = lines[i];
        if (text.isEmpty) continue;
        final w = _width(text, size);
        final x = switch (h) {
          'center' || 'centerContinuous' || 'distributed' => x1 + ((x2 - x1) - w) / 2,
          'right' => x2 - _padX - w,
          _ => x1 + _padX,
        };
        final baseline = top + i * lh + size * _ascent;
        // 空白（全角スペースなど）は描かずに幅だけ空ける（フォントによっては全角スペースが「、」の形で出るため）
        var cx = x;
        final run = StringBuffer();
        var runX = cx;
        void flush() {
          if (run.isEmpty) return;
          g.drawString(
            font,
            size * _scale,
            run.toString(),
            px(runX),
            py(baseline),
            // 太字はフォントがないので、文字の輪郭も塗って太く見せる
            mode: s.bold ? PdfTextRenderingMode.fillAndStroke : PdfTextRenderingMode.fill,
          );
          run.clear();
        }

        for (final ch in text.runes.map(String.fromCharCode)) {
          final cw = _width(ch, size);
          if (isSkillSheetBlank(ch)) {
            flush();
          } else {
            if (run.isEmpty) runX = cx;
            run.write(ch);
          }
          cx += cw;
        }
        flush();
        if (s.underline) {
          g.setLineWidth(math.max(size * 0.06 * _scale, 0.3));
          g.moveTo(px(x), py(baseline + size * 0.12));
          g.lineTo(px(x + w), py(baseline + size * 0.12));
          g.strokePath();
          g.setLineWidth(size * 0.04 * _scale);
        }
      }
      g.restoreContext();
    }
  }

  /// フッターの右（「&P」はページ番号、「&N」は総ページ数。「&P/」のように総ページ数がなければ足す）
  void _paintFooter(PdfGraphics g, int page, int total) {
    final text = skillSheetFooterText(layout.footerRight, page, total);
    if (text == null) return;
    const size = 8.0;
    final w = _width(text, size);
    g.setFillColor(PdfColors.black);
    g.drawString(font, size, text, _paper.width - layout.marginRight - w, layout.marginBottom / 2);
  }
}
