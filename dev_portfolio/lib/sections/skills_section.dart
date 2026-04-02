import 'package:flutter/material.dart';

class SkillsSection extends StatelessWidget {
  const SkillsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.deepPurple,
      child: const Center(
        child: Text(
          'Skills Section',
          style: TextStyle(fontSize: 32, color: Colors.white),
        ),
      ),
    );
  }
}