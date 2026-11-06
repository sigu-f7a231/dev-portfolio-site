// lib/utils/xlsx_reader.dart
//
// Excel（.xlsx / .xlsm）のセルの値を読む最小限の読み取り
// - .xlsx は zip の中に XML が入った形式。zip を開き（package:archive）、XML を読む（package:xml）
// - 読むのは「セルに表示される文字」だけ（書式・結合・数式の計算はしない。数式は保存されている計算結果を読む）
// - 共有文字列（sharedStrings.xml）のふりがな（rPh）は読み飛ばす
//
// Flutter に依存しない（dart run tool/run.dart からも使う）。
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// 読めなかったとき（.xlsx ではない・壊れている）
class XlsxFormatException implements Exception {
  final String message;
  const XlsxFormatException(this.message);

  @override
  String toString() => 'XlsxFormatException: $message';
}

/// 1 枚のシート。行・列は Excel と同じく 1 始まり（A 列 = 1）
class XlsxSheet {
  final String name;

  /// 行 → 列 → 値（空のセルは入れない）
  final Map<int, Map<int, String>> rows;

  const XlsxSheet(this.name, this.rows);

  String? cell(int row, int col) => rows[row]?[col];

  /// 値のあるセルを上の行から、同じ行は左から
  Iterable<XlsxCell> get cells sync* {
    final rowKeys = rows.keys.toList()..sort();
    for (final r in rowKeys) {
      final cols = rows[r]!.keys.toList()..sort();
      for (final c in cols) {
        yield XlsxCell(r, c, rows[r]![c]!);
      }
    }
  }

  int get maxRow => rows.keys.fold(0, (a, b) => a > b ? a : b);
}

class XlsxCell {
  final int row;
  final int col;
  final String value;

  const XlsxCell(this.row, this.col, this.value);
}

/// .xlsx のバイト列から、すべてのシートを読む（ブックの並び順）
List<XlsxSheet> readXlsx(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (e) {
    throw XlsxFormatException('zip として開けません（$e）');
  }

  String? text(String path) {
    final file = archive.findFile(path);
    if (file == null) return null;
    return utf8.decode(file.content, allowMalformed: true);
  }

  XmlDocument? xml(String path) {
    final t = text(path);
    if (t == null) return null;
    try {
      return XmlDocument.parse(t);
    } catch (e) {
      throw XlsxFormatException('$path を読めません（$e）');
    }
  }

  final workbook = xml('xl/workbook.xml');
  if (workbook == null) throw const XlsxFormatException('xl/workbook.xml がありません');

  final shared = _sharedStrings(xml('xl/sharedStrings.xml'));

  // シート名 → ファイルの場所（xl/_rels/workbook.xml.rels）
  final rels = <String, String>{};
  final relsDoc = xml('xl/_rels/workbook.xml.rels');
  if (relsDoc != null) {
    for (final r in _elements(relsDoc, 'Relationship')) {
      final id = r.getAttribute('Id');
      final target = r.getAttribute('Target');
      if (id == null || target == null) continue;
      rels[id] = target.startsWith('/') ? target.substring(1) : 'xl/$target';
    }
  }

  final sheets = <XlsxSheet>[];
  var index = 0;
  for (final s in _elements(workbook, 'sheet')) {
    index++;
    final name = s.getAttribute('name') ?? 'Sheet$index';
    final relId = s.attributes
        .where((a) => a.name.local == 'id')
        .map((a) => a.value)
        .firstOrNull;
    final path = (relId != null ? rels[relId] : null) ?? 'xl/worksheets/sheet$index.xml';
    final doc = xml(path);
    if (doc == null) continue;
    sheets.add(XlsxSheet(name, _readSheet(doc, shared)));
  }
  if (sheets.isEmpty) throw const XlsxFormatException('シートがありません');
  return sheets;
}

/// 名前空間の接頭辞（x: など）があってもなくても、ローカル名で探す
Iterable<XmlElement> _elements(XmlNode node, String local) =>
    node.descendants.whereType<XmlElement>().where((e) => e.name.local == local);

Iterable<XmlElement> _children(XmlElement node, String local) =>
    node.childElements.where((e) => e.name.local == local);

/// 文字列の要素（`<si>` / `<is>`）の文字。ふりがな（`<rPh>`）は除く
String _richText(XmlElement node) {
  final buffer = StringBuffer();
  for (final t in _elements(node, 't')) {
    final inPhonetic =
        t.ancestors.whereType<XmlElement>().any((a) => a.name.local == 'rPh');
    if (!inPhonetic) buffer.write(t.innerText);
  }
  return buffer.toString();
}

List<String> _sharedStrings(XmlDocument? doc) {
  if (doc == null) return const [];
  return [for (final si in _elements(doc, 'si')) _richText(si)];
}

final _cellRef = RegExp(r'^([A-Za-z]+)(\d+)$');

/// 列の文字（A, B, …, Z, AA, …）→ 1 始まりの番号
int columnNumber(String letters) {
  var n = 0;
  for (final code in letters.toUpperCase().codeUnits) {
    n = n * 26 + (code - 0x40);
  }
  return n;
}

Map<int, Map<int, String>> _readSheet(XmlDocument doc, List<String> shared) {
  final rows = <int, Map<int, String>>{};
  var rowNo = 0;
  for (final row in _elements(doc, 'row')) {
    rowNo = int.tryParse(row.getAttribute('r') ?? '') ?? rowNo + 1;
    var colNo = 0;
    for (final c in _children(row, 'c')) {
      final ref = _cellRef.firstMatch(c.getAttribute('r') ?? '');
      colNo = ref != null ? columnNumber(ref.group(1)!) : colNo + 1;

      final type = c.getAttribute('t');
      final v = _children(c, 'v').firstOrNull?.innerText;
      String? value;
      switch (type) {
        case 's':
          final i = int.tryParse(v ?? '');
          value = i != null && i >= 0 && i < shared.length ? shared[i] : null;
        case 'inlineStr':
          final inline = _children(c, 'is').firstOrNull;
          value = inline == null ? null : _richText(inline);
        case 'b':
          value = v == null ? null : (v == '1' ? 'TRUE' : 'FALSE');
        default: // 数値・数式の結果（str）・エラー（e）
          value = v;
      }
      if (value == null || value.trim().isEmpty) continue;
      (rows[rowNo] ??= {})[colNo] = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    }
  }
  return rows;
}
