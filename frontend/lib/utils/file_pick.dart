// lib/utils/file_pick.dart
//
// ファイルを選ぶ入口（ファイル選択のダイアログ）
// - アプリでは file_picker（FilePicker.platform.pickFiles）
// - テストでは差し替える（pickFile に関数を入れ、終わったら resetFilePicker）。
//   選んだ・キャンセルした・拡張子が違う・中身が壊れている、を画面のテストから確かめるため
//
// ファイルを選ぶときは FilePicker を直接使わず、ここの pickFile を使う（asset_text.dart と同じ考え方）。
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// 選んだファイル（名前と中身。中身が読めなければ bytes は null）
typedef PickedFile = ({String name, Uint8List? bytes});

/// [allowedExtensions]（「.」なし）のファイルだけを選べるダイアログを開く。キャンセルなら null
typedef FilePickFunction = Future<PickedFile?> Function(List<String> allowedExtensions);

FilePickFunction pickFile = _pickWithFilePicker;

/// テストのあとなどに、アプリの選び方（file_picker）に戻す
void resetFilePicker() => pickFile = _pickWithFilePicker;

// ブラウザのファイル選択ダイアログを開くだけ（テストでは pickFile を差し替えるので通らない）
// coverage:ignore-start
Future<PickedFile?> _pickWithFilePicker(List<String> allowedExtensions) async {
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    withData: true,
  );
  final file = picked?.files.single;
  return file == null ? null : (name: file.name, bytes: file.bytes);
}
// coverage:ignore-end
