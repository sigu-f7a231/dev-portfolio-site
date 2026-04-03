// lib/sections/projects/projects_work.dart
import 'package:flutter/services.dart';
import '../models/projects_model.dart';
import 'package:yaml/yaml.dart';

Future<List<Project>> loadWorkProjects() async {
  final yamlString = await rootBundle.loadString('assets/data/projects_work.yaml');
  final yamlMap = loadYaml(yamlString) as YamlMap;
  final list = (yamlMap['projects'] as YamlList)
      .map((e) => Project.fromMap(Map<String, dynamic>.from(e)))
      .toList();
  return list;
}