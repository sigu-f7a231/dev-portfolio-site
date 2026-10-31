class ProjectFilterState {
  final Map<String, List<String>> selectedFilters;

  ProjectFilterState({required this.selectedFilters});

  /// 選択中の条件の数
  int get activeCount =>
      selectedFilters.values.fold(0, (sum, v) => sum + v.length);

  /// 中身まで複製した Map（UI 側で書き換えても元に影響しない）
  Map<String, List<String>> copyFilters() => {
        for (final e in selectedFilters.entries) e.key: List<String>.from(e.value),
      };

  /// 条件を 1 つ外した新しい状態
  ProjectFilterState without(String key, String value) {
    final m = copyFilters();
    m[key]?.remove(value);
    return ProjectFilterState(selectedFilters: m);
  }

  factory ProjectFilterState.initial() {
    return ProjectFilterState(
      selectedFilters: {
        'serverOS': [],
        'db': [],
        'tools': [],
        'backendFrameworks': [],
        'frontendFrameworks': [],
        'uiFrameworks': [],
        'testingFrameworks': [],
        'cloudPlatforms': [],
        'awsServices': [],
        'azureServices': [],
        'gcpServices': [],
        'container': [],
        'containerOrchestration': [],
        'aiServices': [],
        'skills': [],
        'workflow': [],
      },
    );
  }
}