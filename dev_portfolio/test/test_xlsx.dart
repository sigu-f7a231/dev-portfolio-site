// テスト用：小さな .xlsx を作る（セルはすべて文字。キーは「A1」などのセル番地）
// 書式（styles.xml）は入れない。読み込み（convertSkillSheet）のテストに使う
//
// ※ ファイル名が _test.dart で終わらないので、これ自体はテストとして実行されない
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

Uint8List testXlsx(Map<String, String> cells) {
  String esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  final rows = <int, List<String>>{};
  for (final e in cells.entries) {
    final row = int.parse(RegExp(r'\d+').firstMatch(e.key)!.group(0)!);
    (rows[row] ??= []).add(
      '<c r="${e.key}" t="inlineStr"><is><t xml:space="preserve">${esc(e.value)}</t></is></c>',
    );
  }
  final sortedRows = rows.keys.toList()..sort();
  final sheet = '<?xml version="1.0" encoding="UTF-8"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>'
      '${sortedRows.map((r) => '<row r="$r">${rows[r]!.join()}</row>').join()}'
      '</sheetData></worksheet>';
  const workbook = '<?xml version="1.0" encoding="UTF-8"?>'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets></workbook>';
  const rels = '<?xml version="1.0" encoding="UTF-8"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
      'Target="worksheets/sheet1.xml"/></Relationships>';

  final archive = Archive();
  for (final (name, text) in [
    ('xl/workbook.xml', workbook),
    ('xl/_rels/workbook.xml.rels', rels),
    ('xl/worksheets/sheet1.xml', sheet),
  ]) {
    final bytes = utf8.encode(text);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
