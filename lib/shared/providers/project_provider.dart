import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow_ai/shared/models/project_model.dart';

import '../../../../core/services/local_storage_service.dart';

class ProjectNotifier extends Notifier<List<ProjectModel>> {
  @override
  List<ProjectModel> build() {
    return const [
      ProjectModel(
        id: 1,
        title: 'TaskFlow AI App',
        description: 'A Flutter-based AI-powered task management application.',
        status: 'Active',
        startDate: '01/10/2026',
        deadline: '30/11/2026',
      ),
      ProjectModel(
        id: 2,
        title: 'Portfolio Website',
        description: 'A responsive personal developer portfolio website.',
        status: 'Active',
        startDate: '05/10/2026',
        deadline: '15/11/2026',
      ),
      ProjectModel(
        id: 3,
        title: 'API Integration',
        description: 'Practice REST API integration with Flutter and Dio.',
        status: 'Planning',
        startDate: '10/10/2026',
        deadline: '20/12/2026',
      ),
    ];
  }

  void replaceAll(List<ProjectModel> projects) {
    state = List<ProjectModel>.from(projects);
  }

  Future<void> _saveProjects() async {
    final data = state.map((project) => project.toMap()).toList();

    await LocalStorageService.saveList(LocalStorageService.projectsKey, data);
  }

  Future<void> addProject(ProjectModel project) async {
    final nextId =
        state.fold<int>(0, (maxId, item) => item.id > maxId ? item.id : maxId) +
        1;

    state = [project.copyWith(id: nextId), ...state];

    await _saveProjects();
  }

  Future<void> updateProject(ProjectModel updatedProject) async {
    state = [
      for (final project in state)
        if (project.id == updatedProject.id) updatedProject else project,
    ];

    await _saveProjects();
  }

  Future<void> deleteProject(int id) async {
    state = state.where((project) => project.id != id).toList();

    await _saveProjects();
  }
}

final projectProvider = NotifierProvider<ProjectNotifier, List<ProjectModel>>(
  ProjectNotifier.new,
);
