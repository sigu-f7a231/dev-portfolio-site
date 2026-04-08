// lib/sections/projects/filters/state/project_filter_state.dart

/// プロジェクトフィルターの状態を管理するクラス
class ProjectFilterState {
  /// 選択されているフィルター
  final Map<String, List<String>> selectedFilters;

  ProjectFilterState({required this.selectedFilters});

  /// 初期状態（全てのフィルターが空）のインスタンスを返す
  factory ProjectFilterState.initial() {
    return ProjectFilterState(
      selectedFilters: {
        'serverOS': [],
        'db': [],
        'toolsFW': [],
        'skills': [],
        'workflow': [],
      },
    );
  }

  /// 指定したキーの選択リストを取得
  List<String> get(String key) => selectedFilters[key] ?? [];

  /// 選択フィルターをコピーして新しい状態を返す
  ProjectFilterState copyWith({Map<String, List<String>>? selectedFilters}) {
    return ProjectFilterState(
      selectedFilters: selectedFilters ?? Map.from(this.selectedFilters),
    );
  }
}