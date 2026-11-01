import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow_ai/shared/models/project_model.dart';
import 'package:taskflow_ai/shared/models/task_model.dart';
import 'package:taskflow_ai/shared/providers/project_provider.dart';
import 'package:taskflow_ai/shared/providers/task_provider.dart';

import 'local_storage_service.dart';

class AppDataLoader {
  AppDataLoader._();

  static Future<void> load(ProviderContainer container) async {
    final savedTasks = await LocalStorageService.loadList(
      LocalStorageService.tasksKey,
    );

    final savedProjects = await LocalStorageService.loadList(
      LocalStorageService.projectsKey,
    );

    if (savedProjects != null) {
      final projects = savedProjects.map(ProjectModel.fromMap).toList();

      container.read(projectProvider.notifier).replaceAll(projects);
    }

    if (savedTasks != null) {
      final tasks = savedTasks.map(TaskModel.fromMap).toList();

      container.read(taskProvider.notifier).replaceAll(tasks);
    }

    final projects = container.read(projectProvider);

    final projectIdsByName = {
      for (final project in projects) project.title: project.id,
    };

    await container
        .read(taskProvider.notifier)
        .migrateProjectIds(projectIdsByName);
  }
}
