// lib/sections/projects/projects_filter.dart
import 'package:flutter/material.dart';
import 'project_filter_chips.dart';
import '../../models/projects_model.dart';
import '../../../../utils/language_utils.dart';
import '../../../../utils/string_utils.dart'; // ← 追加

class ProjectsFilter extends StatefulWidget {
  final List<Project> projects;
  final int tabIndex; // 0: work, 1: private
  final bool isDark;
  final ValueChanged<Map<String, List<String>>>? onApply; // 反映ボタン用コールバック

  const ProjectsFilter({
    super.key,
    required this.projects,
    required this.tabIndex,
    required this.isDark,
    this.onApply,
  });

  @override
  State<ProjectsFilter> createState() => _ProjectsFilterState();
}

class _ProjectsFilterState extends State<ProjectsFilter> {
  bool _expanded = false; // 折りたたみ用
  final Map<String, List<String>> _selectedFilters = {
    'serverOS': [],
    'db': [],
    'toolsFW': [],
    'skills': [],
    'workflow': [],
  };

  List<String> _uniqueItems(List<String> items) => items.toSet().toList();

  void _clearFilters() {
    setState(() {
      for (var key in _selectedFilters.keys) {
        _selectedFilters[key]!.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showWorkflow = widget.tabIndex == 0;

    final serverOSItems = _uniqueItems(
      widget.projects
          .expand((e) => splitSkills(e.serverOS)) // ← 修正
          .toList(),
    );

    final dbItems = _uniqueItems(
      widget.projects
          .expand((e) => splitSkills(e.db)) // ← 修正
          .toList(),
    );

    final toolsFWItems = _uniqueItems(
      widget.projects
          .expand((e) => splitSkills(e.toolsFW)) // ← 修正
          .toList(),
    );

    final skillsItems = _uniqueItems(
      widget.projects
          .expand((e) => splitSkills(e.skills)) // ← 修正
          .toList(),
    );

    final workflowItems = showWorkflow
    ? _uniqueItems(widget.projects
        .expand((e) => e.workflow.keys) // ← すべてのキーを取得
        .map((key) => LanguageUtils.workflowLabels['ja']?[key] ?? key)
        .toList())
    : <String>[];

    return Align(
      alignment: Alignment.topLeft, // 全体右寄せ
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 折りたたみボタン
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            label: const Text('フィルター'),
          ),
          if (_expanded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (serverOSItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: FilterChipsSection(
                      items: serverOSItems,
                      selectedItems: _selectedFilters['serverOS']!,
                      onSelected: (val) {
                        setState(() {
                          _selectedFilters['serverOS']!.contains(val)
                              ? _selectedFilters['serverOS']!.remove(val)
                              : _selectedFilters['serverOS']!.add(val);
                        });
                      },
                      isDark: widget.isDark,
                      title: 'Server OS',
                    ),
                  ),
                if (dbItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: FilterChipsSection(
                      items: dbItems,
                      selectedItems: _selectedFilters['db']!,
                      onSelected: (val) {
                        setState(() {
                          _selectedFilters['db']!.contains(val)
                              ? _selectedFilters['db']!.remove(val)
                              : _selectedFilters['db']!.add(val);
                        });
                      },
                      isDark: widget.isDark,
                      title: 'Database',
                    ),
                  ),
                if (toolsFWItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: FilterChipsSection(
                      items: toolsFWItems,
                      selectedItems: _selectedFilters['toolsFW']!,
                      onSelected: (val) {
                        setState(() {
                          _selectedFilters['toolsFW']!.contains(val)
                              ? _selectedFilters['toolsFW']!.remove(val)
                              : _selectedFilters['toolsFW']!.add(val);
                        });
                      },
                      isDark: widget.isDark,
                      title: 'Tools / Frameworks',
                    ),
                  ),
                if (skillsItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: FilterChipsSection(
                      items: skillsItems,
                      selectedItems: _selectedFilters['skills']!,
                      onSelected: (val) {
                        setState(() {
                          _selectedFilters['skills']!.contains(val)
                              ? _selectedFilters['skills']!.remove(val)
                              : _selectedFilters['skills']!.add(val);
                        });
                      },
                      isDark: widget.isDark,
                      title: 'Skills',
                    ),
                  ),
                if (showWorkflow && workflowItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: FilterChipsSection(
                      items: workflowItems,
                      selectedItems: _selectedFilters['workflow']!,
                      onSelected: (val) {
                        setState(() {
                          _selectedFilters['workflow']!.contains(val)
                              ? _selectedFilters['workflow']!.remove(val)
                              : _selectedFilters['workflow']!.add(val);
                        });
                      },
                      isDark: widget.isDark,
                      title: 'Workflow',
                    ),
                  ),
                // 反映・クリアボタン
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start, // ボタン右寄せ
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          widget.onApply?.call(_selectedFilters);
                          setState(() => _expanded = false);
                        },
                        child: const Text('反映'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('クリア'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}