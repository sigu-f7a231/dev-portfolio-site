import '../models/projects_model.dart';
import '../../config/projects/projects_pagination_config.dart';

class ProjectsPaginationLogic {
  // =========================
  // 総ページ数
  // =========================
  /// [perPage] を省略すると ProjectsPaginationConfig.itemsPerPage（List 表示）
  static int getTotalPages(List<Project> projects, {int? perPage}) {
    if (projects.isEmpty) return 1;

    return (projects.length /
            (perPage ?? ProjectsPaginationConfig.itemsPerPage))
        .ceil();
  }

  // =========================
  // ページごとのデータ取得
  // =========================
  static List<Project> getPaginatedProjects(
    List<Project> allProjects,
    int currentPage, {
    int? perPage,
  }) {
    final size = perPage ?? ProjectsPaginationConfig.itemsPerPage;

    final startIndex = (currentPage - 1) * size;
    final endIndex = startIndex + size;

    if (startIndex >= allProjects.length) {
      return [];
    }

    return allProjects.sublist(
      startIndex,
      endIndex > allProjects.length
          ? allProjects.length
          : endIndex,
    );
  }
}