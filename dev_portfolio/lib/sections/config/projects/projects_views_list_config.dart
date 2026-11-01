// lib/sections/config/projects/projects_views_list_config.dart
import 'package:flutter/material.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_texts.dart';
import '../../../widgets/app_loading_indicator.dart';

// 色・文字色・タグ・モーダルの見た目は lib/theme/（app_colors.dart / app_styles.dart）で管理。
// ここにはレイアウト用のサイズ・余白だけを置く。
class ProjectsListConfig {
  static const separator = SizedBox(height: AppSizes.space12);

  static const loading = Center(child: AppLoadingIndicator());
  static const empty = Center(child: Text(AppTexts.noProjects));

  // =========================
  // カード
  // =========================
  static const cardPadding = EdgeInsets.all(AppSizes.space16);
  static const descriptionMaxLines = 2;
  static const scheduleIconSize = 14.0;
  static const periodIconSpacing = AppSizes.space4;
  static const chevronSize = 22.0;

  static const smallSpacing = SizedBox(height: AppSizes.space6);
  static const mediumSpacing = SizedBox(height: AppSizes.space10);

  // =========================
  // モーダル
  // =========================
  static const modalPadding = EdgeInsets.all(AppSizes.space16);
  static const modalMaxHeight = 600.0;

  static const fieldPadding = EdgeInsets.symmetric(vertical: AppSizes.space6);

  static const closeButtonSize = 24.0;

  static const verticalSpacingSmall = SizedBox(height: AppSizes.space12);

  // 結果が 0 件のとき
  static const double emptyIconSize = 40;
}
