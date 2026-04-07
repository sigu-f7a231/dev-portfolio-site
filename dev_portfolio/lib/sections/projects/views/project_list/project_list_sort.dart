// lib/sections/projects/views/project_list/project_list_sort.dart
import '../../models/projects_model.dart';

int sortProjects(Project a, Project b) {
  DateTime parseStart(String period) {
    try {
      final start = period.split('-').first.trim();
      final parts = start.split('.');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return DateTime(1900);
    }
  }

  bool isOngoing(String period) =>
      period.contains('現在') || period.toLowerCase().contains('present');

  final aOngoing = isOngoing(a.period);
  final bOngoing = isOngoing(b.period);

  if (aOngoing && !bOngoing) return 1; // 進行中は最後
  if (!aOngoing && bOngoing) return -1;

  return parseStart(a.period).compareTo(parseStart(b.period));
}