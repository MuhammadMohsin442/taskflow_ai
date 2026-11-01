import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String projectName;
  final String dueDate;
  final String priority;
  final bool isCompleted;

  final ValueChanged<bool?> onChanged;

  // New: Callback for opening Task Details Screen.
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.projectName,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
    required this.onChanged,
    this.onTap,
  });

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);

      case 'medium':
        return const Color(0xFFD97706);

      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          // New: Open task details when the card is tapped.
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),

          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task completion checkbox.
                Checkbox(
                  value: isCompleted,
                  activeColor: AppTheme.primary,
                  onChanged: onChanged,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task title.
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isCompleted
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Project name.
                      Text(
                        projectName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Due date.
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),

                                const SizedBox(width: 6),

                                Flexible(
                                  child: Text(
                                    dueDate,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Priority badge.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              priority,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
