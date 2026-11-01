// lib/sections/projects/pagination/projects_pagination_ui.dart
import 'package:flutter/material.dart';
import '../../config/projects/projects_pagination_config.dart';
import '../../../theme/app_theme.dart';

/// ページ送り（M3：現在ページは FilledButton、それ以外は TextButton。押したときの反応・キーボード操作に対応）
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
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      shape: const WidgetStatePropertyAll(CircleBorder()),
      textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelLarge),
    );

    return Padding(
      padding: ProjectsPaginationConfig.containerPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 前へ
          IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: ProjectsPaginationConfig.iconSize,
            color: colors.paginationIcon,
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),

          // ページ番号
          ...List.generate(totalPages, (index) {
            final page = index + 1;
            final isActive = page == currentPage;

            return Padding(
              padding: ProjectsPaginationConfig.pageMargin,
              child: isActive
                  ? FilledButton(
                      onPressed: () {},
                      style: pageStyle,
                      child: Text('$page'),
                    )
                  : TextButton(
                      onPressed: () => onPageChanged(page),
                      style: pageStyle.copyWith(
                        foregroundColor:
                            WidgetStatePropertyAll(colors.paginationInactiveText),
                      ),
                      child: Text('$page'),
                    ),
            );
          }),

          // 次へ
          IconButton(
            icon: const Icon(Icons.chevron_right),
            iconSize: ProjectsPaginationConfig.iconSize,
            color: colors.paginationIcon,
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}
