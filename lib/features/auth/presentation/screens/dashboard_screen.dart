import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow_ai/features/auth/presentation/screens/projects_screen.dart';
import 'package:taskflow_ai/features/auth/presentation/screens/tasks_screen.dart';
import 'package:taskflow_ai/shared/providers/dashboard_provider.dart';

import '../../../../app/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openTasks(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TasksScreen()));
  }

  void _openProjects(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProjectsScreen()));
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
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
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),

          const SizedBox(height: 18),

          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    final progressPercentage = (stats.progress * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
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
                'Welcome to TaskFlow AI',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Here is your productivity overview.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),

              const SizedBox(height: 28),

              // Responsive statistics grid.
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
                        title: 'Total Tasks',
                        value: '${stats.totalTasks}',
                        icon: Icons.list_alt_rounded,
                        color: AppTheme.primary,
                        backgroundColor: const Color(0xFFEEF2FF),
                      ),
                      _statCard(
                        title: 'Completed',
                        value: '${stats.completedTasks}',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF16A34A),
                        backgroundColor: const Color(0xFFDCFCE7),
                      ),
                      _statCard(
                        title: 'Pending',
                        value: '${stats.pendingTasks}',
                        icon: Icons.access_time_rounded,
                        color: const Color(0xFFD97706),
                        backgroundColor: const Color(0xFFFEF3C7),
                      ),
                      _statCard(
                        title: 'Projects',
                        value: '${stats.totalProjects}',
                        icon: Icons.folder_outlined,
                        color: const Color(0xFF0284C7),
                        backgroundColor: const Color(0xFFE0F2FE),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // Overall progress.
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
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$progressPercentage%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: stats.progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      '${stats.completedTasks} of '
                      '${stats.totalTasks} tasks completed',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Quick actions.
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 14),

              _quickAction(
                title: 'Manage Tasks',
                subtitle: 'Create, edit and complete tasks',
                icon: Icons.task_alt_outlined,
                onTap: () => _openTasks(context),
              ),

              const SizedBox(height: 12),

              _quickAction(
                title: 'Manage Projects',
                subtitle: 'View and organise projects',
                icon: Icons.folder_copy_outlined,
                onTap: () => _openProjects(context),
              ),

              const SizedBox(height: 28),

              // Recent tasks heading.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openTasks(context),
                    child: const Text('View All'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Recent tasks list.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: stats.recentTasks.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No tasks yet. Create your first task!',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (
                            int i = 0;
                            i < stats.recentTasks.length;
                            i++
                          ) ...[
                            if (i > 0) const Divider(),

                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                stats.recentTasks[i].isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked,
                                color: stats.recentTasks[i].isCompleted
                                    ? const Color(0xFF16A34A)
                                    : AppTheme.primary,
                              ),
                              title: Text(
                                stats.recentTasks[i].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: stats.recentTasks[i].isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                stats.recentTasks[i].projectName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppTheme.textSecondary,
                              ),
                              onTap: () => _openTasks(context),
                            ),
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
