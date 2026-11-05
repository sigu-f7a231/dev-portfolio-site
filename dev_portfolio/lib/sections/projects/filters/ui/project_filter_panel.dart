import 'package:flutter/material.dart';
import '../../models/projects_model.dart';
import '../state/project_filter_state.dart';
import '../../../../utils/language_utils.dart';
import '../../../../utils/skill_name.dart';
import '../../../../utils/tech_catalog.dart';
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

  /// AWS などのサービスの分類名（候補をまとめるときに先頭の「AWS」などを外す）
  final String? category;

  const _FilterGroup(this.key, this.title, this.values, {this.category});
}

/// フィルターパネル（ツールバーの「フィルター」で開閉。開閉は親が管理）
class ProjectsFilter extends StatefulWidget {
  /// いま表示しているタブ（Work / Private）のプロジェクト。候補はここから作る
  final List<Project> projects;
  final bool isWork;

  /// 現在適用中の条件（パネルを開いたときの初期選択）
  final ProjectFilterState initialState;

  final ValueChanged<ProjectFilterState> onApply;
  final VoidCallback onClose;

  const ProjectsFilter({
    super.key,
    required this.projects,
    required this.isWork,
    required this.initialState,
    required this.onApply,
    required this.onClose,
  });

  @override
  State<ProjectsFilter> createState() => _ProjectsFilterState();
}

class _ProjectsFilterState extends State<ProjectsFilter> {
  /// パネル内で編集中の条件（「反映」を押すまで一覧には反映しない）
  late final Map<String, List<String>> _selected = widget.initialState.copyFilters();

  /// 期間（null = 指定なし）と「進行中のみ」
  late RangeValues? _period = widget.initialState.hasPeriod
      ? RangeValues(
          widget.initialState.fromYear!.toDouble(),
          widget.initialState.toYear!.toDouble(),
        )
      : null;
  late bool _ongoingOnly = widget.initialState.ongoingOnly;

  /// スライダーの範囲＝いまのタブのプロジェクトの最も古い開始年〜最も新しい終了年
  ({int min, int max})? get _yearBounds {
    // 期間が書かれていないプロジェクトは範囲の計算に入れない
    final dated = widget.projects.where((p) => p.period.trim().isNotEmpty).toList();
    if (dated.isEmpty) return null;
    final starts = dated.map((p) => p.periodStart.year);
    final ends = dated.map((p) => p.periodEnd.year);
    return (min: starts.reduce((a, b) => a < b ? a : b), max: ends.reduce((a, b) => a > b ? a : b));
  }


  /// 並びは Skills のカテゴリと同じ。候補のない分類は出さない
  List<_FilterGroup> get _groups => [
        _FilterGroup('serverOS', AppTexts.filterServerOS, (p) => p.serverOSList),
        _FilterGroup('db', AppTexts.filterDb, (p) => p.dbList),
        // Tools はグループ（バージョン管理・開発ツール・環境…。名前から推測）ごとに見出しを分ける
        for (final g in ToolGroup.values)
          _FilterGroup(
            'tools',
            AppTexts.skillCategoryLabels[g.key] ?? AppTexts.filterTools,
            (p) => [for (final t in p.toolsList) if (toolGroupOf(t) == g) t],
          ),
        _FilterGroup('backendFrameworks', AppTexts.filterBackend, (p) => p.backendList),
        _FilterGroup('frontendFrameworks', AppTexts.filterFrontend, (p) => p.frontendList),
        _FilterGroup('uiFrameworks', AppTexts.filterUi, (p) => p.uiList),
        _FilterGroup('testingFrameworks', AppTexts.filterTesting, (p) => p.testingList),
        _FilterGroup('cloudPlatforms', AppTexts.filterCloud, (p) => p.cloudList),
        _FilterGroup('awsServices', AppTexts.filterAws, (p) => p.awsList,
            category: 'aws_services'),
        _FilterGroup('azureServices', AppTexts.filterAzure, (p) => p.azureList,
            category: 'azure_services'),
        _FilterGroup('gcpServices', AppTexts.filterGcp, (p) => p.gcpList,
            category: 'gcp_services'),
        _FilterGroup('container', AppTexts.filterContainer, (p) => p.containerList),
        _FilterGroup('containerOrchestration', AppTexts.filterOrchestration,
            (p) => p.orchestrationList),
        _FilterGroup('aiServices', AppTexts.filterAi, (p) => p.aiList),
        // Skills もグループ（プログラミング言語・マークアップ・データ形式・アーキテクチャ・ライブラリ…）ごとに見出しを分ける
        for (final g in SkillGroup.values)
          _FilterGroup(
            'skills',
            AppTexts.skillCategoryLabels[g.key] ?? AppTexts.filterSkills,
            // 書いたままの名前で見分ける（url_launcher のような名前は表示用に整えるとライブラリと分からなくなるため）
            (p) => [
              for (final s in p.skills.split(','))
                if (s.trim().isNotEmpty && skillGroupOf(s) == g) s.trim(),
            ],
          ),
        if (widget.isWork)
          _FilterGroup(
            'workflow',
            AppTexts.filterWorkflow,
            (p) => p.workflow.keys
                .map((k) => LanguageUtils.workflowLabels['ja']?[k] ?? k)
                .toList(),
          ),
      ];

