import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taskflow_ai/shared/models/task_model.dart';
import 'package:taskflow_ai/shared/providers/project_provider.dart';
import 'package:taskflow_ai/shared/providers/task_provider.dart';

final projectTasksProvider = Provider.family<List<TaskModel>, int>((
  ref,
  projectId,
) {
  final tasks = ref.watch(taskProvider);
  final projects = ref.watch(projectProvider);

  final matchingProjects = projects.where((project) => project.id == projectId);

  if (matchingProjects.isEmpty) {
    return <TaskModel>[];
  }

  final projectName = matchingProjects.first.title;

  final projectTasks = tasks.where((task) {
    if (task.projectId != null) {
      return task.projectId == projectId;
    }

    // Backward compatibility for older saved tasks.
    return task.projectName == projectName;
  }).toList();

  // Keep task order stable for now.
  return projectTasks;
});

final projectPendingTasksProvider = Provider.family<List<TaskModel>, int>((
  ref,
  projectId,
) {
  final tasks = ref.watch(projectTasksProvider(projectId));

  return tasks.where((task) => !task.isCompleted).toList();
});

final projectCompletedTasksProvider = Provider.family<List<TaskModel>, int>((
  ref,
  projectId,
) {
  final tasks = ref.watch(projectTasksProvider(projectId));

  return tasks.where((task) => task.isCompleted).toList();
});
