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
  static const double cardHeight = 210;

  /// 高さ [height] のエリアに収まる行数（最低 1 行）
  static int rowsFor(double height) {
    final usable = height - padding.vertical + gridSpacing;
    final rows = (usable / (cardHeight + gridSpacing)).floor();
    return rows < 1 ? 1 : rows;
  }

  /// Collection の 1 ページの件数＝列数 × 行数（行がそろう件数）
  static int itemsPerPage({required double width, required double height}) =>
      columnsFor(width) * rowsFor(height);

  static const double gridSpacing = AppSizes.space12;
  static const EdgeInsets padding = EdgeInsets.only(bottom: AppSizes.space4);

  // =========================
  // カード内
  // =========================
  static const EdgeInsets cardPadding = EdgeInsets.all(AppSizes.space16);
  static const int titleMaxLines = 2;
  static const int descriptionMaxLines = 3;

  /// カードに出すタグの最大数（超えた分は「+N」）
  static const int maxTags = 3;
}
