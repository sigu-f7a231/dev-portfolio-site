class ProjectFilterState {
  final Map<String, List<String>> selectedFilters;

  /// 期間（年）。両方そろっているときだけ有効。この範囲に「少しでも重なる」プロジェクトを残す
  final int? fromYear;
  final int? toYear;

  /// 進行中（期間の終わりが「現在」/ present）のプロジェクトだけにする
  final bool ongoingOnly;

  ProjectFilterState({
    required this.selectedFilters,
    this.fromYear,
    this.toYear,
    this.ongoingOnly = false,
  });

  bool get hasPeriod => fromYear != null && toYear != null;

  /// 選択中の条件の数（期間・進行中のみも 1 件として数える）
  int get activeCount =>
      selectedFilters.values.fold(0, (sum, v) => sum + v.length) +
      (hasPeriod ? 1 : 0) +
      (ongoingOnly ? 1 : 0);

  /// 中身まで複製した Map（UI 側で書き換えても元に影響しない）
  Map<String, List<String>> copyFilters() => {
        for (final e in selectedFilters.entries) e.key: List<String>.from(e.value),
      };

  /// 条件を 1 つ外した新しい状態
  ProjectFilterState without(String key, String value) {
    final m = copyFilters();
    m[key]?.remove(value);
    return ProjectFilterState(
      selectedFilters: m,
      fromYear: fromYear,
      toYear: toYear,
      ongoingOnly: ongoingOnly,
    );
  }

  /// 期間の条件を外した新しい状態
  ProjectFilterState withoutPeriod() => ProjectFilterState(
        selectedFilters: copyFilters(),
        ongoingOnly: ongoingOnly,
      );

  /// 「進行中のみ」を外した新しい状態
  ProjectFilterState withoutOngoing() => ProjectFilterState(
        selectedFilters: copyFilters(),
        fromYear: fromYear,
        toYear: toYear,
      );

  factory ProjectFilterState.initial() {
    return ProjectFilterState(
      selectedFilters: {
        'role': [],
        'scale': [],
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