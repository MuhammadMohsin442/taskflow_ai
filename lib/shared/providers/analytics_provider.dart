import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow_ai/shared/models/task_model.dart';
import 'package:taskflow_ai/shared/providers/project_provider.dart';
import 'package:taskflow_ai/shared/providers/task_provider.dart';

class ProjectAnalytics {
  final String projectName;
  final int totalTasks;
  final int completedTasks;

  const ProjectAnalytics({
    required this.projectName,
    required this.totalTasks,
    required this.completedTasks,
  });

  double get progress {
    if (totalTasks == 0) return 0.0;
    return completedTasks / totalTasks;
  }
}

class AnalyticsStats {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int activeProjects;

  final int highPriority;
  final int mediumPriority;
  final int lowPriority;

  final List<ProjectAnalytics> projects;

  const AnalyticsStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.activeProjects,
    required this.highPriority,
    required this.mediumPriority,
    required this.lowPriority,
    required this.projects,
  });

  double get completionRate {
    if (totalTasks == 0) return 0.0;
    return completedTasks / totalTasks;
  }
}

final analyticsProvider = Provider<AnalyticsStats>((ref) {
  final tasks = ref.watch(taskProvider);
  final projects = ref.watch(projectProvider);

  final totalTasks = tasks.length;

  final completedTasks = tasks.where((task) => task.isCompleted).length;

  final highPriority = tasks.where((task) => task.priority == 'High').length;

  final mediumPriority = tasks
      .where((task) => task.priority == 'Medium')
      .length;

  final lowPriority = tasks.where((task) => task.priority == 'Low').length;

  final activeProjects = projects
      .where((project) => project.status == 'Active')
      .length;

  final projectAnalytics = projects.map((project) {
    final projectTasks = tasks
        .where((TaskModel task) => task.projectName == project.title)
        .toList();

    return ProjectAnalytics(
      projectName: project.title,
      totalTasks: projectTasks.length,
      completedTasks: projectTasks.where((task) => task.isCompleted).length,
    );
  }).toList();

  return AnalyticsStats(
    totalTasks: totalTasks,
    completedTasks: completedTasks,
    pendingTasks: totalTasks - completedTasks,
    activeProjects: activeProjects,
    highPriority: highPriority,
    mediumPriority: mediumPriority,
    lowPriority: lowPriority,
    projects: projectAnalytics,
  );
});
