// lib/utils/browser/browser_web.dart
//
// Web 用の実装（package:web）。browser.dart から自動で選ばれる。
import 'package:web/web.dart' as web;

/// ブラウザの sessionStorage（同じタブの中だけで保持。タブを閉じると消える）
class SessionStore {
  SessionStore._();

  static String? read(String key) => web.window.sessionStorage.getItem(key);

  static void write(String key, String value) =>
      web.window.sessionStorage.setItem(key, value);

  static void remove(String key) => web.window.sessionStorage.removeItem(key);
}

/// ブラウザ（web/index.html）にイベントを送る
void dispatchBrowserEvent(String name) {
  web.window.dispatchEvent(web.Event(name));
}
