// lib/src/data_store.dart
//
// DATA_DIR にある YAML（profile.yaml / work.yaml / private.yaml）を読み、
// JSON にできる形（Map / List / 値）にして返す。
// - 確認の内容はアプリ（frontend）のアップロード時と同じ：
//   プロフィールは home.name / home.role / home.tagline / about.intro が必須、
//   プロジェクトは projects 配列で各要素に title が必須、Work は workflow が必須、Private は workflow を書かない
// - ファイルの更新日時が変わったときだけ読み直す（毎回 YAML を解析しない）
import 'dart:io';

import 'package:yaml/yaml.dart';

enum ProjectType { work, private }

/// ファイルがない
class DataNotFound implements Exception {
  DataNotFound(this.name);
  final String name;

  @override
  String toString() => 'DataNotFound: $name.yaml がありません';
}

/// 中身が正しくない（YAML の書き方の誤り・必須項目がない）
class InvalidData implements Exception {
  InvalidData(this.name, this.message);
  final String name;
  final String message;

  @override
  String toString() => 'InvalidData($name.yaml): $message';
}

class DataStore {
  DataStore(this.directory);

  final Directory directory;
  final Map<String, _Cached> _cache = {};

  /// プロフィール（Home / About）
  Future<Map<String, Object?>> profile() async {
    const name = 'profile';
    final data = _asMap(await _read(name), name, 'ファイル全体');
    final home = _asMap(data['home'], name, 'home');
    final about = _asMap(data['about'], name, 'about');
    for (final key in const ['name', 'role', 'tagline']) {
      _requireText(home[key], name, 'home.$key');
    }
    _requireText(about['intro'], name, 'about.intro');
    return data;
  }

  /// Work / Private のプロジェクト
  Future<Map<String, Object?>> projects(ProjectType type) async {
    final name = type.name;
    final data = _asMap(await _read(name), name, 'ファイル全体');
    final projects = data['projects'];
    if (projects is! List) {
      throw InvalidData(name, 'projects（配列）がありません');
    }
    for (var i = 0; i < projects.length; i++) {
      final where = 'projects[$i]';
      final p = _asMap(projects[i], name, where);
      _requireText(p['title'], name, '$where.title');
      final hasWorkflow = p.containsKey('workflow');
      if (type == ProjectType.work && !hasWorkflow) {
        throw InvalidData(name, '$where.workflow は Work では必須です');
      }
      if (type == ProjectType.private && hasWorkflow) {
        throw InvalidData(name, '$where.workflow は Private には書きません');
      }
    }
    return data;
  }

  Future<Object?> _read(String name) async {
    final file = File('${directory.path}/$name.yaml');
    if (!await file.exists()) throw DataNotFound(name);

    final modified = await file.lastModified();
    final cached = _cache[name];
    if (cached != null && cached.modified == modified) return cached.value;

    final Object? value;
    try {
      value = _toPlain(loadYaml(await file.readAsString()));
    } on YamlException catch (e) {
      throw InvalidData(name, 'YAML の書き方に誤りがあります: ${e.message}');
    } on FileSystemException catch (e) {
      // 権限がないなど（コンテナの実行ユーザーが読めないとき）
      throw InvalidData(name, 'ファイルを読めません: ${e.osError?.message ?? e.message}');
    }
    _cache[name] = _Cached(modified, value);
    return value;
  }

  /// YamlMap / YamlList を、jsonEncode できる Map / List にする
  static Object? _toPlain(Object? node) {
    if (node is YamlMap) {
      return {
        for (final e in node.entries) e.key.toString(): _toPlain(e.value),
      };
    }
    if (node is YamlList) return [for (final v in node) _toPlain(v)];
    return node;
  }

  static Map<String, Object?> _asMap(Object? v, String name, String where) {
    if (v is Map<String, Object?>) return v;
    throw InvalidData(name, '$where がありません（キー: 値 の形で書いてください）');
  }

  static void _requireText(Object? v, String name, String where) {
    if (v == null || v.toString().trim().isEmpty) {
      throw InvalidData(name, '$where は必須です');
    }
  }
}

class _Cached {
  _Cached(this.modified, this.value);
  final DateTime modified;
  final Object? value;
}
