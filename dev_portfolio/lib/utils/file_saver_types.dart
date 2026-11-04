// lib/utils/file_saver_types.dart
//
// FileSaver の結果（Web 用・テスト用の実装で共通）

enum FileSaveResult {
  /// 保存ダイアログで保存した
  saved,

  /// 保存ダイアログでキャンセルした
  cancelled,

  /// 保存ダイアログが使えないブラウザなので、通常のダウンロードにした
  downloaded,
}
