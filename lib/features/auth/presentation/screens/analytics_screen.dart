import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow_ai/shared/providers/analytics_provider.dart';

import '../../../../app/theme/app_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }

  Widget _priorityRow({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final progress = total == 0 ? 0.0 : count / total;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '$count',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);

    final percentage = (analytics.completionRate * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Productivity Insights',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your tasks and project performance.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 26),

              // Statistics cards.
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 700 ? 4 : 2;

                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 4 ? 1.2 : 1.1,
                    children: [
                      _statCard(
                        label: 'Completion Rate',
                        value: '$percentage%',
                        icon: Icons.track_changes_rounded,
                        color: AppTheme.primary,
                      ),
                      _statCard(
                        label: 'Completed Tasks',
                        value: '${analytics.completedTasks}',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF16A34A),
                      ),
                      _statCard(
                        label: 'Pending Tasks',
                        value: '${analytics.pendingTasks}',
                        icon: Icons.access_time_rounded,
                        color: const Color(0xFFD97706),
                      ),
                      _statCard(
                        label: 'Active Projects',
                        value: '${analytics.activeProjects}',
                        icon: Icons.folder_outlined,
                        color: const Color(0xFF0284C7),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Completion donut chart.
              _sectionCard(
                title: 'Task Completion',
                child: Column(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 170,
                              height: 170,
                              child: CircularProgressIndicator(
                                value: analytics.completionRate,
                                strokeWidth: 16,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary,
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$percentage%',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const Text(
                                  'Completed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      '${analytics.completedTasks} of '
                      '${analytics.totalTasks} tasks completed',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Priority breakdown.
              _sectionCard(
                title: 'Tasks by Priority',
                child: Column(
                  children: [
                    _priorityRow(
                      label: 'High Priority',
                      count: analytics.highPriority,
                      total: analytics.totalTasks,
                      color: const Color(0xFFEF4444),
                    ),
                    _priorityRow(
                      label: 'Medium Priority',
                      count: analytics.mediumPriority,
                      total: analytics.totalTasks,
                      color: const Color(0xFFF59E0B),
                    ),
                    _priorityRow(
                      label: 'Low Priority',
                      count: analytics.lowPriority,
                      total: analytics.totalTasks,
                      color: const Color(0xFF22C55E),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Project performance.
              _sectionCard(
                title: 'Project Performance',
                child: analytics.projects.isEmpty
                    ? const Center(
                        child: Text(
                          'No projects available',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : Column(
                        children: [
                          for (final project in analytics.projects) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    project.projectName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(project.progress * 100).round()}%',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: project.progress,
                                minHeight: 9,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${project.completedTasks} of '
                                '${project.totalTasks} tasks completed',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),
                          ],
                        ],
                      ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
