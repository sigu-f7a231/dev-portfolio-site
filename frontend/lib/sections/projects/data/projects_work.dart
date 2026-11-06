import '../../../utils/work_yaml_loader.dart';
import 'package:yaml/yaml.dart';
import '../models/projects_model.dart';

Future<List<Project>> loadWorkProjects() async {
  final yamlMap = await WorkYamlLoader.loadWorkYamlMap();

  final list = (yamlMap['projects'] as YamlList)
      .map((e) => Project.fromMap(Map<String, dynamic>.from(e)))
      .toList();

  return list;
}