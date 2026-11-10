import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticesProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTamil ? 'அறிவிப்புகள்' : 'Notices & Announcements'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final titleCtrl = TextEditingController();
          final contentCtrl = TextEditingController();
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Publish New Notice'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Headline')),
                  const SizedBox(height: 12),
                  TextField(controller: contentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Notice Details')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final newNotice = NoticeModel(
                      id: 'not_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      titleTa: titleCtrl.text.trim(),
                      content: contentCtrl.text.trim(),
                      contentTa: contentCtrl.text.trim(),
                      isPinned: true,
                      publishedAt: DateTime.now(),
                      author: 'Administrator',
                    );
                    ref.read(noticesProvider.notifier).update((state) => [newNotice, ...state]);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notice posted to all cohorts!')),
                    );
                  },
                  child: const Text('Publish'),
                ),
              ],
            ),
          );
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notices.length,
        itemBuilder: (context, index) {
          final notice = notices[index];
          final title = isTamil ? notice.titleTa : notice.title;
          final content = isTamil ? notice.contentTa : notice.content;

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: notice.isPinned ? AppColors.warning : (isDark ? AppColors.lineDark : AppColors.lineLight),
                width: notice.isPinned ? 1.5 : 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (notice.isPinned) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PINNED',
                            style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          notice.author,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: isDark ? AppColors.inkDark : AppColors.inkLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

