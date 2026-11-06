// lib/utils/app_ready.dart
//
// 起動時のローディング表示（web/index.html）を消すタイミングを、アプリ側から知らせる。
// 「Flutter が最初の 1 フレームを描いた瞬間」ではまだデータ読み込みや描画の途中なので、
// 1. 表示に使う YAML（Work / Private）を先に読み込み
// 2. 画面が描かれ、データが入った状態で描き直されるまで待ってから
// 3. ブラウザに 'app-ready' イベントを送る（index.html はこれを受けて、最低表示時間を守りつつ消す）
import 'browser/browser.dart'; // ブラウザへのイベント送信（Web は package:web）
import 'package:flutter/widgets.dart';
import 'work_yaml_loader.dart';
import 'private_yaml_loader.dart';
import 'profile_store.dart';
import '../constants/app_sizes.dart';

class AppReady {
  AppReady._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

  /// index.html と合わせたイベント名
  static const String eventName = 'app-ready';

  /// 最初の表示に必要なデータを先に読み込む（失敗しても画面は出す）
  static Future<void> preload() async {
    try {
      await Future.wait([
        WorkYamlLoader.loadYamlString(),
        PrivateYamlLoader.loadYamlString(),
        ProfileStore.instance.load(), // Home / About のプロフィール
      ]);
    } catch (_) {
      // 読み込みに失敗した場合は、各セクションが空の表示になる
    }
  }

  /// 最初の描画と、データが入った状態での描き直しが終わったら 'app-ready' を送る
  static void notifyWhenSettled() {
    final binding = WidgetsBinding.instance;
    Future<void>(() async {
      for (var i = 0; i < AppSizes.settleFrames; i++) {
        await binding.endOfFrame;
      }
      dispatchBrowserEvent(eventName);
    });
  }
}
