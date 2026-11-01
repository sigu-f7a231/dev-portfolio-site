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

  /// カードの期間（枠線だけの小さな枠＋長さ）
  static const cardPeriodPadding =
      EdgeInsets.symmetric(horizontal: AppSizes.space8, vertical: AppSizes.space4);
  static const double cardPeriodIconGap = AppSizes.space6;
  static const double cardPeriodSpacing = AppSizes.space8;
  static const periodIconSpacing = AppSizes.space4;
  static const chevronSize = 22.0;

  static const smallSpacing = SizedBox(height: AppSizes.space6);
  static const mediumSpacing = SizedBox(height: AppSizes.space10);

  // =========================
  // モーダル
  // =========================
  static const modalPadding = EdgeInsets.all(AppSizes.space16);

  /// 詳細ダイアログ：固定ヘッダー（プロジェクト名＋×）・スクロールする本文・固定フッター（公開ページ）
  static const modalHeaderPadding = EdgeInsets.fromLTRB(
      AppSizes.space24, AppSizes.space16, AppSizes.space8, AppSizes.space8);
  static const modalBodyPadding = EdgeInsets.symmetric(
      horizontal: AppSizes.space24, vertical: AppSizes.space8);
  static const modalFooterPadding = EdgeInsets.fromLTRB(
      AppSizes.space24, AppSizes.space12, AppSizes.space24, AppSizes.space16);
  static const double modalTitleFontSize = 22; // M3 title large

  /// 詳細ダイアログの Workflow（工程を横に並べる）
  static const workflowStepPadding = EdgeInsets.symmetric(
      horizontal: AppSizes.space12, vertical: AppSizes.space8);
  static const double workflowStepSpacing = AppSizes.space12; // 横の間隔
  static const double workflowStepRunSpacing = AppSizes.space12; // 折り返したときの縦の間隔
  static const double workflowStepIconSize = 18;
  static const double workflowStepIconGap = AppSizes.space6;
  static const SizedBox workflowLabelSpacing = SizedBox(height: AppSizes.space8);

  /// 詳細ダイアログの各項目（見出し＋中身）の上下の余白（項目どうしの間は 20px）
  static const detailSectionPadding = EdgeInsets.symmetric(vertical: AppSizes.space10);

  /// 期間（開始 → 終了・長さ）
  static const double periodIconSize = 18;
  static const modalMaxHeight = 600.0;

  static const fieldPadding = EdgeInsets.symmetric(vertical: AppSizes.space6);

  static const closeButtonSize = 24.0;

  static const verticalSpacingSmall = SizedBox(height: AppSizes.space12);

  // 結果が 0 件のとき
  static const double emptyIconSize = 40;
}
