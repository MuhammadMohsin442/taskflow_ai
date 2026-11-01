import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taskflow_ai/shared/models/task_model.dart';
import 'package:taskflow_ai/shared/providers/task_provider.dart';
import 'package:taskflow_ai/shared/providers/task_filter_provider.dart';

import '../../../../app/theme/app_theme.dart';

import '../widgets/task_card.dart';
import '../widgets/task_filter_bar.dart';

import 'create_task_screen.dart';
import 'task_details_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool _isCreatingTask = false;

  Future<void> _openCreateTask() async {
    if (_isCreatingTask) return;

    final newTask = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
    );

    if (!mounted || newTask == null) return;

    setState(() {
      _isCreatingTask = true;
    });

    try {
      final task = TaskModel.fromMap(newTask);

      await ref.read(taskProvider.notifier).addTask(task);

      // Show the newly created task by clearing filters.
      ref.read(taskFilterProvider.notifier).resetFilters();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to create task: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingTask = false;
        });
      }
    }
  }

  Future<void> _openTaskDetails(TaskModel task) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task.toMap())),
    );

    if (!mounted || result == null) return;

    // TaskDetailsScreen now saves edits and deletions itself.
    // Do not call updateTask or deleteTask again here.
    if (result['deleted'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleTask(TaskModel task, bool completed) async {
    try {
      await ref.read(taskProvider.notifier).toggleTask(task.id, completed);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update task: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(taskProvider);

    final completedCount = ref.watch(completedTaskCountProvider);

    final progress = ref.watch(taskProgressProvider);

    // LESSON 24:
    // Tasks are now searched, filtered and sorted
    // through the shared Riverpod provider.
    final tasks = ref.watch(filteredTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Tasks',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Stay focused and get things done',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // OVERALL TASK PROGRESS
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Task Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '$completedCount of ${allTasks.length}',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 9,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ADVANCED SEARCH AND FILTERS
                    const TaskFilterBar(),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${tasks.length} of ${allTasks.length}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                  ]),
                ),
              ),

              // FILTERED TASK LIST
              if (tasks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No tasks found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Try another search or reset your filters.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = tasks[index];

                      return TaskCard(
                        key: ValueKey(task.id),
                        title: task.title,
                        projectName: task.projectName,
                        dueDate: task.dueDate,
                        priority: task.priority,
                        isCompleted: task.isCompleted,
                        onChanged: (value) {
                          _toggleTask(task, value ?? false);
                        },
                        onTap: () {
                          _openTaskDetails(task);
                        },
                      );
                    }, childCount: tasks.length),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreatingTask ? null : _openCreateTask,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      ),
    );
  }
}
