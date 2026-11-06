// lib/sections/config/projects/projects_views_collection_config.dart
import 'package:flutter/material.dart';
import '../../../constants/app_sizes.dart';

// 色は lib/theme/app_colors.dart、カードの見た目は lib/theme/app_styles.dart（projectCard など）で管理
class ProjectsCollectionConfig {
  // =========================
  // グリッド（画面幅に応じて列数を変える）
  // =========================
  /// 幅（px）→ 列数。上から順に判定し、どれにも当てはまらなければ 1 列
  static const List<MapEntry<double, int>> columnBreakpoints = [
    MapEntry(1100, 4),
    MapEntry(820, 3),
    MapEntry(520, 2),
  ];

  static int columnsFor(double width) {
    for (final bp in columnBreakpoints) {
      if (width >= bp.key) return bp.value;
    }
    return 1;
  }

  /// カード 1 枚の高さ（列数が変わっても高さは一定）
  static const double cardHeight = 272; // カバー＋本文（期間・タグを含む）

  /// カバー（上の色の帯）の高さ
  static const double coverHeight = 72;
  static const EdgeInsets coverPadding =
      EdgeInsets.symmetric(horizontal: AppSizes.space16, vertical: AppSizes.space12);
  static const EdgeInsets coverBadgePadding =
      EdgeInsets.symmetric(horizontal: AppSizes.space8, vertical: AppSizes.space4);

  /// 幅（px）→ 1 ページの行数。列が少ない狭い画面ほど行を増やす
  /// （ページ全体でスクロールするので、エリアの高さではなく幅で決める）
  static const List<MapEntry<double, int>> rowBreakpoints = [
    MapEntry(820, 2), // PC：3〜4 列 × 2 行
    MapEntry(520, 3), // タブレット：2 列 × 3 行
  ];
  static const int rowsOnPhone = 4; // スマホ：1 列 × 4 行

  static int rowsFor(double width) {
    for (final bp in rowBreakpoints) {
      if (width >= bp.key) return bp.value;
    }
    return rowsOnPhone;
  }

  /// Collection の 1 ページの件数＝列数 × 行数（行がそろう件数）
  static int itemsPerPage(double width) => columnsFor(width) * rowsFor(width);

  static const double gridSpacing = AppSizes.space12;
  static const EdgeInsets padding = EdgeInsets.only(bottom: AppSizes.space4);

  // =========================
  // カード内
  // =========================
  static const EdgeInsets cardPadding = EdgeInsets.all(AppSizes.space16);
  static const int titleMaxLines = 2;
  static const int descriptionMaxLines = 2;

  /// カードに出すタグの最大数（超えた分は「+N」）
  static const int maxTags = 3;
}
