// lib/data/portfolio_repository.dart
//
// 表示するデータ（プロフィール・Work / Private）を読み書きする入口（Repository）
// - 画面・集計・ダイアログは、データがどこにあるかを知らず、ここだけを通す
// - 実装が用意するのは「構造のデータ（records.dart の DataRecord）」の読み書き 5 つだけ（下の ===== 実装が用意するもの =====）
//   YAML の文字での読み書き・サンプルへのフォールバックは、この 5 つから作る（既定の作り方）
// - 今の実装は LocalPortfolioRepository（このタブの sessionStorage・起動時の指定。元の文字をそのまま保つため、文字の読み書きも上書き）
// - 次の構成（docs/plan/）では、Hono の API（Firestore）を呼ぶ実装を作り、5 つを書いて差し替える。テストでは偽物に差し替えられる
// - Riverpod からは portfolioRepositoryProvider（lib/state/providers.dart）で取り出す
import 'package:flutter/foundation.dart';

import '../models/profile.dart';
import '../utils/asset_text.dart';
import 'local_portfolio_repository.dart';
import 'records.dart';

export 'records.dart' show DataRecord;

/// Work / Private の種類（名前は YAML のテンプレート・sessionStorage のキーと同じ）
enum ProjectsKind {
  work,
  private;

  /// 画面で使っている文字（'work' / 'private'）から。'work' 以外は Private
  static ProjectsKind of(String dataType) => dataType == 'work' ? work : private;
}

/// プロフィールを読んだ結果
class ProfileLoadResult {
  const ProfileLoadResult({this.profile, this.errors = const []});

  /// 読めたプロフィール（なければ null。入力画面を出す）
  final Profile? profile;

  /// 起動時に指定したプロフィールが読めなかった理由（入力画面に出す。なければ空）
  final List<String> errors;
}

abstract class PortfolioRepository {
  static PortfolioRepository _instance = LocalPortfolioRepository();

  /// 今使っている Repository（アプリ全体で 1 つ）
  static PortfolioRepository get instance => _instance;

  /// テストで偽物に差し替える（終わったら [reset] で元に戻す）
  @visibleForTesting
  static set instance(PortfolioRepository value) => _instance = value;

  /// 元の実装（LocalPortfolioRepository）に戻す
  @visibleForTesting
  static void reset() => _instance = LocalPortfolioRepository();

  /// ログイン・ログアウトで実装を切り替える（AuthController が呼ぶ。ログイン中は API、ログアウトしたら Local）
  static void use(PortfolioRepository repository) => _instance = repository;

  /// 自分のデータがないときに見せるサンプル（テンプレート）の場所
  static String sampleAssetPath(ProjectsKind kind) => 'assets/data/format_${kind.name}.yaml';

  // ===== 実装が用意するもの（構造のデータ） =====

  /// プロフィール（home・about・sheet の Map）。なければ null
  Future<DataRecord?> loadProfileRecord();

  /// プロフィールを保存する
  Future<void> saveProfileRecord(DataRecord record);

  /// 自分の Work / Private のプロジェクト。なければ null（サンプルを見せる）
  Future<List<DataRecord>?> loadProjectRecords(ProjectsKind kind);

  /// Work / Private のプロジェクトを保存する
  Future<void> saveProjectRecords(ProjectsKind kind, List<DataRecord> records);

  /// 保存した Work / Private を消す（サンプルに戻る）
  Future<void> clearProjects(ProjectsKind kind);

  // ===== 画面が使うもの（既定は上の 5 つから作る） =====

  /// 表示するプロフィール
  Future<ProfileLoadResult> loadProfile() async {
    final record = await loadProfileRecord();
    if (record == null) return const ProfileLoadResult();
    return ProfileLoadResult(profile: Profile.parse(yamlOfRecord(record)).profile);
  }

  /// プロフィール（YAML の文字）を保存する
  /// 形が違えば FormatException（書き方の誤りは YamlException）で、保存しない
  Future<void> saveProfile(String text) async => saveProfileRecord(recordOfYaml(text));

  /// 表示する Work / Private のプロジェクト。自分のデータがなければサンプル
  Future<List<DataRecord>> loadProjects(ProjectsKind kind) async =>
      await loadProjectRecords(kind) ?? projectRecordsOfYaml(await loadAssetText(sampleAssetPath(kind)));

  /// 表示する Work / Private（YAML の文字）。自分のデータがなければサンプル
  Future<String> loadProjectsText(ProjectsKind kind) async {
    final records = await loadProjectRecords(kind);
    return records == null ? loadAssetText(sampleAssetPath(kind)) : yamlOfProjects(records);
  }

  /// Work / Private（YAML の文字）を自分のデータとして保存する
  /// 形が違えば FormatException（書き方の誤りは YamlException）で、保存しない
  Future<void> saveProjectsText(ProjectsKind kind, String text) async =>
      saveProjectRecords(kind, projectRecordsOfYaml(text));

  /// 今表示している Work / Private がサンプルか（自分のデータがないか）
  Future<bool> isSampleProjects(ProjectsKind kind) async => await loadProjectRecords(kind) == null;
}
