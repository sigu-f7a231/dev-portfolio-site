class Skill {
  final String name;
  final double level; // 0〜100

  Skill({required this.name, required this.level});

  /// YAML Map から変換
  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      name: map['name'] as String,
      level: (map['level'] as num).toDouble(),
    );
  }
}