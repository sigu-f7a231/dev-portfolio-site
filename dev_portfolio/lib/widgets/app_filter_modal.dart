// lib/widgets/app_filter_modal.dart
import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../theme/app_theme.dart';

/// フィルター・カテゴリ選択をポップアップで開く（M3）
/// - 幅が広い（PC・タブレット）：画面中央のダイアログ
/// - 幅が狭い（スマホ）：下から出るボトムシート（つまみ付き・下にスワイプで閉じる）
///
/// [builder] のパネルは「見出し・スクロールする本文・フッター」の形にしておくと、
/// 高さが足りないときも見出しとボタンが固定されたまま本文だけスクロールする。
Future<T?> showAppFilterModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final size = MediaQuery.sizeOf(context);
  final colors = context.colors;

  if (size.width >= AppSizes.filterModalBreakpoint) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: colors.dialogBackground,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppSizes.filterModalMaxWidth,
            maxHeight: size.height * AppSizes.filterDialogMaxHeightRatio,
          ),
          child: builder(ctx),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: colors.dialogBackground,
    constraints: BoxConstraints(
      maxHeight: size.height * AppSizes.filterSheetMaxHeightRatio,
    ),
    builder: builder,
  );
}
