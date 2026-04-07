import '../models/projects_model.dart';
import '../../config/projects/projects_pagination_config.dart';

class ProjectsPaginationLogic {
  // =========================
  // 総ページ数
  // =========================
  static int getTotalPages(List<Project> projects) {
    if (projects.isEmpty) return 1;

    return (projects.length /
            ProjectsPaginationConfig.itemsPerPage)
        .ceil();
  }

  // =========================
  // ページごとのデータ取得
  // =========================
  static List<Project> getPaginatedProjects(
    List<Project> allProjects,
    int currentPage,
  ) {
    final perPage = ProjectsPaginationConfig.itemsPerPage;

    final startIndex = (currentPage - 1) * perPage;
    final endIndex = startIndex + perPage;

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