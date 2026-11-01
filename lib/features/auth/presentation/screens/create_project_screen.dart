import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _deadline;

  String _status = 'Active';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? now)
          : (_deadline ?? _startDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (isStartDate) {
        _startDate = selected;

        if (_deadline != null && _deadline!.isBefore(selected)) {
          _deadline = null;
        }
      } else {
        _deadline = selected;
      }
    });
  }

  void _createProject() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date and deadline'),
        ),
      );
      return;
    }

    if (_deadline!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deadline cannot be before start date')),
      );
      return;
    }

    final project = <String, dynamic>{
      'title': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'completedTasks': 0,
      'totalTasks': 0,
      'status': _status,
      'startDate': _startDate!,
      'deadline': _deadline!,
    };

    Navigator.of(context).pop(project);
  }

  InputDecoration _decoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Project',
          style: TextStyle(fontWeight: FontWeight.w700),
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
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.folder_copy_outlined,
                              color: AppTheme.primary,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Start something great',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Organise your goals, deadlines '
                          'and tasks in one place.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Project Name *',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: _decoration(
                      hint: 'e.g. TaskFlow AI Development',
                      icon: Icons.folder_outlined,
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';

                      if (name.isEmpty) {
                        return 'Please enter a project name';
                      }

                      if (name.length < 3) {
                        return 'Name must be at least 3 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Description *',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _decoration(hint: 'Describe your project...'),
                    validator: (value) {
                      final description = value?.trim() ?? '';

                      if (description.isEmpty) {
                        return 'Please enter a description';
                      }

                      if (description.length < 10) {
                        return 'Description must be at least 10 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Start Date',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: () => _pickDate(isStartDate: true),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_formatDate(_startDate)),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(18),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Deadline',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: () => _pickDate(isStartDate: false),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_formatDate(_deadline)),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(18),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Project Status',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: _decoration(
                      hint: 'Select status',
                      icon: Icons.flag_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _status = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 36),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _createProject,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Create Project',
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
