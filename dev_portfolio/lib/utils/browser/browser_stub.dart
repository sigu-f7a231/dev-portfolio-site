// lib/utils/browser/browser_stub.dart
//
// Web 以外（flutter test の VM）用の代わりの実装。browser.dart から自動で選ばれる。
// sessionStorage はメモリ上の Map で代用する。
import 'package:flutter/foundation.dart';

class SessionStore {
  SessionStore._();

  static final Map<String, String> _values = {};

  static String? read(String key) => _values[key];

  static void write(String key, String value) => _values[key] = value;

  static void remove(String key) => _values.remove(key);

  /// テストの前後で中身を空にする
  @visibleForTesting
  static void clear() => _values.clear();
}

/// Web 以外では送り先がないので何もしない
void dispatchBrowserEvent(String name) {}

/// Web 以外ではブラウザの拡大・縮小がないので何もしない
void Function() blockBrowserZoomKeys() => () {};
