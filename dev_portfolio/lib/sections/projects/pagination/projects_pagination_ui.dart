// lib/sections/projects/pagination/projects_pagination_ui.dart
import 'package:flutter/material.dart';
import '../../config/projects/projects_pagination_config.dart';

class ProjectsPaginationUI extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;
  final bool isDark; // 🔽 ダークモード追加

  const ProjectsPaginationUI({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.isDark = false, // 🔽 デフォルト false
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox();
    }

    final activeColor =
        isDark ? ProjectsPaginationConfig.darkActiveColor : ProjectsPaginationConfig.activeColor;
    final inactiveColor =
        isDark ? ProjectsPaginationConfig.darkInactiveColor : ProjectsPaginationConfig.inactiveColor;
    final activeTextColor =
        isDark ? ProjectsPaginationConfig.darkActiveTextColor : ProjectsPaginationConfig.activeTextColor;
    final inactiveTextColor =
        isDark ? ProjectsPaginationConfig.darkInactiveTextColor : ProjectsPaginationConfig.inactiveTextColor;

    return Padding(
      padding: ProjectsPaginationConfig.containerPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 前へ
          IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: ProjectsPaginationConfig.iconSize,
            color: ProjectsPaginationConfig.iconColor,
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
                  color: isActive ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(ProjectsPaginationConfig.borderRadius),
                ),
                child: Text(
                  '$page',
                  style: TextStyle(
                    fontSize: ProjectsPaginationConfig.fontSize,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? activeTextColor : inactiveTextColor,
                  ),
                ),
              ),
            );
          }),

          // 次へ
          IconButton(
            icon: const Icon(Icons.chevron_right),
            iconSize: ProjectsPaginationConfig.iconSize,
            color: ProjectsPaginationConfig.iconColor,
            onPressed: () => onPageChanged(
              currentPage < totalPages ? currentPage + 1 : totalPages,
            ),
          ),
        ],
      ),
    );
  }
}