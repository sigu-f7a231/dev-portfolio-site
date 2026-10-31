import 'package:flutter/material.dart';
import '../../models/projects_model.dart';
import '../../../../utils/language_utils.dart';
import '../../../../widgets/filter_chips_section.dart';
import '../../../config/projects/projects_section_config.dart';
import '../../../../theme/app_styles.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_texts.dart';

/// フィルターのグループ定義（キー・見出し・プロジェクトから候補を取り出す関数）
class _FilterGroup {
  final String key;
  final String title;
  final List<String> Function(Project p) values;

  const _FilterGroup(this.key, this.title, this.values);
}

/// フィルターパネル（ツールバーの「フィルター」で開閉。開閉は親が管理）
class ProjectsFilter extends StatefulWidget {
  /// いま表示しているタブ（Work / Private）のプロジェクト。候補はここから作る
  final List<Project> projects;
  final bool isWork;

  /// 現在適用中の条件（パネルを開いたときの初期選択）
  final Map<String, List<String>> initialFilters;

  final ValueChanged<Map<String, List<String>>> onApply;
  final VoidCallback onClose;

  const ProjectsFilter({
    super.key,
    required this.projects,
    required this.isWork,
    required this.initialFilters,
    required this.onApply,
    required this.onClose,
  });

  @override
  State<ProjectsFilter> createState() => _ProjectsFilterState();
}

class _ProjectsFilterState extends State<ProjectsFilter> {
  /// パネル内で編集中の条件（「反映」を押すまで一覧には反映しない）
  late final Map<String, List<String>> _selected = {
    for (final e in widget.initialFilters.entries) e.key: List<String>.from(e.value),
  };

  static const String _notUsed = '利用なし'; // YAML で「該当なし」を表す値（候補から除く）

  List<_FilterGroup> get _groups => [
        _FilterGroup('serverOS', AppTexts.filterServerOS, (p) => p.serverOSList),
        _FilterGroup('db', AppTexts.filterDb, (p) => p.dbList),
        _FilterGroup('tools', AppTexts.filterTools, (p) => p.toolsList),
        _FilterGroup('backendFrameworks', AppTexts.filterBackend, (p) => p.backendList),
        _FilterGroup('frontendFrameworks', AppTexts.filterFrontend, (p) => p.frontendList),
        _FilterGroup('skills', AppTexts.filterSkills, (p) => p.skillsList),
        if (widget.isWork)
          _FilterGroup(
            'workflow',
            AppTexts.filterWorkflow,
            (p) => p.workflow.keys
                .map((k) => LanguageUtils.workflowLabels['ja']?[k] ?? k)
                .toList(),
          ),
      ];

  List<String> _candidates(_FilterGroup g) => widget.projects
      .expand(g.values)
      .where((v) => v != _notUsed)
      .toSet()
      .toList();

  void _toggle(String key, String value) {
    setState(() {
      final list = _selected.putIfAbsent(key, () => []);
      list.contains(value) ? list.remove(value) : list.add(value);
    });
  }

  void _clear() {
    setState(() {
      for (final list in _selected.values) {
        list.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups
        .map((g) => (group: g, items: _candidates(g)))
        .where((e) => e.items.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: ProjectsSectionConfig.filterPanelPadding,
      decoration: AppStyles.filterPanel(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 見出し＋閉じる
          Row(
            children: [
              Expanded(
                child: Text(AppTexts.filter, style: AppStyles.title(
                  context,
                  fontSize: ProjectsSectionConfig.filterPanelTitleFontSize,
                )),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: AppTexts.close,
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space8),

          // グループ（幅があれば 2 列）
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >=
                  ProjectsSectionConfig.filterTwoColumnBreakpoint;
              final gap = ProjectsSectionConfig.filterGroupGap;
              final itemWidth = twoColumns
                  ? (constraints.maxWidth - gap) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: gap,
                runSpacing: AppSizes.space20,
                children: groups
                    .map((e) => SizedBox(
                          width: itemWidth,
                          child: FilterChipsSection(
                            title: e.group.title,
                            items: e.items,
                            selectedItems: _selected[e.group.key] ?? const [],
                            onSelected: (v) => _toggle(e.group.key, v),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSizes.space20),

          // フッター
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clear,
                child: const Text(AppTexts.filterClear),
              ),
              const SizedBox(width: AppSizes.space8),
              ElevatedButton(
                onPressed: () => widget.onApply({
                  for (final e in _selected.entries) e.key: List<String>.from(e.value),
                }),
                child: const Text(AppTexts.filterApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
