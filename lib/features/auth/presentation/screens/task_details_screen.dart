import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taskflow_ai/shared/models/task_model.dart';
import 'package:taskflow_ai/shared/providers/task_provider.dart';

import '../../../../app/theme/app_theme.dart';
import 'edit_task_screen.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  late Map<String, dynamic> _task;

  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    _task = Map<String, dynamic>.from(widget.task);
  }

  int? get _taskId {
    final value = _task['id'];

    if (value is int) return value;
    if (value is num) return value.toInt();

    return null;
  }

  bool get _isCompleted => _task['isCompleted'] as bool? ?? false;

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);

      case 'medium':
        return const Color(0xFFD97706);

      default:
        return const Color(0xFF16A34A);
    }
  }

  TaskModel? _findSavedTask() {
    final id = _taskId;

    if (id == null) return null;

    final tasks = ref.read(taskProvider);

    for (final task in tasks) {
      if (task.id == id) {
        return task;
      }
    }

    return null;
  }

  Map<String, dynamic> _taskToMap(TaskModel task) {
    return task.toMap();
  }

  // SAVE COMPLETION STATUS THROUGH RIVERPOD
  Future<void> _toggleCompletion() async {
    if (_isSaving) return;

    final savedTask = _findSavedTask();

    if (savedTask == null) {
      _showMessage('Task not found in saved tasks.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final newStatus = !savedTask.isCompleted;

      await ref.read(taskProvider.notifier).toggleTask(savedTask.id, newStatus);

      if (!mounted) return;

      setState(() {
        _task['isCompleted'] = newStatus;
        _hasChanges = true;
      });

      _showMessage(
        newStatus ? 'Task marked as completed!' : 'Task marked as pending!',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage('Unable to update task: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // OPEN EDIT TASK SCREEN AND SAVE CHANGES
  Future<void> _openEditTask() async {
    if (_isSaving) return;

    final updatedTask = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => EditTaskScreen(task: Map<String, dynamic>.from(_task)),
      ),
    );

    if (!mounted || updatedTask == null) return;

    final savedTask = _findSavedTask();

    if (savedTask == null) {
      _showMessage('Task not found in saved tasks.', isError: true);
      return;
    }

    final updatedProjectId = updatedTask['projectId'];

    final projectId = updatedProjectId is num
        ? updatedProjectId.toInt()
        : savedTask.projectId;

    final model = savedTask.copyWith(
      title: updatedTask['title'] as String? ?? savedTask.title,
      description:
          updatedTask['description'] as String? ?? savedTask.description,
      projectId: projectId,
      projectName:
          updatedTask['projectName'] as String? ?? savedTask.projectName,
      dueDate: updatedTask['dueDate'] as String? ?? savedTask.dueDate,
      priority: updatedTask['priority'] as String? ?? savedTask.priority,
      isCompleted: updatedTask['isCompleted'] as bool? ?? savedTask.isCompleted,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(taskProvider.notifier).updateTask(model);

      if (!mounted) return;

      setState(() {
        _task = _taskToMap(model);
        _hasChanges = true;
      });

      _showMessage('Task updated successfully!');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Unable to save task: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // DELETE TASK FROM RIVERPOD
  Future<void> _confirmDelete() async {
    if (_isSaving) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Expanded(child: Text('Delete Task?')),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this task? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) return;

    final id = _taskId;

    if (id == null) {
      _showMessage('Invalid task ID.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(taskProvider.notifier).deleteTask(id);

      if (!mounted) return;

      Navigator.of(context).pop(<String, dynamic>{'deleted': true, 'id': id});
    } catch (error) {
      if (!mounted) return;

      _showMessage('Unable to delete task: $error', isError: true);

      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // KEEP EXISTING NAVIGATION RESULT FORMAT
  void _goBack() {
    if (_isSaving) return;

    Navigator.of(context).pop(<String, dynamic>{
      'deleted': false,
      'task': Map<String, dynamic>.from(_task),
      'updated': _hasChanges,
    });
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? AppTheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color ?? AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when tasks change elsewhere.
    final tasks = ref.watch(taskProvider);

    TaskModel? currentTask;

    for (final task in tasks) {
      if (task.id == _taskId) {
        currentTask = task;
        break;
      }
    }

    final displayTask = currentTask == null ? _task : _taskToMap(currentTask);

    final title = displayTask['title'] as String? ?? 'Untitled Task';

    final description = displayTask['description'] as String? ?? '';

    final projectName = displayTask['projectName'] as String? ?? 'No Project';

    final dueDate = displayTask['dueDate'] as String? ?? 'Not set';

    final priority = displayTask['priority'] as String? ?? 'Medium';

    final isCompleted = displayTask['isCompleted'] as bool? ?? false;

    return PopScope<Map<String, dynamic>>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isSaving) {
          _goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _isSaving ? null : _goBack,
          ),
          title: const Text(
            'Task Details',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Edit Task',
              onPressed: _isSaving ? null : _openEditTask,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete Task',
              onPressed: _isSaving ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.task_alt_outlined,
                              color: AppTheme.primary,
                              size: 28,
                            ),
                          ),
                          Chip(
                            label: Text(isCompleted ? 'Completed' : 'Pending'),
                            backgroundColor: isCompleted
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                            side: BorderSide.none,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        description.isEmpty
                            ? 'No description provided.'
                            : description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),

                      _detailRow(
                        icon: Icons.folder_outlined,
                        label: 'Project',
                        value: projectName,
                      ),

                      const Divider(),

                      _detailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Due Date',
                        value: dueDate,
                      ),

                      const Divider(),

                      _detailRow(
                        icon: Icons.flag_outlined,
                        label: 'Priority',
                        value: '$priority Priority',
                        color: _priorityColor(priority),
                      ),

                      const Divider(),

                      _detailRow(
                        icon: Icons.info_outline_rounded,
                        label: 'Status',
                        value: isCompleted ? 'Completed' : 'Pending',
                        color: isCompleted
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // EDIT TASK
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _openEditTask,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Task'),
                  ),
                ),

                const SizedBox(height: 12),

                // COMPLETE / REOPEN TASK
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _toggleCompletion,
                    icon: Icon(
                      isCompleted
                          ? Icons.undo_rounded
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      isCompleted ? 'Mark as Pending' : 'Mark as Completed',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // DELETE TASK
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Delete Task',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECACA)),
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
    );
  }
}
