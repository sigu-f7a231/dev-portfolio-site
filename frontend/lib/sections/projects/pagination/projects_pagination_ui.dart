// lib/sections/projects/pagination/projects_pagination_ui.dart
import 'package:flutter/material.dart';
import '../../config/projects/projects_pagination_config.dart';
import '../../../constants/app_texts.dart';
import '../../../theme/app_theme.dart';

/// ページ送り（M3：現在ページは FilledButton、それ以外は TextButton）
///
/// 幅に合わせて表示を変える：
/// - 全部入る      → 1 2 3 4 5
/// - 入りきらない  → 1 … 4 5 6 … 10（最初・最後・現在の前後）
/// - かなり狭い    → ‹ 3 / 10 ›
class ProjectsPaginationUI extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const ProjectsPaginationUI({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  /// 番号ボタン 1 個ぶんの幅（ボタン＋左右の余白）
  static double get _slotWidth =>
      ProjectsPaginationConfig.pageButtonSize +
      ProjectsPaginationConfig.pageMargin.horizontal;

  /// [maxSlots] 個に収まるように、表示するページ番号を決める（null は「…」）
  static List<int?> _visiblePages(int current, int total, int maxSlots) {
    if (total <= maxSlots) return List.generate(total, (i) => i + 1);

    // 両端（1 と最後）＋「…」2 つ＝ 4 枠を除いた残りを、現在ページの周りに使う
    final int middle = maxSlots - 4 < 1 ? 1 : maxSlots - 4;
    final int start = current - middle ~/ 2;
    final int end = start + middle - 1;

    // 端に寄っているときは「…」を片側だけにして、その分ページを多く出す
    if (start <= 3) {
      return [...List.generate(maxSlots - 2, (i) => i + 1), null, total];
    }
    if (end >= total - 2) {
      final count = maxSlots - 2;
      return [1, null, ...List.generate(count, (i) => total - count + 1 + i)];
    }
    return [1, null, for (var p = start; p <= end; p++) p, null, total];
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox();
    }

    final colors = context.colors;
    final pageStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size.square(ProjectsPaginationConfig.pageButtonSize),
      ),
      fixedSize: const WidgetStatePropertyAll(
        Size.square(ProjectsPaginationConfig.pageButtonSize),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      // スマホ（Android / iOS）では Material のボタンが当たり判定を 48px に広げる（padded）ため、
      // 40px として数えた番号の数が収まらず、右端の ›（次のページ）が画面の外に押し出されていた。見た目どおり 40px にそろえる
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const WidgetStatePropertyAll(CircleBorder()),
      textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelLarge),
    );

    Widget navButton(IconData icon, String tooltip, int? target) => IconButton(
          icon: Icon(icon),
          tooltip: tooltip,
          iconSize: ProjectsPaginationConfig.iconSize,
          color: colors.paginationIcon,
          onPressed: target == null ? null : () => onPageChanged(target),
        );

    final prev = navButton(Icons.chevron_left, AppTexts.paginationPrev,
        currentPage > 1 ? currentPage - 1 : null);
    final next = navButton(Icons.chevron_right, AppTexts.paginationNext,
        currentPage < totalPages ? currentPage + 1 : null);

    Widget pageButton(int page) {
      final isActive = page == currentPage;
      return Padding(
        padding: ProjectsPaginationConfig.pageMargin,
        child: isActive
            ? FilledButton(onPressed: () {}, style: pageStyle, child: Text('$page'))
            : TextButton(
                onPressed: () => onPageChanged(page),
                style: pageStyle.copyWith(
                  foregroundColor:
                      WidgetStatePropertyAll(colors.paginationInactiveText),
                ),
                child: Text('$page'),
              ),
      );
    }

    Widget ellipsis() => SizedBox(
          width: _slotWidth,
          child: Text(
            AppTexts.paginationEllipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: colors.paginationInactiveText),
          ),
        );

    return Padding(
      padding: ProjectsPaginationConfig.containerPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available =
              constraints.maxWidth - ProjectsPaginationConfig.navButtonWidth * 2;
          final maxSlots = (available / _slotWidth).floor();

          // かなり狭い：‹ 3 / 10 ›
          if (maxSlots < ProjectsPaginationConfig.minNumberedButtons) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                prev,
                Text(
                  AppTexts.paginationCompact(currentPage, totalPages),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                next,
              ],
            );
          }

          final pages = _visiblePages(currentPage, totalPages, maxSlots);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              prev,
              for (final p in pages) p == null ? ellipsis() : pageButton(p),
              next,
            ],
          );
        },
      ),
    );
  }
}
