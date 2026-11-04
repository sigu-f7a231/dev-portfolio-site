// lib/utils/file_saver.dart
//
// テキストファイルを「名前を付けて保存」する（入口）
// - Web：file_saver_web.dart（Chrome / Edge は保存ダイアログ、そのほかは通常のダウンロード）
// - flutter test（VM）：file_saver_stub.dart（何もしない）
// を自動で切り替える。これで保存ボタンのある画面もテストから開ける。
export 'file_saver_types.dart';
export 'file_saver_stub.dart' if (dart.library.js_interop) 'file_saver_web.dart';
