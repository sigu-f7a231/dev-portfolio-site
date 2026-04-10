import 'package:flutter/material.dart';
import '../../models/projects_model.dart';
import '../../../../utils/language_utils.dart';
import '../state/project_filter_state.dart';
import 'project_filter_chips.dart';

class ProjectsFilter extends StatefulWidget {
  final List<Project> projects;
  final int tabIndex;
  final bool isDark;
  final ValueChanged<Map<String, List<String>>>? onApply;

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
  bool _expanded = false;

  final Map<String, List<String>> _selectedFilters =
      ProjectFilterState.initial().selectedFilters;

  List<String> _unique(List<String> v) => v.toSet().toList();

  void _clear() {
    setState(() {
      for (final k in _selectedFilters.keys) {
        _selectedFilters[k]!.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showWorkflow = widget.tabIndex == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          label: const Text('フィルター'),
        ),

        if (_expanded)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilterChipsSection(
                title: 'Server OS',
                items: _unique(widget.projects.expand((e) => e.serverOSList).toList()),
                selectedItems: _selectedFilters['serverOS']!,
                onSelected: (v) => setState(() {
                  _selectedFilters['serverOS']!.contains(v)
                      ? _selectedFilters['serverOS']!.remove(v)
                      : _selectedFilters['serverOS']!.add(v);
                }),
                isDark: widget.isDark,
              ),

              FilterChipsSection(
                title: 'DB',
                items: _unique(widget.projects.expand((e) => e.dbList).toList()),
                selectedItems: _selectedFilters['db']!,
                onSelected: (v) => setState(() {
                  _selectedFilters['db']!.contains(v)
                      ? _selectedFilters['db']!.remove(v)
                      : _selectedFilters['db']!.add(v);
                }),
                isDark: widget.isDark,
              ),

              FilterChipsSection(
                title: 'Tools',
                items: _unique(widget.projects.expand((e) => e.toolsList).toList()),
                selectedItems: _selectedFilters['tools']!,
                onSelected: (v) => setState(() {
                  _selectedFilters['tools']!.contains(v)
                      ? _selectedFilters['tools']!.remove(v)
                      : _selectedFilters['tools']!.add(v);
                }),
                isDark: widget.isDark,
              ),

              FilterChipsSection(
                title: 'Backend',
                items: _unique(widget.projects.expand((e) => e.backendList).toList()),
                selectedItems: _selectedFilters['backendFrameworks']!,
                onSelected: (v) => setState(() {
                  _selectedFilters['backendFrameworks']!.contains(v)
                      ? _selectedFilters['backendFrameworks']!.remove(v)
                      : _selectedFilters['backendFrameworks']!.add(v);
                }),
                isDark: widget.isDark,
              ),

              FilterChipsSection(
                title: 'Frontend',
                items: _unique(widget.projects.expand((e) => e.frontendList).toList()),
                selectedItems: _selectedFilters['frontendFrameworks']!,
                onSelected: (v) => setState(() {
                  _selectedFilters['frontendFrameworks']!.contains(v)
                      ? _selectedFilters['frontendFrameworks']!.remove(v)
                      : _selectedFilters['frontendFrameworks']!.add(v);
                }),
                isDark: widget.isDark,
              ),

              FilterChipsSection(
                title: 'Skills',
                items: _unique(widget.projects.expand((e) => e.skillsList).toList()),
                selectedItems: _selectedFilters['skills']!,
                onSelected: (v) => setState(() {
                  _selectedFilters['skills']!.contains(v)
                      ? _selectedFilters['skills']!.remove(v)
                      : _selectedFilters['skills']!.add(v);
                }),
                isDark: widget.isDark,
              ),

              if (showWorkflow)
                FilterChipsSection(
                  title: 'Workflow',
                  items: _unique(widget.projects
                      .expand((e) => e.workflow.keys)
                      .map((e) => LanguageUtils.workflowLabels['ja']?[e] ?? e)
                      .toList()),
                  selectedItems: _selectedFilters['workflow']!,
                  onSelected: (v) => setState(() {
                    _selectedFilters['workflow']!.contains(v)
                        ? _selectedFilters['workflow']!.remove(v)
                        : _selectedFilters['workflow']!.add(v);
                  }),
                  isDark: widget.isDark,
                ),

              Row(
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
                    onPressed: _clear,
                    child: const Text('クリア'),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}