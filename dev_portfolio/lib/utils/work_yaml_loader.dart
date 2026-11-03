import 'package:flutter/services.dart';
import 'browser/browser.dart'; // sessionStorage（Web は package:web、テストはメモリ）
import 'package:yaml/yaml.dart';

class WorkYamlLoader {
  // Work用の一時カスタムYAML文字列を保持する変数（メモリ用フォールバック）
  static String? _customYamlString; // 修正: staticの重複を回避

  /// カスタムYAMLを一時保存する
  static void setCustomYaml(String yamlString) {
    _customYamlString = yamlString;
    // セッションストレージにも確実に保存しておく
    SessionStore.write('work', yamlString);
  }

  /// カスタムYAMLをクリアする
  static void clearCustomYaml() {
    _customYamlString = null;
    SessionStore.remove('work');
  }

  /// YAML文字列を取得する
  /// 優先順位: 
  /// 1. セッションストレージの 'work' キー
  /// 2. メモリ上の変数 (_customYamlString)
  /// 3. アセットファイル (assets/data/projects_work.yaml)
  static Future<String> loadYamlString() async {
    // 1. セッションストレージから先に読み込みを試みる
    final sessionYaml = SessionStore.read('work');
    if (sessionYaml != null && sessionYaml.isNotEmpty) {
      return sessionYaml;
    }

    // 2. メモリ上の変数にあればそれを使う
    if (_customYamlString != null) {
      return _customYamlString!;
    }

    // 3. どちらもなければアセットから読み込む
    return await rootBundle.loadString('assets/data/format_work.yaml');
  }

  /// 共通のパース処理を含めたYamlMapの取得
  static Future<YamlMap> loadWorkYamlMap() async {
    final yamlString = await loadYamlString();
    return loadYaml(yamlString) as YamlMap;
  }
}