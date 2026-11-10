
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteContentProvider);
    final currentLang = ref.watch(languageProvider);
    final isTamil = currentLang == 'ta';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Image.asset(
          'assets/images/logo.png',
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('AIRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        actions: [
          // Admin Sign In button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14877C),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 34),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isTamil ? 'நிர்வாக உள்நுழைவு' : 'Admin Sign In',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Language toggle
          TextButton(
            onPressed: () => ref.read(languageProvider.notifier).toggleLanguage(),
            child: Text(
              isTamil ? 'English' : 'தமிழ்',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent),
            ),
          ),
          // Theme toggle
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: siteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (site) {
          final headline = isTamil ? site.headlineTa : site.headline;
          final lead = isTamil ? site.leadTa : site.lead;
          final subCta = isTamil ? site.subscriberCtaLabelTa : site.subscriberCtaLabel;
          final subDetail = isTamil ? site.subscriberCtaDetailTa : site.subscriberCtaDetail;
          final memCta = isTamil ? site.memberCtaLabelTa : site.memberCtaLabel;
          final memDetail = isTamil ? site.memberCtaDetailTa : site.memberCtaDetail;
          final aiTitle = isTamil ? site.aiTitleTa : site.aiTitle;
          final aiBody = isTamil ? site.aiBodyTa : site.aiBody;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Eyebrow Badge
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      site.eyebrow.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accentHover,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main Headline
                Text(
                  headline,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),

                // Lead Paragraph
                Text(
                  lead,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),

                // Primary Actions Card 1: Subscriber Registration
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppColors.lineDark : AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.school, color: AppColors.accent, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isTamil ? 'பயிற்சியாளர்கள் & சந்தாதாரர்கள்' : 'For Teachers & Subscribers',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subDetail,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/register'),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: Text(subCta),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Primary Actions Card 2: Student Join Group
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppColors.lineDark : AppColors.lineLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.brandBlue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.groups, color: AppColors.brandBlue, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isTamil ? 'மாணவர்கள் & உறுப்பினர்கள்' : 'For Students & Members',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          memDetail,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/group-join'),
                          icon: const Icon(Icons.key, size: 18, color: AppColors.brandBlue),
                          label: Text(memCta),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Already have an account? Sign In
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/login'),
                    child: Text(
                      isTamil ? 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழையவும்' : 'Already have an account? Sign In',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Section Title: Platform Services
                Text(
                  isTamil ? 'சேவைகள் மற்றும் அம்சங்கள்' : 'Services & Core Capabilities',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),

                // 4 Core Services
                ...site.services.map((svc) {
                  final title = isTamil ? svc.titleTa : svc.title;
                  final detail = isTamil ? svc.detailTa : svc.detail;
                  final icon = _getServiceIcon(svc.id);
                  final color = _getServiceColor(svc.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    detail,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // 9 Features Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: site.features.map((feat) {
                    final label = isTamil ? feat.labelTa : feat.label;
                    return Chip(
                      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      avatar: const Icon(Icons.check_circle, size: 16, color: AppColors.accent),
                      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.bgLight,
                      side: BorderSide(color: isDark ? AppColors.lineDark : AppColors.lineLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // AI Teacher Showcase Card
                Card(
                  color: isDark ? const Color(0xFF16233B) : const Color(0xFFF0FDF4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.brandGreen, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.brandGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                site.aiKicker,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              aiTitle,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          aiBody,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: isDark ? AppColors.inkDark : AppColors.inkLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/ai-teacher-demo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: Text(
                            isTamil ? 'AI ஆசிரியரை முயற்சிக்கவும்' : 'Try AI Teacher Assistant',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Footer & Legal Links
                Divider(color: isDark ? AppColors.lineDark : AppColors.lineLight),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    children: [
                      TextButton(
                        onPressed: () => context.push('/privacy'),
                        child: Text(
                          isTamil ? 'தனியுரிமைக் கொள்கை' : 'Privacy Policy',
                          style: const TextStyle(fontSize: 12, color: AppColors.mutedLight),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/cookies'),
                        child: Text(
                          isTamil ? 'குக்கீ கொள்கை' : 'Cookie Policy',
                          style: const TextStyle(fontSize: 12, color: AppColors.mutedLight),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '© ${DateTime.now().year} AIRO TECHHUB. All rights reserved.',
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedLight),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getServiceIcon(String id) {
    switch (id) {
      case 'groups':
        return Icons.people_outline;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'payments':
        return Icons.payments_outlined;
      case 'meetings':
      default:
        return Icons.video_call_outlined;
    }
  }

  Color _getServiceColor(String id) {
    switch (id) {
      case 'groups':
        return AppColors.brandBlue;
      case 'chat':
        return AppColors.accent;
      case 'payments':
        return AppColors.warning;
      case 'meetings':
      default:
        return AppColors.brandGreen;
    }
  }
}

