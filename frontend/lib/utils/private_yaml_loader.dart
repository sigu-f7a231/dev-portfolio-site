// lib/utils/private_yaml_loader.dart
//
// Private の YAML を読む手伝い。どこから読むか（セッション → 起動時の指定 → サンプル）は Repository（lib/data/）に任せる
import 'package:yaml/yaml.dart';
import '../data/portfolio_repository.dart';

class PrivateYamlLoader {
  PrivateYamlLoader._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

  /// 自分のデータとして保存する
  static Future<void> setCustomYaml(String yamlString) =>
      PortfolioRepository.instance.saveProjectsText(ProjectsKind.private, yamlString);

  /// 保存したものを消す（サンプルに戻る）
  static Future<void> clearCustomYaml() => PortfolioRepository.instance.clearProjects(ProjectsKind.private);

  /// 表示する YAML の文字
  static Future<String> loadYamlString() => PortfolioRepository.instance.loadProjectsText(ProjectsKind.private);

  /// 表示する YAML を YamlMap として読む（トップが Map でなければ型のエラー）
  static Future<YamlMap> loadPrivateYamlMap() async => loadYaml(await loadYamlString()) as YamlMap;
}
