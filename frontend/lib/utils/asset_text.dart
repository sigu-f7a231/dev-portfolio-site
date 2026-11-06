// lib/utils/asset_text.dart
//
// アセット（テンプレート・サンプル）の文字列・バイト列を読む入口
// - アプリでは rootBundle.loadString / rootBundle.load
// - テストでは差し替える（test/test_assets.dart の useFileAssets）
//   testWidgets の仮の時間（FakeAsync）の中では rootBundle の読み込みが終わらないことがあり、
//   テンプレートのコピーや、今の内容との比較（上書きの確認）が止まってしまうため
//
// アセットを読むときは rootBundle を直接使わず、ここの loadAssetText / loadAssetBytes を使う。
import 'package:flutter/services.dart';

typedef AssetTextLoader = Future<String> Function(String path);
typedef AssetBytesLoader = Future<Uint8List> Function(String path);

AssetTextLoader loadAssetText = _rootBundleLoader;

/// Excel のテンプレートなど、文字ではないアセット
AssetBytesLoader loadAssetBytes = _rootBundleBytesLoader;

Future<String> _rootBundleLoader(String path) => rootBundle.loadString(path);

Future<Uint8List> _rootBundleBytesLoader(String path) async {
  final data = await rootBundle.load(path);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

/// テストのあとなどに、アプリの読み方（rootBundle）に戻す
void resetAssetTextLoader() {
  loadAssetText = _rootBundleLoader;
  loadAssetBytes = _rootBundleBytesLoader;
}
