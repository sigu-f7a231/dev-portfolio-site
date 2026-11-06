// lib/state/providers.dart
//
// アプリ全体の状態（Riverpod の Provider）
// - main.dart の ProviderScope の中で使う。テストでは ProviderScope(overrides: [...]) で差し替えられる
// - データの読み書きは Repository（lib/data/）。ここは「どの Repository を使うか」「データが変わったこと」と、
//   画面が読むもの（テーマ・プロフィール・Work / Private・Skills の集計・Projects の一覧）を持つ
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/portfolio_repository.dart';
import '../models/profile.dart';
import '../sections/projects/data/projects_private.dart';
import '../sections/projects/data/projects_work.dart';
import '../sections/projects/models/projects_model.dart';
import '../sections/skills/data/skills_private.dart';
import '../sections/skills/data/skills_work.dart';
import '../utils/profile_store.dart';

/// 読み込みに失敗しても繰り返さない（Riverpod 3 は既定で繰り返す。読めないデータは何度読んでも読めないため）
Duration? _noRetry(int retryCount, Object error) => null;

// ============================================================
// テーマ
// ============================================================

/// ライト / ダーク（保存しない。開くといつもライト）
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  /// [initial] はテストで最初のテーマを決めるため
  ThemeModeNotifier([this.initial = ThemeMode.light]);

  final ThemeMode initial;

  @override
  ThemeMode build() => initial;

  /// ダークにするか
  void toggle(bool isDark) => state = isDark ? ThemeMode.dark : ThemeMode.light;
}

// ============================================================
// データ
// ============================================================

/// 使う Repository（今は PortfolioRepository.instance。API の実装に替えるときはここを差し替える）
final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) => PortfolioRepository.instance);

/// 表示するデータ（Work / Private・プロフィールと一緒に読んだもの）が変わった回数
/// 増えると、下の Work / Private を読み直す。HomePage は Skills / Projects を作り直す（選んでいたタブ・フィルターは初めに戻る）
final dataRevisionProvider = NotifierProvider<DataRevision, int>(DataRevision.new);

class DataRevision extends Notifier<int> {
  @override
  int build() => 0;

  /// データが変わったことを知らせる
  void bump() => state++;
}

/// 表示中のプロフィール（なければ null）。持っているのは ProfileStore（入力画面・スキルシートの作成からも使うため）で、
/// 変わったらこの Provider も変わる
final profileProvider = Provider<Profile?>((ref) {
  final store = ProfileStore.instance;
  void changed() => ref.invalidateSelf();
  store.addListener(changed);
  ref.onDispose(() => store.removeListener(changed));
  return store.value;
});

/// Work / Private のプロジェクト（構造のデータ）
typedef ProjectRecords = ({List<DataRecord> work, List<DataRecord> private});

/// 表示する Work / Private（Repository から。データが変わったら読み直す）
final projectRecordsProvider = FutureProvider<ProjectRecords>((ref) async {
  ref.watch(dataRevisionProvider);
  final repository = ref.watch(portfolioRepositoryProvider);
  final results = await Future.wait([
    repository.loadProjects(ProjectsKind.work),
    repository.loadProjects(ProjectsKind.private),
  ]);
  return (work: results[0], private: results[1]);
}, retry: _noRetry);

/// Skills の集計（[0] = Work、[1] = Private。分類 → 項目 → 割合%）
final skillsDataProvider = FutureProvider<List<Map<String, Map<String, double>>>>((ref) async {
  final records = await ref.watch(projectRecordsProvider.future);
  return [workSkillsOf(records.work), privateSkillsOf(records.private)];
}, retry: _noRetry);

/// Projects の一覧（[0] = Work、[1] = Private）
final projectsListProvider = FutureProvider<List<List<Project>>>((ref) async {
  final records = await ref.watch(projectRecordsProvider.future);
  return [workProjectsOf(records.work), privateProjectsOf(records.private)];
}, retry: _noRetry);
