// lib/utils/file_saver_stub.dart
//
// Web 以外（flutter test の VM）用の代わりの実装。file_saver.dart から自動で選ばれる。
// 保存先がないので、保存した扱い（downloaded）にして中身は捨てる。
import 'dart:typed_data';

import 'file_saver_types.dart';

class FileSaver {
  FileSaver._();

  static Future<FileSaveResult> saveTextAs({
    required String fileName,
    required String text,
    required String description,
    required String mimeType,
    required List<String> extensions,
  }) async =>
      FileSaveResult.downloaded;

  static Future<FileSaveResult> saveBytesAs({
    required String fileName,
    required Uint8List bytes,
    required String description,
    required String mimeType,
    required List<String> extensions,
  }) async =>
      FileSaveResult.downloaded;
}
