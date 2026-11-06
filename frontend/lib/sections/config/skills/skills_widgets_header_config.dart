// lib/sections/config/skills/skills_widgets_header_config.dart
import 'package:flutter/material.dart';
import '../../../constants/app_sizes.dart';

/// Skills のヘッダー・ツールバー・カテゴリ絞り込みの設定
/// 色は lib/theme/app_colors.dart、見た目は lib/theme/app_styles.dart、セグメントのサイズは lib/constants/app_sizes.dart
class SkillsHeaderConfig {
  // セクション全体の余白（Projects と合わせる）
  static const EdgeInsets sectionPadding = EdgeInsets.all(AppSizes.space24);

  /// カテゴリボタン内の「選択中カテゴリ」の最大幅（スマホではみ出さないように）
  static const double currentCategoryMaxWidth = 160;

  // タイトル
  static const double titleFontSize = 28; // M3 headline medium（Projects と同じ）
  static const EdgeInsets titlePadding = EdgeInsets.symmetric(vertical: AppSizes.space8);

  // タイトル〜ツールバー、ツールバー〜カテゴリ、カテゴリ〜グラフ
  static const SizedBox headerSpacing = SizedBox(height: AppSizes.space16);
  static const EdgeInsets panelMargin = EdgeInsets.only(top: AppSizes.space12);
  static const SizedBox chartSpacing = SizedBox(height: AppSizes.space20);

  // カテゴリパネル（Projects のフィルターパネルと同じ作り）
  static const EdgeInsets panelPadding = EdgeInsets.all(AppSizes.space20);
  static const double panelTitleFontSize = 16;

  /// この幅以上でグループを 2 列に並べる
  static const double panelTwoColumnBreakpoint = 720;
  static const double panelGroupGap = AppSizes.space24;

  /// ツールバーのカテゴリボタン
  static const double categoryButtonIconSize = 18;
  static const EdgeInsets currentCategoryPadding =
      EdgeInsets.symmetric(horizontal: AppSizes.space8, vertical: AppSizes.space2);
}
