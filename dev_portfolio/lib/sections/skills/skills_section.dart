import 'package:flutter/material.dart';
import 'data/skills_work.dart';
import 'data/skills_private.dart';
import 'widgets/skills_header.dart';
import 'widgets/skills_card.dart';

class SkillsSection extends StatefulWidget {
  const SkillsSection({super.key});

  @override
  State<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection>
    with TickerProviderStateMixin {
  bool _showPie = false;

  late Future<Map<String, Map<String, double>>> _workSkillsFuture;
  late Future<Map<String, Map<String, double>>> _privateSkillsFuture;

  /// 全カテゴリ
  final List<String> _baseCategories = const [
    'server_os',
    'db',
    'tools',
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
    'skills',
  ];

  /// workのみ追加
  final List<String> _workExtra = const ['workflow'];

  /// 表示TOP
  final List<String> _topDisplayCategories = const [
    'server_os',
    'db',
    'backend_frameworks',
    'frontend_frameworks',
    'aws_services',
  ];

  String _currentCategory = 'server_os';
  bool _isWork = true;

  @override
  void initState() {
    super.initState();
    _workSkillsFuture = loadWorkSkillsAll();
    _privateSkillsFuture = loadPrivateSkillsAll();
  }

  List<String> _getAllCategories(bool isWork) {
    return isWork ? [..._baseCategories, ..._workExtra] : _baseCategories;
  }

  List<String> _getDropdownCategories(bool isWork) {
    final all = _getAllCategories(isWork);
    return all.where((c) => !_topDisplayCategories.contains(c)).toList();
  }

  Map<String, double> _getCategoryData(
    Map<String, Map<String, double>> data,
    String category,
  ) {
    return data[category] ?? {};
  }

  final Map<String, String> _labelOverrides = {
    'server_os': 'OS',
    'db': 'DB',
    'tools': 'Tools',
    'backend_frameworks': 'Backend',
    'frontend_frameworks': 'Frontend',
    'ui_frameworks': 'UI Frameworks',
    'testing_frameworks': 'Testing Frameworks',
    'cloud_platforms': 'Cloud Platforms',
    'aws_services': 'AWS',
    'gcp_services': 'GCP',
    'azure_services': 'Azure',
    'container': 'Container',
    'container_orchestration': 'Container Orchestration',
    'ai_services': 'AI Services',
    'skills': 'Skills',
    'workflow': 'Workflow',
  };

  String _label(String key) =>
      _labelOverrides[key] ??
      key.replaceAll('_', ' ').split(' ').map((e) {
        if (e.isEmpty) return '';
        return '${e[0].toUpperCase()}${e.substring(1)}';
      }).join(' ');

  Widget _emptyState(bool isDark) {
    return Center(
      child: Text(
        'データがありません',
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownCategories = _getDropdownCategories(_isWork);

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          /// HEADER
          SkillsHeader(
            showPie: _showPie,
            isDark: isDark,
            onToggle: (v) => setState(() => _showPie = v),
          ),

          const SizedBox(height: 12),

          /// WORK / PRIVATE（★修正ここ）
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text("Work")),
                    ButtonSegment(value: false, label: Text("Private")),
                  ],
                  selected: {_isWork},
                  onSelectionChanged: (v) {
                    setState(() {
                      final newIsWork = v.first;
                      final allCategories = _getAllCategories(newIsWork);

                      _isWork = newIsWork;

                      // ★重要：存在しない場合のみ補正（維持優先）
                      if (!allCategories.contains(_currentCategory)) {
                        _currentCategory = allCategories.first;
                      }
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// TOP5 + dropdown
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: _topDisplayCategories.map((key) {
                    final selected = _currentCategory == key;

                    return ChoiceChip(
                      label: Text(_label(key)),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _currentCategory = key);
                      },
                    );
                  }).toList(),
                ),
              ),

              PopupMenuButton<String>(
                icon: const Icon(Icons.arrow_drop_down),
                onSelected: (value) {
                  setState(() => _currentCategory = value);
                },
                itemBuilder: (context) {
                  return dropdownCategories
                      .map((c) => PopupMenuItem(
                            value: c,
                            child: Text(_label(c)),
                          ))
                      .toList();
                },
              ),

              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_label(_currentCategory)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// CONTENT
          Expanded(
            child: FutureBuilder<Map<String, Map<String, double>>>(
              future: _isWork ? _workSkillsFuture : _privateSkillsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                final categoryData =
                    _getCategoryData(data, _currentCategory);

                if (categoryData.isEmpty) {
                  return _emptyState(isDark);
                }

                return SkillsCard(
                  data: categoryData,
                  isDark: isDark,
                  showPie: _showPie,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}