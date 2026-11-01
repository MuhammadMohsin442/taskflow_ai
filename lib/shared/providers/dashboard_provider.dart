import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow_ai/shared/models/task_model.dart';
import 'package:taskflow_ai/shared/providers/project_provider.dart';
import 'package:taskflow_ai/shared/providers/task_provider.dart';

class DashboardStats {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int totalProjects;
  final double progress;
  final List<TaskModel> recentTasks;

  const DashboardStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.totalProjects,
    required this.progress,
    required this.recentTasks,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final tasks = ref.watch(taskProvider);
  final projects = ref.watch(projectProvider);

  final totalTasks = tasks.length;

  final completedTasks = tasks.where((task) => task.isCompleted).length;

  final pendingTasks = totalTasks - completedTasks;

  final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  return DashboardStats(
    totalTasks: totalTasks,
    completedTasks: completedTasks,
    pendingTasks: pendingTasks,
    totalProjects: projects.length,
    progress: progress,
    recentTasks: tasks.take(5).toList(),
  );
});
