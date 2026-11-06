import 'skills_aggregator.dart';
import '../../../utils/tech_catalog.dart';

/// Private のプロジェクト（構造のデータ）→ 分類ごとの割合（%）。読み込みは Provider（lib/state/providers.dart）が Repository から行う
Map<String, Map<String, double>> privateSkillsOf(List<Object?> rawProjects) {
  // Skills・Tools に書かれたフロントエンド・バックエンドなどは、本来の分類に移してから数える
  final projects = redistributeProjects(rawProjects);
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
  };
}