import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taskflow_ai/shared/models/task_model.dart';
import 'package:taskflow_ai/shared/providers/project_provider.dart';
import 'package:taskflow_ai/shared/providers/project_tasks_provider.dart';
import 'package:taskflow_ai/shared/providers/task_provider.dart';

import '../../../../app/theme/app_theme.dart';

class ProjectTasksScreen extends ConsumerStatefulWidget {
  final int projectId;
  final String projectName;

  const ProjectTasksScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<ProjectTasksScreen> createState() => _ProjectTasksScreenState();
}

class _ProjectTasksScreenState extends ConsumerState<ProjectTasksScreen> {
  final _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _selectedPriority = 'All';
  String _selectedSort = 'Newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedFilter = 'All';
      _selectedPriority = 'All';
      _selectedSort = 'Newest';
    });
  }

  int _priorityRank(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  DateTime? _parseDueDate(String value) {
    final text = value.trim().toLowerCase();
    final today = DateTime.now();

    if (text == 'today') {
      return DateTime(today.year, today.month, today.day);
    }

    if (text == 'tomorrow') {
      return DateTime(today.year, today.month, today.day + 1);
    }

    final parts = text.split('/');

    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    final date = DateTime(year, month, day);

    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }

    return date;
  }

  List<TaskModel> _filterAndSortTasks(List<TaskModel> tasks) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = tasks.where((task) {
      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.projectName.toLowerCase().contains(query);

      final matchesStatus =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'Pending' && !task.isCompleted) ||
          (_selectedFilter == 'Completed' && task.isCompleted);

      final matchesPriority =
          _selectedPriority == 'All' ||
          task.priority.toLowerCase() == _selectedPriority.toLowerCase();

      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();

    switch (_selectedSort) {
      case 'Oldest':
        filtered.sort((a, b) => a.id.compareTo(b.id));
        break;

      case 'Priority':
        filtered.sort(
          (a, b) =>
              _priorityRank(b.priority).compareTo(_priorityRank(a.priority)),
        );
        break;

      case 'Due Date':
        filtered.sort((a, b) {
          final aDate = _parseDueDate(a.dueDate);
          final bDate = _parseDueDate(b.dueDate);

          if (aDate == null && bDate == null) {
            return 0;
          }
          if (aDate == null) return 1;
          if (bDate == null) return -1;

          return aDate.compareTo(bDate);
        });
        break;

      case 'Title A-Z':
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;

      case 'Title Z-A':
        filtered.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;

      case 'Newest':
      default:
        filtered.sort((a, b) => b.id.compareTo(a.id));
    }

    return filtered;
  }

  Future<void> _toggleTask(TaskModel task) async {
    try {
      await ref
          .read(taskProvider.notifier)
          .toggleTask(task.id, !task.isCompleted);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update task: $error')));
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task?'),
          content: Text('Delete "${task.title}" permanently?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    try {
      await ref.read(taskProvider.notifier).deleteTask(task.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete task: $error')));
    }
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final priorityColor = switch (task.priority.toLowerCase()) {
      'high' => Colors.red,
      'medium' => Colors.orange,
      _ => Colors.green,
    };

    return Card(
      key: ValueKey(task.id),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.isCompleted,
              activeColor: AppTheme.primary,
              onChanged: (_) => _toggleTask(task),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(
                            Icons.flag_outlined,
                            color: priorityColor,
                            size: 16,
                          ),
                          label: Text(task.priority),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                          ),
                          label: Text(task.dueDate),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Delete task',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteTask(task),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only tasks belonging to this project.
    final allTasks = ref.watch(projectTasksProvider(widget.projectId));

    // Keep the displayed name up to date if renamed.
    final projects = ref.watch(projectProvider);

    final matchingProjects = projects.where(
      (project) => project.id == widget.projectId,
    );

    final currentProjectName = matchingProjects.isNotEmpty
        ? matchingProjects.first.title
        : widget.projectName;

    final completedCount = allTasks.where((task) => task.isCompleted).length;

    final filteredTasks = _filterAndSortTasks(allTasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Project Tasks',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // PROJECT NAME
              Text(
                currentProjectName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '$completedCount of ${allTasks.length} '
                'tasks completed',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),

              const SizedBox(height: 20),

              // PROJECT PROGRESS
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: allTasks.isEmpty
                      ? 0
                      : completedCount / allTasks.length,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // SEARCH TASKS
              TextField(
                controller: _searchController,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search project tasks...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // STATUS FILTER
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final filter in ['All', 'Pending', 'Completed'])
                    ChoiceChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      selectedColor: AppTheme.primary,
                      backgroundColor: Colors.white,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: _selectedFilter == filter
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // PRIORITY AND SORTING
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 500;

                  final priorityDropdown = DropdownButtonFormField<String>(
                    key: ValueKey('priority-$_selectedPriority'),
                    initialValue: _selectedPriority,
                    isExpanded: true,
                    decoration: _dropdownDecoration('Priority'),
                    items: const [
                      DropdownMenuItem(
                        value: 'All',
                        child: Text('All Priorities'),
                      ),
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'High', child: Text('High')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedPriority = value;
                      });
                    },
                  );

                  final sortDropdown = DropdownButtonFormField<String>(
                    key: ValueKey('sort-$_selectedSort'),
                    initialValue: _selectedSort,
                    isExpanded: true,
                    decoration: _dropdownDecoration('Sort By'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Newest',
                        child: Text('Newest First'),
                      ),
                      DropdownMenuItem(
                        value: 'Oldest',
                        child: Text('Oldest First'),
                      ),
                      DropdownMenuItem(
                        value: 'Due Date',
                        child: Text('Due Date'),
                      ),
                      DropdownMenuItem(
                        value: 'Priority',
                        child: Text('Priority'),
                      ),
                      DropdownMenuItem(
                        value: 'Title A-Z',
                        child: Text('Title A-Z'),
                      ),
                      DropdownMenuItem(
                        value: 'Title Z-A',
                        child: Text('Title Z-A'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedSort = value;
                      });
                    },
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        priorityDropdown,
                        const SizedBox(height: 12),
                        sortDropdown,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: priorityDropdown),
                      const SizedBox(width: 12),
                      Expanded(child: sortDropdown),
                    ],
                  );
                },
              ),

              const SizedBox(height: 14),

              // RESET FILTERS
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset Filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // FILTERED RESULTS COUNT
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
                    '${filteredTasks.length} of '
                    '${allTasks.length}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // TASK LIST
              if (filteredTasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No tasks found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        allTasks.isEmpty
                            ? 'This project has no tasks yet.'
                            : 'Try changing your search '
                                  'or resetting the filters.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      if (allTasks.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Reset Filters'),
                        ),
                      ],
                    ],
                  ),
                )
              else
                for (final task in filteredTasks) _buildTaskCard(task),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
