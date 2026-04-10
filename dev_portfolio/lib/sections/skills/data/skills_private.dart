import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'skills_aggregator.dart';

Future<Map<String, Map<String, double>>> loadPrivateSkillsAll() async {
  final yamlString =
      await rootBundle.loadString('assets/data/projects_private.yaml');

  final yamlMap = loadYaml(yamlString) as YamlMap;
  final projects = yamlMap['projects'] as YamlList;

  return {
    'server_os': aggregateCategory(projects, 'server_os'),
    'db': aggregateCategory(projects, 'db'),
    'tools': aggregateCategory(projects, 'tools'),

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
  };
}