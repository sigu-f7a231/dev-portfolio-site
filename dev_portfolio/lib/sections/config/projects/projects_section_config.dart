// lib/sections/config/projects/projects_section_config.dart
import 'package:flutter/material.dart';
import '../../../constants/app_sizes.dart';

// 色は lib/theme/app_colors.dart、見た目は lib/theme/app_styles.dart で管理
class ProjectsSectionConfig {
  // セクション全体のパディング
  static const EdgeInsets padding = EdgeInsets.all(AppSizes.space24);

  // ヘッダー〜ツールバー間
  static const SizedBox headerSpacing = SizedBox(height: AppSizes.space16);

  // ツールバー〜一覧の間
  static const SizedBox toolbarSpacing = SizedBox(height: AppSizes.space16);

  /// 読み込み中・0 件のときの一覧エリアの高さ
  static const double loadingHeight = 240;

  // =========================
  // ツールバー（Work/Private・フィルター・表示切替）
  // =========================
  // Work/Private・List/Collection は M3 の SegmentedButton（lib/widgets/app_segment.dart）

  /// フィルターボタンのアイコン
  static const double filterIconSize = 18;

  // =========================
  // フィルターパネル
  // =========================
  static const EdgeInsets filterPanelPadding = EdgeInsets.all(AppSizes.space20);
  static const double filterPanelTitleFontSize = 16;

  /// この幅以上でグループを 2 列に並べる
  static const double filterTwoColumnBreakpoint = 720;
  static const double filterGroupGap = AppSizes.space24;

  /// 適用中フィルターのチップ
  static const EdgeInsets activeFilterPadding = EdgeInsets.only(
      left: AppSizes.space12, right: AppSizes.space6, top: AppSizes.space4, bottom: AppSizes.space4);
  static const double activeFilterRemoveIconSize = 16;
}
