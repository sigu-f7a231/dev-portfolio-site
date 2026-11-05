// lib/utils/browser/browser_web.dart
//
// Web 用の実装（package:web）。browser.dart から自動で選ばれる。
import 'dart:js_interop';

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

/// ブラウザの拡大・縮小のキー（⌘ / Ctrl ＋ ＋ − 0）を止める（アプリ側の拡大・縮小だけを効かせる）
/// - キー操作そのものはアプリにも届く（preventDefault だけ。伝わるのは止めない）
/// - 返した関数を呼ぶと元に戻す（ダイアログを閉じたとき）
void Function() blockBrowserZoomKeys() {
  const keys = {'+', '-', '_', '=', ';', '0'};
  const codes = {'Minus', 'Equal', 'Semicolon', 'Digit0', 'Numpad0', 'NumpadAdd', 'NumpadSubtract'};
  final listener = ((web.KeyboardEvent e) {
    if (!(e.ctrlKey || e.metaKey)) return;
    if (keys.contains(e.key) || codes.contains(e.code)) e.preventDefault();
  }).toJS;
  // 先に受け取る（capture）ので、ブラウザの処理より前に止められる
  web.window.addEventListener('keydown', listener, true.toJS);
  return () => web.window.removeEventListener('keydown', listener, true.toJS);
}
