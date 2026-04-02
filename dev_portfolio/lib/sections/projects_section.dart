import 'package:flutter/material.dart';

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.orange,
      child: const Center(
        child: Text(
          'Projects Section',
          style: TextStyle(fontSize: 32, color: Colors.white),
        ),
      ),
    );
  }
}