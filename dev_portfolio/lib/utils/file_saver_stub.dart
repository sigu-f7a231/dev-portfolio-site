// lib/utils/file_saver_stub.dart
//
// Web 以外（flutter test の VM）用の代わりの実装。file_saver.dart から自動で選ばれる。
// 保存先がないので、保存した扱い（downloaded）にする。中身は [lastSaved] に残す（テストで確かめる用）。
import 'dart:convert';
import 'dart:typed_data';

import 'file_saver_types.dart';

class FileSaver {
  FileSaver._();

  /// 最後に保存したもの（テスト用。Web の実装にはない）
  static ({String fileName, Uint8List bytes, String mimeType, List<String> extensions})? lastSaved;

  static Future<FileSaveResult> saveTextAs({
    required String fileName,
    required String text,
    required String description,
    required String mimeType,
    required List<String> extensions,
  }) async {
    lastSaved = (
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(text)),
      mimeType: mimeType,
      extensions: extensions,
    );
    return FileSaveResult.downloaded;
  }

  static Future<FileSaveResult> saveBytesAs({
    required String fileName,
    required Uint8List bytes,
    required String description,
    required String mimeType,
    required List<String> extensions,
  }) async {
    lastSaved = (fileName: fileName, bytes: bytes, mimeType: mimeType, extensions: extensions);
    return FileSaveResult.downloaded;
  }

  /// 先に保存先を選んでから [make] で中身を作る（Web と同じ順。ここでは作って [lastSaved] に残す）
  static Future<FileSaveResult> saveGeneratedBytesAs({
    required String fileName,
    required String description,
    required String mimeType,
    required List<String> extensions,
    required Future<Uint8List> Function() make,
  }) async {
    final bytes = await make();
    lastSaved = (fileName: fileName, bytes: bytes, mimeType: mimeType, extensions: extensions);
    return FileSaveResult.downloaded;
  }
}
