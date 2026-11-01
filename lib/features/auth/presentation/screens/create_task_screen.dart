import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taskflow_ai/shared/providers/project_provider.dart';

import '../../../../app/theme/app_theme.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  // Optional project ID for tasks created from Project Details.
  final int? initialProjectId;

  const CreateTaskScreen({super.key, this.initialProjectId});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _selectedProjectId;
  String _selectedPriority = 'Medium';
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();

    // Automatically select the project when opened
    // from Project Details.
    _selectedProjectId = widget.initialProjectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _selectDueDate() async {
    final today = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: today,
      lastDate: DateTime(2100),
    );

    if (!mounted || selectedDate == null) return;

    setState(() {
      _dueDate = selectedDate;
    });
  }

  void _createTask() {
    if (!_formKey.currentState!.validate()) return;

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a due date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final projects = ref.read(projectProvider);

    final selectedProjects = projects.where(
      (project) => project.id == _selectedProjectId,
    );

    if (selectedProjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid project'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedProject = selectedProjects.first;

    final newTask = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'projectId': selectedProject.id,
      'projectName': selectedProject.title,
      'dueDate': _formatDate(_dueDate!),
      'priority': _selectedPriority,
      'isCompleted': false,
    };

    // The calling screen saves the returned task.
    Navigator.of(context).pop(newTask);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectProvider);

    final validSelectedProjectId =
        projects.any((project) => project.id == _selectedProjectId)
        ? _selectedProjectId
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Task',
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
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create a new task',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Organise your work by assigning '
                          'tasks to your projects.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // TASK TITLE
                  const Text(
                    'Task Title *',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('Enter task title'),
                    validator: (value) {
                      final title = value?.trim() ?? '';

                      if (title.isEmpty) {
                        return 'Please enter a task title';
                      }

                      if (title.length < 3) {
                        return 'Title must be at least 3 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // DESCRIPTION
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: _inputDecoration('Enter task description'),
                  ),

                  const SizedBox(height: 24),

                  // PROJECT
                  const Text(
                    'Project *',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    key: ValueKey(validSelectedProjectId),
                    initialValue: validSelectedProjectId,
                    isExpanded: true,
                    decoration: _inputDecoration('Select project'),
                    items: projects.map((project) {
                      return DropdownMenuItem<int>(
                        value: project.id,
                        child: Text(
                          project.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: projects.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              _selectedProjectId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null ||
                          !projects.any((project) => project.id == value)) {
                        return 'Please select a project';
                      }

                      return null;
                    },
                  ),

                  if (projects.isEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'No projects available. '
                      'Create a project first.',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // DUE DATE
                  const Text(
                    'Due Date *',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _selectDueDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _dueDate == null
                          ? 'Select due date'
                          : _formatDate(_dueDate!),
                    ),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(18),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PRIORITY
                  const Text(
                    'Priority',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Low', label: Text('Low')),
                      ButtonSegment(value: 'Medium', label: Text('Medium')),
                      ButtonSegment(value: 'High', label: Text('High')),
                    ],
                    selected: {_selectedPriority},
                    onSelectionChanged: (values) {
                      setState(() {
                        _selectedPriority = values.first;
                      });
                    },
                  ),

                  const SizedBox(height: 36),

                  // CREATE TASK BUTTON
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: projects.isEmpty ? null : _createTask,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Create Task',
                        style: TextStyle(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
