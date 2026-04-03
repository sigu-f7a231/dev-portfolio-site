// lib/sections/projects/views/project_list.dart
import 'package:flutter/material.dart';
import '../models/projects_model.dart';

class ProjectList extends StatelessWidget {
  final Future<List<Project>> future;
  final bool isDark;

  const ProjectList({super.key, required this.future, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No projects'));
        }

        final projects = snapshot.data!;
        return ListView.separated(
          itemCount: projects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final p = projects[index];
            return Card(
              color: isDark ? Colors.grey[850] : Colors.white,
              child: ListTile(
                title: Text(p.title,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                subtitle: Text(p.description,
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
              ),
            );
          },
        );
      },
    );
  }
}