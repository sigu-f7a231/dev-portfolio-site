// lib/utils/asset_text.dart
//
// アセット（テンプレート・サンプル）の文字列を読む入口
// - アプリでは rootBundle.loadString
// - テストでは差し替える（test/test_assets.dart の useFileAssets）
//   testWidgets の仮の時間（FakeAsync）の中では rootBundle の読み込みが終わらないことがあり、
//   テンプレートのコピーや、今の内容との比較（上書きの確認）が止まってしまうため
//
// アセットを読むときは rootBundle を直接使わず、ここの loadAssetText を使う。
import 'package:flutter/services.dart';

typedef AssetTextLoader = Future<String> Function(String path);

AssetTextLoader loadAssetText = _rootBundleLoader;

Future<String> _rootBundleLoader(String path) => rootBundle.loadString(path);

/// テストのあとなどに、アプリの読み方（rootBundle）に戻す
void resetAssetTextLoader() => loadAssetText = _rootBundleLoader;
