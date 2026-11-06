// lib/sections/projects/sort/project_sort.dart
//
// Projects の並び替え（ツールバーの［並び替え］で選ぶ）
// - 一覧（List / Collection）と、詳細の ‹ › で移る順番の両方に使う
// - 期間が読み取れないプロジェクトは、どの並びでも最後に置く
// - 同じ値のときはプロジェクト名の順
import '../../../constants/app_texts.dart';
import '../models/projects_model.dart';

enum ProjectSort {
  /// 開始が古い順（これまでの並び）
  startOldest(AppTexts.sortStartOldest),

  /// 開始が新しい順
  startNewest(AppTexts.sortStartNewest),

  /// 終了が新しい順（進行中がいちばん上）
  endNewest(AppTexts.sortEndNewest),

  /// 期間が長い順
  durationLongest(AppTexts.sortDurationLongest),

  /// 期間が短い順
  durationShortest(AppTexts.sortDurationShortest),

  /// プロジェクト名の順
  title(AppTexts.sortTitle);

  final String label;
  const ProjectSort(this.label);

  /// はじめの並び
  static const ProjectSort initial = ProjectSort.startOldest;

  /// 並び替えた新しいリストを返す（元のリストは変えない）
  List<Project> apply(Iterable<Project> projects) {
    int byTitle(Project a, Project b) => a.title.compareTo(b.title);

    int compare(Project a, Project b) {
      if (this != ProjectSort.title) {
        // 期間がないものは最後
        final av = a.hasValidPeriod, bv = b.hasValidPeriod;
        if (av != bv) return av ? -1 : 1;
        // 期間がないもの同士は名前の順（periodEnd は呼ぶたびに今の時刻になり、比べるたびに結果が変わるため）
        if (!av) return byTitle(a, b);
      }
      final c = switch (this) {
        ProjectSort.startOldest => a.periodStart.compareTo(b.periodStart),
        ProjectSort.startNewest => b.periodStart.compareTo(a.periodStart),
        // 進行中がいちばん上。進行中同士は同じ扱い（periodEnd は呼ぶたびに今の時刻になるので比べない）
        ProjectSort.endNewest => a.isOngoing == b.isOngoing
            ? (a.isOngoing ? 0 : b.periodEnd.compareTo(a.periodEnd))
            : (a.isOngoing ? -1 : 1),
        ProjectSort.durationLongest => b.durationMonths.compareTo(a.durationMonths),
        ProjectSort.durationShortest => a.durationMonths.compareTo(b.durationMonths),
        ProjectSort.title => byTitle(a, b),
      };
      return c != 0 ? c : byTitle(a, b);
    }

    return projects.toList()..sort(compare);
  }
}
