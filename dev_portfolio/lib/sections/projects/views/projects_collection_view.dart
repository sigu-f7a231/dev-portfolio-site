// lib/sections/projects/project_collection_view.dart
import 'package:flutter/material.dart';
import '../models/projects_model.dart';

class ProjectCollectionView extends StatelessWidget {
  final List<Project> projects;
  final bool isDark;

  const ProjectCollectionView({super.key, required this.projects, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final p = projects[index];
        return Card(
          color: isDark ? Colors.grey[850] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                Text(p.description,
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 4),
                Text('Period: ${p.period}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45)),
              ],
            ),
          ),
        );
      },
    );
  }
}