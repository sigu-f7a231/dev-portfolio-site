import '../../../utils/work_yaml_loader.dart';
import 'package:yaml/yaml.dart';
import 'skills_aggregator.dart';
import '../../../utils/tech_catalog.dart';

Future<Map<String, Map<String, double>>> loadWorkSkillsAll() async {
  final yamlMap = await WorkYamlLoader.loadWorkYamlMap();
  // Skills・Tools に書かれたフロントエンド・バックエンドなどは、本来の分類に移してから数える
  final projects = redistributeProjects(yamlMap['projects'] as YamlList);
  final toolGroups = splitToolGroups(projects);
  final skillGroups = splitSkillGroups(projects);

  return {
    'server_os': aggregateCategory(projects, 'server_os'),
    'db': aggregateCategory(projects, 'db'),
    'tools': aggregateCategory(projects, 'tools'),
    // Tools はグループ（バージョン管理・開発ツール・環境…）ごとにも数える（名前から推測。tech_catalog.dart）
    for (final g in ToolGroup.values)
      g.key: aggregateCategory(toolGroups, g.key),

    'backend_frameworks':
        aggregateCategory(projects, 'backend_frameworks'),
    'frontend_frameworks':
        aggregateCategory(projects, 'frontend_frameworks'),
    'ui_frameworks': aggregateCategory(projects, 'ui_frameworks'),
    'testing_frameworks':
        aggregateCategory(projects, 'testing_frameworks'),

    'cloud_platforms': aggregateCategory(projects, 'cloud_platforms'),
    'aws_services': aggregateCategory(projects, 'aws_services'),
    'azure_services': aggregateCategory(projects, 'azure_services'),
    'gcp_services': aggregateCategory(projects, 'gcp_services'),

    'container': aggregateCategory(projects, 'container'),
    'container_orchestration':
        aggregateCategory(projects, 'container_orchestration'),
    'ai_services': aggregateCategory(projects, 'ai_services'),

    'skills': aggregateCategory(projects, 'skills'),
    // Skills もグループ（プログラミング言語・マークアップ・データ形式・アーキテクチャ・ライブラリ…）ごとに数える
    for (final g in SkillGroup.values)
      g.key: aggregateCategory(skillGroups, g.key),
    'workflow': aggregateWorkflow(projects),
  };
}