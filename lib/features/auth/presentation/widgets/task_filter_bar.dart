import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:taskflow_ai/shared/providers/task_filter_provider.dart';

import '../../../../app/theme/app_theme.dart';

class TaskFilterBar extends ConsumerStatefulWidget {
  const TaskFilterBar({super.key});

  @override
  ConsumerState<TaskFilterBar> createState() => _TaskFilterBarState();
}

class _TaskFilterBarState extends ConsumerState<TaskFilterBar> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Restore the current search query when the widget opens.
    _searchController.text = ref.read(taskFilterProvider).searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();

    ref.read(taskFilterProvider.notifier).setSearchQuery('');
  }

  void _resetFilters() {
    _searchController.clear();

    ref.read(taskFilterProvider.notifier).resetFilters();
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

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(taskFilterProvider);

    // Keep the search field synchronized with Riverpod.
    // This also handles resets made from TasksScreen.
    if (_searchController.text != filters.searchQuery) {
      _searchController.value = TextEditingValue(
        text: filters.searchQuery,
        selection: TextSelection.collapsed(offset: filters.searchQuery.length),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SEARCH FIELD
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            ref.read(taskFilterProvider.notifier).setSearchQuery(value);
          },
          decoration: InputDecoration(
            hintText: 'Search tasks or projects...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: filters.searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _clearSearch,
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

        const SizedBox(height: 18),

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
            for (final status in ['All', 'Pending', 'Completed'])
              ChoiceChip(
                label: Text(status),
                selected: filters.status == status,
                showCheckmark: false,
                selectedColor: AppTheme.primary,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: filters.status == status
                      ? Colors.white
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) {
                  ref.read(taskFilterProvider.notifier).setStatus(status);
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
              key: ValueKey('priority-${filters.priority}'),
              initialValue: filters.priority,
              isExpanded: true,
              decoration: _dropdownDecoration('Priority'),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Priorities')),
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(taskFilterProvider.notifier).setPriority(value);
                }
              },
            );

            final sortDropdown = DropdownButtonFormField<String>(
              key: ValueKey('sort-${filters.sortBy}'),
              initialValue: filters.sortBy,
              isExpanded: true,
              decoration: _dropdownDecoration('Sort By'),
              items: const [
                DropdownMenuItem(value: 'Newest', child: Text('Newest First')),
                DropdownMenuItem(value: 'Oldest', child: Text('Oldest First')),
                DropdownMenuItem(value: 'Due Date', child: Text('Due Date')),
                DropdownMenuItem(value: 'Priority', child: Text('Priority')),
                DropdownMenuItem(value: 'Title A-Z', child: Text('Title A-Z')),
                DropdownMenuItem(value: 'Title Z-A', child: Text('Title Z-A')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(taskFilterProvider.notifier).setSortBy(value);
                }
              },
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
          ),
        ),
      ],
    );
  }
}
