// lib/utils/browser/browser.dart
//
// ブラウザの機能（sessionStorage・イベント送信）の入口
// - Web では package:web（dart:html の後継）を使う実装
// - flutter test（VM）ではメモリ上で動く代わりの実装
// を自動で切り替える。ほかのファイルは dart:html / package:web を直接 import せず、ここを使う。
export 'browser_stub.dart' if (dart.library.js_interop) 'browser_web.dart';
