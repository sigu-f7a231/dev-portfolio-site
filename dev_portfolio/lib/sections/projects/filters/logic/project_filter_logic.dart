import '../../models/projects_model.dart';
import '../state/project_filter_state.dart';

class ProjectFilterLogic {
  static List<Project> apply(
    List<Project> projects,
    ProjectFilterState state,
  ) {
    final f = state.selectedFilters;

    bool match(List<String> selected, List<String> values) {
      if (selected.isEmpty) return true;
      return selected.every((s) => values.contains(s));
    }

    bool matchWorkflow(List<String> selected, Map<String, bool> wf) {
      if (selected.isEmpty) return true;

      final active = wf.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      return selected.every((s) => active.contains(s));
    }

    return projects.where((p) {
      return match(f['serverOS']!, p.serverOSList) &&
          match(f['db']!, p.dbList) &&
          match(f['tools']!, p.toolsList) &&

          match(f['backendFrameworks']!, p.backendList) &&
          match(f['frontendFrameworks']!, p.frontendList) &&
          match(f['uiFrameworks']!, p.uiList) &&
          match(f['testingFrameworks']!, p.testingList) &&

          match(f['cloudPlatforms']!, p.cloudList) &&
          match(f['awsServices']!, p.awsList) &&
          match(f['azureServices']!, p.azureList) &&
          match(f['gcpServices']!, p.gcpList) &&

          match(f['container']!, p.containerList) &&
          match(f['containerOrchestration']!, p.orchestrationList) &&
          match(f['aiServices']!, p.aiList) &&

          match(f['skills']!, p.skillsList) &&
          matchWorkflow(f['workflow']!, p.workflow);
    }).toList();
  }
}