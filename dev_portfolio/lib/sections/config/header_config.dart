import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';

// 色は lib/theme/app_colors.dart（header* / nav*）、見た目は lib/theme/app_styles.dart で管理
class HeaderConfig {
  // ブレークポイント
  static const double mobileBreakpoint = 600;

  /// ナビの文字まで出す幅（これ未満の PC 幅ではアイコンだけ）
  static const double navLabelBreakpoint = 900;

  /// タイトル（DevPortfolio）を出す幅（これ未満はナビとアクションだけ）
  static const double titleBreakpoint = 760;

  /// アップロードボタンに「Work / Private」の文字まで出す幅（これ未満はアイコンだけ）
  static const double uploadLabelBreakpoint = 1100;
  static const double uploadGap = 8;

  // Desktop 用（M3 の Small top app bar：高さ 64）
  static const double desktopHeight = 64;
  static const EdgeInsets desktopPadding = EdgeInsets.symmetric(horizontal: AppSizes.space24);

  /// タイトルとナビの間・グループ間
  static const double titleNavGap = AppSizes.space24;
  static const double navGap = AppSizes.space4;
  static const double actionsDividerIndent = 20;

  /// ナビボタン（丸いインジケーター）
  static const EdgeInsets navPadding =
      EdgeInsets.symmetric(horizontal: AppSizes.space16, vertical: AppSizes.space10);
  static const double navIconSize = 20;

  /// どのセクションを「表示中」とみなすか：画面の上からこの割合の位置にあるセクション
  static const double activeSectionLine = 0.3;
}
