// lib/sections/skills/data/skills_private.dart

import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'skills_aggregator.dart';

Future<Map<String, Map<String, double>>> loadPrivateSkillsAll() async {
  final yamlString =
      await rootBundle.loadString('assets/data/projects_private.yaml');
  final yamlMap = loadYaml(yamlString) as YamlMap;

  final projects = yamlMap['projects'] as YamlList;

  return {
    'skills': aggregateCategory(projects, 'skills'),
    'server_os': aggregateCategory(projects, 'server_os'),
    'db': aggregateCategory(projects, 'db'),
    'tools_fw': aggregateCategory(projects, 'tools_fw'),
  };
}

