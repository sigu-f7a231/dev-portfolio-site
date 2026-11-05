import 'package:flutter/material.dart';
import 'data/skills_work.dart';
import 'data/skills_private.dart';
import 'widgets/skills_header.dart';
import 'widgets/skills_card.dart';
import 'widgets/skills_chart_switch.dart';
import 'widgets/skills_category_filter.dart';
import '../config/skills/skills_widgets_header_config.dart';
import '../config/skills/skills_widgets_card_config.dart';
import '../../widgets/app_segment.dart';
import '../../widgets/app_filter_modal.dart';
import '../../theme/app_styles.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_texts.dart';
import '../../widgets/app_loading_indicator.dart';

/// カテゴリ → （項目名 → 割合%）
typedef SkillsData = Map<String, Map<String, double>>;

class SkillsSection extends StatefulWidget {
  const SkillsSection({super.key});

  @override
  State<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection> {
  bool _showPie = false;

  /// [0] = Work、[1] = Private
  late final Future<List<SkillsData>> _skillsFuture;

  /// 全カテゴリ
  final List<String> _baseCategories = const [
    'server_os',
    'db',
    // Tools はグループごと（バージョン管理・開発ツール・環境…。名前から推測）
    'tools_vcs',
    'tools_dev',
    'tools_env',
    'tools_cicd',
    'tools_pm',
    'tools_design',
    'tools_other',
    'backend_frameworks',
    'frontend_frameworks',
    'ui_frameworks',
    'testing_frameworks',
    'cloud_platforms',
    'aws_services',
    'azure_services',
    'gcp_services',
    'container',
    'container_orchestration',
    'ai_services',
    // Skills はグループごと（プログラミング言語・マークアップ・データ形式・アーキテクチャ・ライブラリ…。名前から推測）
    'skills_lang',
    'skills_markup',
    'skills_data',
    'skills_arch',
    'skills_lib',
    'skills_other',
  ];

  /// workのみ追加
  final List<String> _workExtra = const ['workflow'];

  /// カテゴリパネルのグループ（どのカテゴリをどの見出しの下に並べるか）
  static const List<SkillsCategoryGroup> _categoryGroups = [
    SkillsCategoryGroup(AppTexts.categoryGroupInfra, [
      'server_os',
      'db',
      'container',
      'container_orchestration',
    ]),
    SkillsCategoryGroup(AppTexts.categoryGroupDev, [
      'backend_frameworks',
      'frontend_frameworks',
      'ui_frameworks',
      'testing_frameworks',
    ]),
    SkillsCategoryGroup(AppTexts.categoryGroupSkills, [
      'skills_lang',
      'skills_markup',
      'skills_data',
      'skills_arch',
      'skills_lib',
      'skills_other',
    ]),
    SkillsCategoryGroup(AppTexts.categoryGroupTools, [
      'tools_vcs',
      'tools_dev',
      'tools_env',
      'tools_cicd',
      'tools_pm',
      'tools_design',
      'tools_other',
    ]),
    SkillsCategoryGroup(AppTexts.categoryGroupCloud, [
      'cloud_platforms',
      'aws_services',
      'azure_services',
      'gcp_services',
      'ai_services',
    ]),
    SkillsCategoryGroup(AppTexts.categoryGroupProcess, ['workflow']),
  ];

  String _currentCategory = 'server_os';
  bool _isWork = true;
  bool _categoryOpen = false;

  @override
  void initState() {
    super.initState();
    _skillsFuture = Future.wait([loadWorkSkillsAll(), loadPrivateSkillsAll()]);
  }

  List<String> _getAllCategories(bool isWork) {
    return isWork ? [..._baseCategories, ..._workExtra] : _baseCategories;
  }

  /// パネルに出すグループ：いまのタブにあり、データがあるカテゴリだけ（空のグループは出さない）
  List<SkillsCategoryGroup> _panelGroups(SkillsData? data) {
    final all = _getAllCategories(_isWork);
    return _categoryGroups
        .map((g) => SkillsCategoryGroup(
              g.title,
              g.categories
                  .where((c) => all.contains(c))
                  .where((c) => data == null || (data[c]?.isNotEmpty ?? false))
                  .toList(),
            ))
        .where((g) => g.categories.isNotEmpty)
        .toList();
  }

  final Map<String, String> _labelOverrides = AppTexts.skillCategoryLabels;

  String _label(String key) =>
      _labelOverrides[key] ??
      key.replaceAll('_', ' ').split(' ').map((e) {
        if (e.isEmpty) return '';
        return '${e[0].toUpperCase()}${e.substring(1)}';
      }).join(' ');

  void _selectTab(bool isWork) {
    setState(() {
      _isWork = isWork;
      _categoryOpen = false;
      // 選んでいたカテゴリが新しいタブにない場合だけ先頭に戻す（維持優先）
      final allCategories = _getAllCategories(isWork);
      if (!allCategories.contains(_currentCategory)) {
        _currentCategory = allCategories.first;
      }
    });
  }

  /// カテゴリをポップアップで開く（1 つ選んで「反映」でグラフを切り替える）
  Future<void> _openCategory(SkillsData? data) async {
    setState(() => _categoryOpen = true);
    await showAppFilterModal<void>(
      context,
      builder: (ctx) => SkillsCategoryPanel(
        groups: _panelGroups(data),
        current: _currentCategory,
        labelOf: _label,
        onApply: (c) {
          Navigator.of(ctx).pop();
          setState(() => _currentCategory = c);
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
    if (mounted) setState(() => _categoryOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 高さは中身なり（スクロールはページ全体で 1 つにまとめる）
      padding: SkillsHeaderConfig.sectionPadding,
      child: FutureBuilder<List<SkillsData>>(
        future: _skillsFuture,
        builder: (context, snapshot) {
          final SkillsData? data =
              snapshot.hasData ? snapshot.data![_isWork ? 0 : 1] : null;
          final categoryData = data?[_currentCategory] ?? const <String, double>{};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkillsHeader(),
              SkillsHeaderConfig.headerSpacing,

              // Work/Private ・ Bar/Pie
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSizes.space12,
                runSpacing: AppSizes.space12,
                children: [
                  AppSegment<bool>(
                    value: _isWork,
                    onChanged: _selectTab,
                    items: const [
                      AppSegmentItem(value: true, label: AppTexts.work, icon: Icons.work_outline),
                      AppSegmentItem(value: false, label: AppTexts.private, icon: Icons.lock_outline),
                    ],
                  ),
                  // 狭い画面では折り返す
                  Wrap(
                    spacing: AppSizes.space12,
                    runSpacing: AppSizes.space12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SkillsCategoryButton(
                        currentLabel: _label(_currentCategory),
                        open: _categoryOpen,
                        onPressed: () => _openCategory(data),
                      ),
                      SkillsChartSwitch(
                        showPie: _showPie,
                        onToggle: (v) => setState(() => _showPie = v),
                      ),
                    ],
                  ),
                ],
              ),

              SkillsHeaderConfig.chartSpacing,

              // グラフ
              SizedBox(
                width: double.infinity,
                child: !snapshot.hasData
                    ? const SizedBox(
                        height: SkillsCardConfig.minHeight,
                        child: Center(child: AppLoadingIndicator()),
                      )
                    : categoryData.isEmpty
                        ? SizedBox(
                            height: SkillsCardConfig.minHeight,
                            child: Center(
                            child: Text(
                              AppTexts.noData,
                              style: AppStyles.secondary(context),
                            ),
                            ),
                          )
                        : SkillsCard(
                            data: categoryData,
                            showPie: _showPie,
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
