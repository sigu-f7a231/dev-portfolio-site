// テスト用：アプリのアセット（テンプレート・サンプル）の読み方を、ファイルをその場で読む方法に差し替える
//
// testWidgets の中は仮の時間（FakeAsync）で動くため、rootBundle の読み込みが終わらないことがあり、
// アセットに頼る処理（テンプレートの保存・コピー、ローダーがサンプルを読む上書きの確認など）が止まってしまう。
// lib/utils/asset_text.dart の loadAssetText / loadAssetBytes を、すぐに結果が出る読み方（SynchronousFuture）に差し替えて防ぐ。
//
// ※ ファイル名が _test.dart で終わらないので、これ自体はテストとして実行されない
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/utils/asset_text.dart';
import 'package:dev_portfolio/utils/data_format.dart';

/// テンプレート（YAML / Markdown）と、複数件のサンプルをすべて
final List<String> allTemplateAssets = [
  for (final kind in DataKind.values)
    for (final format in DataFormat.values) templateAssetPath(kind, format),
  // 複数件まとめて追加するときのサンプル（Work / Private）
  for (final kind in [DataKind.work, DataKind.private])
    for (final format in DataFormat.values) multiSampleAssetPath(kind, format),
];

/// setUpAll で呼ぶ：文字を実際に近い幅で描くため、同梱の日本語フォント（IPA P ゴシック）を既定のフォント（Roboto）として読み込む
/// flutter test の既定のフォントは英字も全角に近い幅で描くので、実際には収まる文字が「はみ出し」になることがある
Future<void> loadAppFont() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = File('assets/fonts/ipagp.ttf').readAsBytesSync();
  final loader = FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// setUp で呼ぶ：アセットをファイルから直接読む（テストのあとはアプリの読み方に戻す）
void useFileAssets() {
  loadAssetText = (path) => SynchronousFuture(File(path).readAsStringSync());
  loadAssetBytes = (path) => SynchronousFuture(File(path).readAsBytesSync());
  addTearDown(resetAssetTextLoader);
}
