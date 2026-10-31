// lib/sections/projects/pagination/projects_pagination_ui.dart
import 'package:flutter/material.dart';
import '../../config/projects/projects_pagination_config.dart';
import '../../../theme/app_theme.dart';

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
            onPressed: () => onPageChanged(currentPage > 1 ? currentPage - 1 : 1),
          ),

          // ページ番号
          ...List.generate(totalPages, (index) {
            final page = index + 1;
            final isActive = page == currentPage;

            return GestureDetector(
              onTap: () => onPageChanged(page),
              child: Container(
                margin: ProjectsPaginationConfig.pageMargin,
                padding: ProjectsPaginationConfig.pagePadding,
                decoration: BoxDecoration(
                  color: isActive ? colors.paginationActive : colors.paginationInactive,
                  borderRadius: BorderRadius.circular(ProjectsPaginationConfig.borderRadius),
                ),
                child: Text(
                  '$page',
                  style: TextStyle(
                    fontSize: ProjectsPaginationConfig.fontSize,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? colors.paginationActiveText
                        : colors.paginationInactiveText,
                  ),
                ),
              ),
            );
          }),

          // 次へ
          IconButton(
            icon: const Icon(Icons.chevron_right),
            iconSize: ProjectsPaginationConfig.iconSize,
            color: colors.paginationIcon,
            onPressed: () => onPageChanged(
              currentPage < totalPages ? currentPage + 1 : totalPages,
            ),
          ),
        ],
      ),
    );
  }
}
