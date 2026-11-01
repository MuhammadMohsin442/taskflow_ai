import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taskflow_ai/shared/providers/project_provider.dart';
import 'package:taskflow_ai/shared/providers/task_provider.dart';

class ProjectProgress {
  final int totalTasks;
  final int completedTasks;

  const ProjectProgress({
    required this.totalTasks,
    required this.completedTasks,
  });

  double get progress {
    if (totalTasks == 0) {
      return 0.0;
    }

    return completedTasks / totalTasks;
  }

  int get pendingTasks {
    return totalTasks - completedTasks;
  }

  int get progressPercentage {
    return (progress * 100).round();
  }
}

// Existing name-based interface is preserved
// for compatibility with older screens.
final projectProgressProvider = Provider.family<ProjectProgress, String>((
  ref,
  projectName,
) {
  final projects = ref.watch(projectProvider);
  final tasks = ref.watch(taskProvider);

  final matchingProjects = projects.where(
    (project) => project.title == projectName,
  );

  if (matchingProjects.isEmpty) {
    return const ProjectProgress(totalTasks: 0, completedTasks: 0);
  }

  final projectId = matchingProjects.first.id;

  final projectTasks = tasks.where((task) {
    if (task.projectId != null) {
      return task.projectId == projectId;
    }

    // Support old saved tasks without projectId.
    return task.projectName == projectName;
  }).toList();

  final completedTasks = projectTasks.where((task) => task.isCompleted).length;

  return ProjectProgress(
    totalTasks: projectTasks.length,
    completedTasks: completedTasks,
  );
});

// New ID-based provider for future screens.
final projectProgressByIdProvider = Provider.family<ProjectProgress, int>((
  ref,
  projectId,
) {
  final projects = ref.watch(projectProvider);
  final tasks = ref.watch(taskProvider);

  final matchingProjects = projects.where((project) => project.id == projectId);

  if (matchingProjects.isEmpty) {
    return const ProjectProgress(totalTasks: 0, completedTasks: 0);
  }

  final projectName = matchingProjects.first.title;

  final projectTasks = tasks.where((task) {
    if (task.projectId != null) {
      return task.projectId == projectId;
    }

    return task.projectName == projectName;
  }).toList();

  final completedTasks = projectTasks.where((task) => task.isCompleted).length;

  return ProjectProgress(
    totalTasks: projectTasks.length,
    completedTasks: completedTasks,
  );
});
