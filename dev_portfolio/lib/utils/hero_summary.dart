// lib/utils/hero_summary.dart
//
// Home のまとめ（開発経験・プロジェクトの件数・直近のプロジェクト）を Work / Private の案件から作る
// Skills・Projects の中身をくり返すのではなく、「全体でどのくらいか」「いちばん新しいのは何か」だけを出す
//
// Flutter に依存しない（テストからそのまま呼べる）。
import '../sections/projects/models/projects_model.dart';

class HeroSummary {
  /// いちばん古い案件の開始（期間が読めるものだけ。Work を優先し、Work になければ Private）
  final DateTime? since;

  /// [since] から今日までの月数（[since] がなければ 0）
  final int experienceMonths;

  final int workCount;
  final int privateCount;

  /// 開始がいちばん新しい案件（期間が読めるものだけ）
  final Project? latest;

  /// [latest] が Private か
  final bool latestIsPrivate;

  const HeroSummary({
    required this.since,
    required this.experienceMonths,
    required this.workCount,
    required this.privateCount,
    required this.latest,
    required this.latestIsPrivate,
  });

  int get totalCount => workCount + privateCount;

  /// 何も出すものがない（案件が 0 件）
  bool get isEmpty => totalCount == 0;

  static HeroSummary of(List<Project> work, List<Project> private, {DateTime? now}) {
    final today = now ?? DateTime.now();
    List<Project> dated(List<Project> list) => [for (final p in list) if (p.hasValidPeriod) p];
    final datedWork = dated(work), datedPrivate = dated(private);

    // 開発経験：業務の案件の最初から（業務がなければ個人開発の最初から）
    final base = datedWork.isNotEmpty ? datedWork : datedPrivate;
    DateTime? since;
    for (final p in base) {
      if (since == null || p.periodStart.isBefore(since)) since = p.periodStart;
    }
    final months = since == null
        ? 0
        : ((today.year * 12 + today.month) - (since.year * 12 + since.month) + 1).clamp(1, 1200);

    // 直近：開始がいちばん新しいもの（同じなら Work を先に）
    Project? latest;
    var latestIsPrivate = false;
    for (final (p, isPrivate) in [
      for (final p in datedWork) (p, false),
      for (final p in datedPrivate) (p, true),
    ]) {
      if (latest == null || p.periodStart.isAfter(latest.periodStart)) {
        latest = p;
        latestIsPrivate = isPrivate;
      }
    }

    return HeroSummary(
      since: since,
      experienceMonths: months,
      workCount: work.length,
      privateCount: private.length,
      latest: latest,
      latestIsPrivate: latestIsPrivate,
    );
  }
}
