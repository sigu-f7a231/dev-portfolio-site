import 'package:yaml/yaml.dart';
import '../models/projects_model.dart';
import '../../../utils/private_yaml_loader.dart';

Future<List<Project>> loadPrivateProjects() async {

  final yamlMap = await PrivateYamlLoader.loadPrivateYamlMap();

  final list = (yamlMap['projects'] as YamlList)
      .map((e) => Project.fromMap(Map<String, dynamic>.from(e)))
      .toList();

  return list;
}