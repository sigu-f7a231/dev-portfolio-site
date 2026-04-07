// dev_portfolio/lib/utils/string_utils.dart
List<String> splitSkills(String skills, {String separator = ','}) {
  if (skills.isEmpty) return [];
  return skills.split(separator).map((s) => s.trim()).toList();
}