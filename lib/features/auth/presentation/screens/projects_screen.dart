import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow_ai/shared/models/project_model.dart';
import 'package:taskflow_ai/shared/providers/project_progress_provider.dart';
import 'package:taskflow_ai/shared/providers/project_provider.dart';

import '../../../../app/theme/app_theme.dart';
import '../widgets/project_card.dart';
import 'create_project_screen.dart';
import 'project_details_screen.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateProject() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const CreateProjectScreen()),
    );

    if (!mounted || result == null) return;

    final project = ProjectModel.fromMap(result);

    ref.read(projectProvider.notifier).addProject(project);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project created successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openProjectDetails(ProjectModel project, ProjectProgress progress) {
    final details = {
      ...project.toMap(),
      'completedTasks': progress.completedTasks,
      'totalTasks': progress.totalTasks,
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailsScreen(project: details),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectProvider);

    final query = _searchController.text.trim().toLowerCase();

    final filteredProjects = projects.where((project) {
      return project.title.toLowerCase().contains(query) ||
          project.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Projects',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Organise your work into projects',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search projects...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filteredProjects.isEmpty
                    ? const Center(
                        child: Text(
                          'No projects found',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = filteredProjects[index];

                          final progress = ref.watch(
                            projectProgressProvider(project.title),
                          );

                          return ProjectCard(
                            title: project.title,
                            description: project.description,
                            completedTasks: progress.completedTasks,
                            totalTasks: progress.totalTasks,
                            status: project.status,
                            onTap: () {
                              _openProjectDetails(project, progress);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateProject,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project'),
      ),
    );
  }
}
