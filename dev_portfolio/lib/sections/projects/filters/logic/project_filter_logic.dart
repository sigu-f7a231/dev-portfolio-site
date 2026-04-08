// dev_portfolio/lib/sections/projects/filters/logic/project_filter_logic.dart

import '../../models/projects_model.dart';
import '../../../../../utils/string_utils.dart';
import '../state/project_filter_state.dart';

class ProjectFilterLogic {
  static List<Project> apply(
    List<Project> projects,
    ProjectFilterState state,
  ) {
    final filters = state.selectedFilters;

    // 選択された条件すべてを含むか
    bool matchList(List<String>? selected, String value) {
      if (selected == null || selected.isEmpty) return true;

      final values = splitSkills(value);
      // AND 条件: selected のすべてが values に含まれているか
      return selected.every((s) => values.contains(s));
    }

    bool matchWorkflow(
      List<String>? selected,
      Map<String, bool> workflow,
    ) {
      if (selected == null || selected.isEmpty) return true;

      final activeWorkflow = workflow.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      return selected.every((s) => activeWorkflow.contains(s));
    }

    return projects.where((p) {
      return matchList(filters['serverOS'], p.serverOS) &&
          matchList(filters['db'], p.db) &&
          matchList(filters['toolsFW'], p.toolsFW) &&
          matchList(filters['skills'], p.skills) &&
          matchWorkflow(filters['workflow'], p.workflow);
    }).toList();
  }
}