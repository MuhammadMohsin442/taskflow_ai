import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow_ai/features/auth/presentation/screens/create_task_screen.dart';

import 'package:taskflow_ai/shared/models/project_model.dart';
import 'package:taskflow_ai/shared/models/task_model.dart';
import 'package:taskflow_ai/shared/providers/project_provider.dart';
import 'package:taskflow_ai/shared/providers/project_progress_provider.dart';
import 'package:taskflow_ai/shared/providers/project_tasks_provider.dart';
import 'package:taskflow_ai/shared/providers/task_provider.dart';

import '../../../../app/theme/app_theme.dart';
import 'edit_project_screen.dart';
import 'project_tasks_screen.dart';

class ProjectDetailsScreen extends ConsumerWidget {
  final Map<String, dynamic> project;

  const ProjectDetailsScreen({super.key, required this.project});

  String _formatDate(dynamic value) {
    if (value == null) return 'Not set';

    if (value is String) {
      return value.trim().isEmpty ? 'Not set' : value;
    }

    if (value is DateTime) {
      final day = value.day.toString().padLeft(2, '0');
      final month = value.month.toString().padLeft(2, '0');

      return '$day/$month/${value.year}';
    }

    return 'Not set';
  }

  Widget _buildDateCard({
    required String title,
    required String date,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 26),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // EDIT PROJECT
  Future<void> _editProject(
    BuildContext context,
    ProjectModel currentProject,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProjectScreen(project: currentProject),
      ),
    );
  }

  // OPEN ALL TASKS FOR THIS PROJECT
  void _viewAllTasks(BuildContext context, ProjectModel currentProject) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectTasksScreen(
          projectId: currentProject.id,
          projectName: currentProject.title,
        ),
      ),
    );
  }

  // CREATE AND SAVE A NEW TASK
  Future<void> _addTask(
    BuildContext context,
    WidgetRef ref,
    ProjectModel currentProject,
  ) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => CreateTaskScreen(initialProjectId: currentProject.id),
      ),
    );

    if (!context.mounted || result == null) return;

    final projectIdValue = result['projectId'];

    final selectedProjectId = projectIdValue is num
        ? projectIdValue.toInt()
        : currentProject.id;

    final projects = ref.read(projectProvider);

    final matchingProjects = projects.where(
      (item) => item.id == selectedProjectId,
    );

    if (matchingProjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected project no longer exists.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedProject = matchingProjects.first;

    final newTask = TaskModel(
      // TaskNotifier.addTask assigns the next unique ID.
      id: 0,
      title: result['title'] as String? ?? '',
      description: result['description'] as String? ?? '',
      projectId: selectedProject.id,
      projectName: selectedProject.title,
      dueDate: result['dueDate'] as String? ?? '',
      priority: result['priority'] as String? ?? 'Medium',
      isCompleted: result['isCompleted'] as bool? ?? false,
    );

    try {
      await ref.read(taskProvider.notifier).addTask(newTask);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to create task: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // DELETE PROJECT
  Future<void> _deleteProject(
    BuildContext context,
    WidgetRef ref,
    ProjectModel currentProject,
  ) async {
    final tasks = ref.read(taskProvider);

    final linkedTasks = tasks.where(
      (task) =>
          task.projectId == currentProject.id ||
          (task.projectId == null && task.projectName == currentProject.title),
    );

    if (linkedTasks.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This project has ${linkedTasks.length} linked '
            'task(s). Move or delete them first.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Project?'),
          content: Text(
            'Are you sure you want to delete '
            '"${currentProject.title}"? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (!context.mounted || confirmed != true) return;

    final stillHasTasks = ref
        .read(taskProvider)
        .any(
          (task) =>
              task.projectId == currentProject.id ||
              (task.projectId == null &&
                  task.projectName == currentProject.title),
        );

    if (stillHasTasks) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project still contains linked tasks.')),
      );
      return;
    }

    try {
      await ref.read(projectProvider.notifier).deleteProject(currentProject.id);

      if (!context.mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete project: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = (project['id'] as num?)?.toInt();

    final projects = ref.watch(projectProvider);

    final matchingProjects = projects.where((item) => item.id == projectId);

    if (matchingProjects.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Details')),
        body: const Center(child: Text('Project not found')),
      );
    }

    // Always display the latest saved project.
    final currentProject = matchingProjects.first;

    final title = currentProject.title;
    final description = currentProject.description;
    final status = currentProject.status;

    final isCompleted = status.toLowerCase() == 'completed';

    // Progress is calculated using the project ID.
    final projectProgress = ref.watch(
      projectProgressByIdProvider(currentProject.id),
    );

    // Live tasks for this project.
    final projectTasks = ref.watch(projectTasksProvider(currentProject.id));

    final completedTasks = projectProgress.completedTasks;

    final totalTasks = projectProgress.totalTasks;

    final progress = projectProgress.progress.clamp(0.0, 1.0);

    final progressPercentage = (progress * 100).round();

    final startDate = _formatDate(currentProject.startDate);

    final deadline = _formatDate(currentProject.deadline);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Project Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Project',
            onPressed: () {
              _editProject(context, currentProject);
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // PROJECT INFORMATION CARD
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.folder_copy_outlined,
                            color: AppTheme.primary,
                            size: 28,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isCompleted
                                  ? const Color(0xFF15803D)
                                  : AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      description.isEmpty
                          ? 'No description provided.'
                          : description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 22),
                    const Divider(),
                    const SizedBox(height: 16),

                    // PROJECT PROGRESS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Project Progress',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$progressPercentage%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '$completedTasks of $totalTasks tasks completed',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // PROJECT DATES
              Row(
                children: [
                  Expanded(
                    child: _buildDateCard(
                      title: 'Start Date',
                      date: startDate,
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateCard(
                      title: 'Deadline',
                      date: deadline,
                      icon: Icons.event_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // PROJECT TASKS HEADING
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Project Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _viewAllTasks(context, currentProject);
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // LIVE PROJECT TASK SUMMARY
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: projectTasks.isEmpty
                    ? const Column(
                        children: [
                          SizedBox(height: 16),
                          Icon(
                            Icons.task_alt_outlined,
                            color: AppTheme.primary,
                            size: 46,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'No tasks in this project',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create a task and assign it '
                            'to this project.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          SizedBox(height: 16),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalTasks Project Tasks',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$completedTasks completed • '
                            '${totalTasks - completedTasks} pending',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),

                          // Preview up to three tasks.
                          for (final task in projectTasks.take(3))
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                task.isCompleted
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: task.isCompleted
                                    ? Colors.green
                                    : AppTheme.primary,
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                '${task.priority} Priority • '
                                '${task.dueDate}',
                              ),
                              onTap: () {
                                _viewAllTasks(context, currentProject);
                              },
                            ),

                          if (projectTasks.length > 3)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _viewAllTasks(context, currentProject);
                                },
                                child: Text(
                                  'View all ${projectTasks.length} tasks',
                                ),
                              ),
                            ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // ADD TASK BUTTON
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _addTask(context, ref, currentProject);
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Add Task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // EDIT AND DELETE PROJECT BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _editProject(context, currentProject);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Project'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _deleteProject(context, ref, currentProject);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Project'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