  /// 候補（表記ゆれ「MAC / mac / mac.」などは 1 つにまとめる。lib/utils/skill_name.dart）
  /// AWS などのサービスは、先頭の「AWS」などを外してまとめる（AWS Lambda / Lambda → Lambda）
  List<String> _candidates(_FilterGroup g) => uniqueSkillNames(
        widget.projects.expand(g.values).where((v) => cleanSkillName(v) != Project.notUsed),
        category: g.category,
      );

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
      _period = null;
      _ongoingOnly = false;
    });
  }

  void _apply() {
    final bounds = _yearBounds;
    final p = _period;
    int? fromYear;
    int? toYear;
    // スライダーが全範囲のままなら「指定なし」として扱う
    if (bounds != null && p != null) {
      final from = p.start.round(), to = p.end.round();
      if (from != bounds.min || to != bounds.max) {
        fromYear = from;
        toYear = to;
      }
    }
    widget.onApply(ProjectFilterState(
      selectedFilters: _selected.map((k, v) => MapEntry(k, List<String>.from(v))),
      fromYear: fromYear,
      toYear: toYear,
      ongoingOnly: _ongoingOnly,
    ));
  }

  /// 「期間」グループ：年の範囲スライダー＋「進行中のみ」
  Widget _buildPeriod(BuildContext context) {
    final bounds = _yearBounds;
    final children = <Widget>[
      Text(AppTexts.filterPeriod, style: AppStyles.filterGroupLabel(context)),
      const SizedBox(height: AppSizes.space8),
    ];

    if (bounds != null && bounds.min < bounds.max) {
      final values = _period ??
          RangeValues(bounds.min.toDouble(), bounds.max.toDouble());
      final from = values.start.round(), to = values.end.round();
      final isFull = from == bounds.min && to == bounds.max;
      children.addAll([
        Text(
          isFull ? AppTexts.periodAll : AppTexts.periodRange(from, to),
          style: AppStyles.secondary(context),
        ),
        RangeSlider(
          min: bounds.min.toDouble(),
          max: bounds.max.toDouble(),
          divisions: bounds.max - bounds.min,
          values: values,
          labels: RangeLabels('$from', '$to'),
          onChanged: (v) => setState(() => _period = v),
        ),
      ]);
    } else if (bounds != null) {
      // 全プロジェクトが同じ年のときはスライダーを出さない
      children.add(Text(
        AppTexts.periodSingleYear(bounds.min),
        style: AppStyles.secondary(context),
      ));
      children.add(const SizedBox(height: AppSizes.space8));
    }

    children.add(FilterChip(
      label: const Text(AppTexts.filterOngoingOnly),
      selected: _ongoingOnly,
      onSelected: (v) => setState(() => _ongoingOnly = v),
      showCheckmark: true,
    ));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 見出し＋閉じる（固定）
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

          // 本文（高さが足りないときはここだけスクロール）
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 期間（全幅）
                _buildPeriod(context),
                const SizedBox(height: AppSizes.space20),

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
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space20),

          // フッター（固定）
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clear,
                child: const Text(AppTexts.filterClear),
              ),
              const SizedBox(width: AppSizes.space8),
              FilledButton(
                onPressed: _apply,
                child: const Text(AppTexts.filterApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
