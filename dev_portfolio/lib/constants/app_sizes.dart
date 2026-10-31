// lib/constants/app_sizes.dart
//
// ============================================================
// 余白・サイズ・時間などの数値（ウィジェットに直接数値を書かず、ここから参照する）
// ============================================================
// - 色は lib/theme/app_colors.dart、文字スタイル・角丸は lib/theme/app_styles.dart。
// - セクション固有のまとまった設定（グラフ半径・カード幅など）は sections/config/ にある。
import 'package:flutter/material.dart';

class AppSizes {
  AppSizes._();

  // ----------------------------------------------------------
  // 余白のスケール（SizedBox / EdgeInsets / Wrap の spacing などに使う）
  // ----------------------------------------------------------
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space36 = 36;
  static const double space40 = 40;
  static const double space48 = 48;

  // ----------------------------------------------------------
  // アニメーション・時間
  // ----------------------------------------------------------
  /// ナビゲーションでセクションへスクロールする時間
  static const Duration scrollDuration = Duration(milliseconds: 500);

  /// フィルター適用時に Work/Private 切替を少し下げるアニメーション
  static const Duration filterPaddingDuration = Duration(milliseconds: 150);

  /// フィルターパネルの開閉
  static const Duration filterPanelDuration = Duration(milliseconds: 200);

  /// ダウンロード用の一時 URL を解放するまでの待ち時間
  static const Duration downloadUrlRevokeDelay = Duration(seconds: 1);

  // ----------------------------------------------------------
  // セグメント（Work/Private・List/Collection・Bar/Pie で共通。lib/widgets/app_segment.dart）
  // ----------------------------------------------------------
  /// 外枠と中のボタンの間
  static const EdgeInsets segmentTrackPadding = EdgeInsets.all(space4);

  /// 文字のボタン（Work / Private）
  static const EdgeInsets segmentItemPadding =
      EdgeInsets.symmetric(horizontal: space16, vertical: space8);

  /// アイコンのボタン（List / Collection・Bar / Pie）
  static const EdgeInsets iconSegmentItemPadding =
      EdgeInsets.symmetric(horizontal: space12, vertical: space8);
  static const double iconSegmentSize = 20;

  // ----------------------------------------------------------
  // Drawer
  // ----------------------------------------------------------
  static const double drawerTitleFontSize = 24;

  // ----------------------------------------------------------
  // ダイアログ（YAML アップロード / 書き方の説明）
  // ----------------------------------------------------------
  static const double uploadDialogWidth = 450;
  static const double helpDialogWidth = 560;

  /// ボタン内のローディング表示
  static const double buttonLoadingSize = 16;
  static const double buttonLoadingStrokeWidth = 2;

  // ----------------------------------------------------------
  // Projects
  // ----------------------------------------------------------
  /// 一覧エリアの高さ（画面の高さに対する割合）
  static const double projectsListHeightRatio = 0.7;

  /// ページネーションバーの高さ
  static const double paginationBarHeight = 60;

  /// 詳細モーダルの項目の文字サイズ
  static const double modalFieldFontSize = 14;
  static const double modalTitleFontSize = 18;

  // ----------------------------------------------------------
  // Skills
  // ----------------------------------------------------------
  /// グラフに出す上位件数（それ以降は「その他」にまとめる）
  static const int chartTopN = 10;

  /// （未使用の SkillsTabs 用）メッセージの文字サイズ
  static const double skillsTabsMessageFontSize = 16;
}
