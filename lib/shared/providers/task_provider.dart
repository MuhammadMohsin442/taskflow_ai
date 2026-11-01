import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow_ai/shared/models/task_model.dart';

import '../../../../core/services/local_storage_service.dart';

class TaskNotifier extends Notifier<List<TaskModel>> {
  @override
  List<TaskModel> build() {
    return const [
      TaskModel(
        id: 1,
        title: 'Finish Flutter dashboard',
        description: 'Complete dashboard UI and navigation.',
        projectId: 1,
        projectName: 'TaskFlow AI App',
        dueDate: 'Today',
        priority: 'High',
        isCompleted: false,
      ),
      TaskModel(
        id: 2,
        title: 'Review project design',
        description: 'Review colours and application layout.',
        projectId: 1,
        projectName: 'TaskFlow AI App',
        dueDate: 'Tomorrow',
        priority: 'Medium',
        isCompleted: false,
      ),
      TaskModel(
        id: 3,
        title: 'Prepare project structure',
        description: 'Organise the Flutter project.',
        projectId: 1,
        projectName: 'TaskFlow AI App',
        dueDate: 'Completed',
        priority: 'Low',
        isCompleted: true,
      ),
      TaskModel(
        id: 4,
        title: 'Design portfolio homepage',
        description: 'Build a responsive portfolio homepage.',
        projectId: 2,
        projectName: 'Portfolio Website',
        dueDate: 'Completed',
        priority: 'Medium',
        isCompleted: true,
      ),
    ];
  }

  // Replace all tasks when loading saved data.
  void replaceAll(List<TaskModel> tasks) {
    state = List<TaskModel>.from(tasks);
  }

  // Save tasks to local storage.
  Future<void> _saveTasks() async {
    final data = state.map((task) => task.toMap()).toList();

    await LocalStorageService.saveList(LocalStorageService.tasksKey, data);
  }

  // Add a new task.
  Future<void> addTask(TaskModel task) async {
    final nextId =
        state.fold<int>(0, (maxId, item) => item.id > maxId ? item.id : maxId) +
        1;

    state = [task.copyWith(id: nextId), ...state];

    await _saveTasks();
  }

  // Update an existing task.
  Future<void> updateTask(TaskModel updatedTask) async {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task,
    ];

    await _saveTasks();
  }

  // Delete a task.
  Future<void> deleteTask(int id) async {
    state = state.where((task) => task.id != id).toList();

    await _saveTasks();
  }

  // Mark a task completed or pending.
  Future<void> toggleTask(int id, bool completed) async {
    state = [
      for (final task in state)
        if (task.id == id) task.copyWith(isCompleted: completed) else task,
    ];

    await _saveTasks();
  }

  // NEW: Migrate older tasks from project names
  // to stable project IDs.
  Future<void> migrateProjectIds(Map<String, int> projectIdsByName) async {
    var changed = false;

    final updatedTasks = state.map((task) {
      // Already migrated.
      if (task.projectId != null) {
        return task;
      }

      final projectId = projectIdsByName[task.projectName];

      // Preserve unmatched tasks.
      if (projectId == null) {
        return task;
      }

      changed = true;

      return task.copyWith(projectId: projectId);
    }).toList();

    if (!changed) return;

    state = updatedTasks;

    await _saveTasks();
  }

  // NEW: Update task project names when a
  // project is renamed.
  Future<void> renameProjectTasks({
    required int projectId,
    required String newName,
  }) async {
    var changed = false;

    final updatedTasks = state.map((task) {
      if (task.projectId != projectId) {
        return task;
      }

      if (task.projectName == newName) {
        return task;
      }

      changed = true;

      return task.copyWith(projectName: newName);
    }).toList();

    if (!changed) return;

    state = updatedTasks;

    await _saveTasks();
  }
}

// Main task provider.
final taskProvider = NotifierProvider<TaskNotifier, List<TaskModel>>(
  TaskNotifier.new,
);

// Completed task count.
final completedTaskCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(taskProvider);

  return tasks.where((task) => task.isCompleted).length;
});

// Overall task completion progress.
final taskProgressProvider = Provider<double>((ref) {
  final tasks = ref.watch(taskProvider);

  if (tasks.isEmpty) {
    return 0.0;
  }

  final completed = tasks.where((task) => task.isCompleted).length;

  return completed / tasks.length;
});
