import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taskflow_ai/shared/models/project_model.dart';
import 'package:taskflow_ai/shared/providers/project_provider.dart';
import 'package:taskflow_ai/shared/providers/task_provider.dart';

import '../../../../app/theme/app_theme.dart';

class EditProjectScreen extends ConsumerStatefulWidget {
  final ProjectModel project;

  const EditProjectScreen({super.key, required this.project});

  @override
  ConsumerState<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends ConsumerState<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _startDateController;
  late final TextEditingController _deadlineController;

  late String _selectedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final project = widget.project;

    _titleController = TextEditingController(text: project.title);

    _descriptionController = TextEditingController(text: project.description);

    _startDateController = TextEditingController(text: project.startDate);

    _deadlineController = TextEditingController(text: project.deadline);

    _selectedStatus =
        ['Planning', 'Active', 'Completed'].contains(project.status)
        ? project.status
        : 'Active';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Future<void> _selectDate({required TextEditingController controller}) async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || selectedDate == null) return;

    final day = selectedDate.day.toString().padLeft(2, '0');
    final month = selectedDate.month.toString().padLeft(2, '0');

    controller.text = '$day/$month/${selectedDate.year}';
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newTitle = _titleController.text.trim();

    final projects = ref.read(projectProvider);

    // Prevent duplicate project names.
    final duplicateExists = projects.any(
      (project) =>
          project.id != widget.project.id &&
          project.title.toLowerCase() == newTitle.toLowerCase(),
    );

    if (duplicateExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A project with this name already exists.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedProject = widget.project.copyWith(
      title: newTitle,
      description: _descriptionController.text.trim(),
      status: _selectedStatus,
      startDate: _startDateController.text.trim(),
      deadline: _deadlineController.text.trim(),
    );

    try {
      // Save project changes.
      await ref.read(projectProvider.notifier).updateProject(updatedProject);

      // Keep task display names synchronized
      // when a project is renamed.
      if (widget.project.title != updatedProject.title) {
        await ref
            .read(taskProvider.notifier)
            .renameProjectTasks(
              projectId: updatedProject.id,
              newName: updatedProject.title,
            );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(updatedProject);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update project: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Project',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          color: AppTheme.primary,
                          size: 32,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Update your project',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Edit project details, status '
                          'and important dates.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // PROJECT NAME
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration(
                      'Project Name *',
                      icon: Icons.folder_outlined,
                    ),
                    validator: (value) {
                      final title = value?.trim() ?? '';

                      if (title.isEmpty) {
                        return 'Please enter a project name';
                      }

                      if (title.length < 3) {
                        return 'Project name must be at least 3 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // DESCRIPTION
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      'Project Description',
                      icon: Icons.description_outlined,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // STATUS
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: _inputDecoration(
                      'Project Status',
                      icon: Icons.flag_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Planning',
                        child: Text('Planning'),
                      ),
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // START DATE
                  TextFormField(
                    controller: _startDateController,
                    readOnly: true,
                    onTap: () => _selectDate(controller: _startDateController),
                    decoration: _inputDecoration(
                      'Start Date',
                      icon: Icons.calendar_today_outlined,
                    ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
                  ),

                  const SizedBox(height: 20),

                  // DEADLINE
                  TextFormField(
                    controller: _deadlineController,
                    readOnly: true,
                    onTap: () => _selectDate(controller: _deadlineController),
                    decoration: _inputDecoration(
                      'Deadline',
                      icon: Icons.event_outlined,
                    ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down)),
                  ),

                  const SizedBox(height: 36),

                  // SAVE BUTTON
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProject,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? 'Saving Changes...' : 'Save Changes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

                  const SizedBox(height: 16),

                  // CANCEL BUTTON
                  OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
