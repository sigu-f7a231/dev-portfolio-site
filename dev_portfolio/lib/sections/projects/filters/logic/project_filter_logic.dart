import '../../models/projects_model.dart';
import '../state/project_filter_state.dart';
import '../../../../utils/skill_name.dart';

class WorkflowKeyMapper {
  /// 日本語 → workflowキー
  static const Map<String, String> jaToKey = {
    '要件定義': 'requirements',
    '基本設計': 'basic_design',
    '詳細設計': 'detailed_design',
    '実装・単体テスト': 'implementation_unit_test',
    '結合テスト': 'integration_test',
    '総合テスト': 'system_test',
    '保守・運用': 'maintenance_operation',
  };
}

class ProjectFilterLogic {
  static List<Project> apply(
    List<Project> projects,
    ProjectFilterState state,
  ) {
    final f = state.selectedFilters;

    /// ---------------------------
    /// CSV split
    /// ---------------------------
    List<String> split(String v) {
      return v
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    /// ---------------------------
    /// 通常フィルター（部分一致）
    /// ---------------------------
    bool match(List<String> selected, List<String> values, [String? category]) {
      if (selected.isEmpty) return true;

      // 表記ゆれ（大文字・小文字、全角・半角、前後の記号、空白、AWS などの先頭）を無視して部分一致で比べる
      return selected.every(
        (s) => values.any((v) =>
            skillKey(v, category: category).contains(skillKey(s, category: category))),
      );
    }

    /// ---------------------------
    /// workflowフィルター（重要）
    /// ---------------------------
    bool matchWorkflow(List<String> selected, Map<String, bool> wf) {
      if (selected.isEmpty) return true;

      // trueのキーだけ取得
      final activeKeys = wf.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toSet();

      // 日本語 → 英語キー変換
      final normalizedSelected = selected
          .map((s) => WorkflowKeyMapper.jaToKey[s] ?? s)
          .toSet();

      return normalizedSelected.every(activeKeys.contains);
    }

    /// ---------------------------
    /// Projectから値取得
    /// ---------------------------
    List<String> getValues(Project p, String key) {
      switch (key) {
        case 'serverOS':
          return split(p.serverOS);
        case 'db':
          return split(p.db);
        case 'tools':
          return split(p.tools);

        case 'backendFrameworks':
          return split(p.backendFrameworks);
        case 'frontendFrameworks':
          return split(p.frontendFrameworks);
        case 'uiFrameworks':
          return split(p.uiFrameworks);
        case 'testingFrameworks':
          return split(p.testingFrameworks);

        case 'cloudPlatforms':
          return split(p.cloudPlatforms);
        case 'awsServices':
          return split(p.awsServices);
        case 'azureServices':
          return split(p.azureServices);
        case 'gcpServices':
          return split(p.gcpServices);

        case 'container':
          return split(p.container);
        case 'containerOrchestration':
          return split(p.containerOrchestration);
        case 'aiServices':
          return split(p.aiServices);

        case 'skills':
          return split(p.skills);

        default:
          return [];
      }
    }

    return projects.where((p) {
      final okServer = match(f['serverOS'] ?? [], getValues(p, 'serverOS'));
      final okDb = match(f['db'] ?? [], getValues(p, 'db'));
      final okTools = match(f['tools'] ?? [], getValues(p, 'tools'));

      final okBackend =
          match(f['backendFrameworks'] ?? [], getValues(p, 'backendFrameworks'));

      final okFrontend =
          match(f['frontendFrameworks'] ?? [], getValues(p, 'frontendFrameworks'));

      final okUi =
          match(f['uiFrameworks'] ?? [], getValues(p, 'uiFrameworks'));

      final okTest =
          match(f['testingFrameworks'] ?? [], getValues(p, 'testingFrameworks'));

      final okCloud =
          match(f['cloudPlatforms'] ?? [], getValues(p, 'cloudPlatforms'));

      final okAws =
          match(f['awsServices'] ?? [], getValues(p, 'awsServices'), 'aws_services');

      final okAzure =
          match(f['azureServices'] ?? [], getValues(p, 'azureServices'), 'azure_services');

      final okGcp =
          match(f['gcpServices'] ?? [], getValues(p, 'gcpServices'), 'gcp_services');

      final okContainer =
          match(f['container'] ?? [], getValues(p, 'container'));

      final okOrch =
          match(f['containerOrchestration'] ?? [], getValues(p, 'containerOrchestration'));

      final okAi =
          match(f['aiServices'] ?? [], getValues(p, 'aiServices'));

      final okSkills =
          match(f['skills'] ?? [], getValues(p, 'skills'));

      final okWorkflow =
          matchWorkflow(f['workflow'] ?? [], p.workflow);

      // 期間：指定した年の範囲に少しでも重なれば残す
      final okPeriod = !state.hasPeriod ||
          (!p.periodStart.isAfter(DateTime(state.toYear!, 12, 31)) &&
              !p.periodEnd.isBefore(DateTime(state.fromYear!, 1, 1)));

      // 進行中のみ
      final okOngoing = !state.ongoingOnly || p.isOngoing;

      return okPeriod &&
          okOngoing &&
          okServer &&
          okDb &&
          okTools &&
          okBackend &&
          okFrontend &&
          okUi &&
          okTest &&
          okCloud &&
          okAws &&
          okAzure &&
          okGcp &&
          okContainer &&
          okOrch &&
          okAi &&
          okSkills &&
          okWorkflow;
    }).toList();
  }
}