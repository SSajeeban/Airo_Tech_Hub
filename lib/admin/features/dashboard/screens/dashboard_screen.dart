import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final groups = ref.watch(groupsProvider);
    final meetings = ref.watch(meetingsProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalMembers = groups.fold<int>(0, (sum, g) => sum + g.memberCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.headingLight, AppColors.brandBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTamil ? 'வணக்கம்!' : 'Welcome Back,',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        session?.user.role.toDisplayString() ?? 'Subscriber Plan',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  session?.user.displayName ?? 'Educator Admin',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Text(
                  isTamil
                      ? 'உங்கள் அனைத்து குழுக்கள், மாணவர்கள் மற்றும் வகுப்புகளை ஒரு பார்வையில் நிர்வகியுங்கள்.'
                      : 'Manage your classes, live sessions, and payments from your mobile dashboard.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Plan Usage Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: isTamil ? 'குழுக்கள்' : 'Active Groups',
                  value: '${groups.length}',
                  icon: Icons.groups,
                  color: AppColors.brandBlue,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: isTamil ? 'மாணவர்கள்' : 'Total Students',
                  value: '$totalMembers',
                  icon: Icons.people_alt,
                  color: AppColors.brandGreen,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: isTamil ? 'கூட்டங்கள்' : 'Live Classes',
                  value: '${meetings.length}',
                  icon: Icons.video_call,
                  color: AppColors.accent,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Action Buttons
          Text(
            isTamil ? 'விரைவு நடவடிக்கைகள்' : 'Quick Actions',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/app/meetings'),
                  icon: const Icon(Icons.videocam, size: 18),
                  label: Text(isTamil ? 'நேரலை கூட்டம்' : 'Instant Meet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/app/ai-teacher'),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(isTamil ? 'AI ஆசிரியர்' : 'AI Teacher'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Upcoming Class / Live Meeting Alert
          if (meetings.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isTamil ? 'அடுத்த நேரலை வகுப்பு' : 'Upcoming Live Class',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => context.push('/app/meetings'),
                  child: Text(isTamil ? 'அனைத்தும்' : 'View All'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.live_tv, color: AppColors.accent, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meetings.first.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meetings.first.groupName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/app/meetings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: const Size(60, 36),
                      ),
                      child: Text(isTamil ? 'இணை' : 'Join'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Active Groups List Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTamil ? 'செயலில் உள்ள குழுக்கள்' : 'Your Cohort Groups',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: () => context.go('/app/groups'),
                child: Text(isTamil ? 'அனைத்தும்' : 'View All'),
              ),
            ],
          ),
          ...groups.take(2).map((grp) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.brandBlue.withValues(alpha: 0.15),
                  child: Text(grp.code.substring(0, 2), style: const TextStyle(color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
                ),
                title: Text(grp.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('${grp.memberCount} students • ${grp.schedule}', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => context.go('/app/groups'),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
