import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

class MeetingsScreen extends ConsumerWidget {
  const MeetingsScreen({super.key});

  void _launchMeeting(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open meeting: $url')),
        );
      }
    }
  }

  void _createInstantMeeting(BuildContext context, WidgetRef ref) {
    final newId = 'airo_${DateTime.now().millisecondsSinceEpoch % 100000}';
    final meeting = MeetingModel(
      id: newId,
      title: 'Instant Online Classroom',
      groupName: 'General Session',
      scheduledTime: DateTime.now(),
      durationMinutes: 60,
      meetingUrl: 'https://meet.jit.si/$newId',
      isLive: true,
    );

    ref.read(meetingsProvider.notifier).update((state) => [meeting, ...state]);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Instant live meeting created!'),
        action: SnackBarAction(
          label: 'JOIN NOW',
          onPressed: () => _launchMeeting(context, meeting.meetingUrl),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetings = ref.watch(meetingsProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createInstantMeeting(context, ref),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_call, color: Colors.white),
        label: Text(
          isTamil ? 'உடனடி கூட்டம்' : 'Instant Meeting',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Card(
            color: isDark ? AppColors.surfaceDark : AppColors.accentLight.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.accent, width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.video_camera_front, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamil ? 'நேரலை கூட்டங்கள்' : 'Live Classrooms & Meetings',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTamil
                              ? 'மாணவர்கள் எவ்வித ஆப்பும் இன்றி உலாவி வழியாக நேரடியாக இணைகிறார்கள்.'
                              : 'Students join directly with meeting links or classroom code.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            isTamil ? 'திட்டமிடப்பட்ட கூட்டங்கள்' : 'Scheduled & Live Sessions',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          ...meetings.map((meeting) {
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: meeting.isLive ? AppColors.accent : (isDark ? AppColors.lineDark : AppColors.lineLight),
                  width: meeting.isLive ? 1.5 : 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (meeting.isLive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '● LIVE NOW',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            meeting.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 14, color: AppColors.mutedLight),
                        const SizedBox(width: 6),
                        Text(meeting.groupName, style: const TextStyle(fontSize: 12, color: AppColors.brandBlue, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.mutedLight),
                        const SizedBox(width: 4),
                        Text('${meeting.durationMinutes} mins', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchMeeting(context, meeting.meetingUrl),
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: Text(meeting.isLive ? 'Join Meeting' : 'Start Session'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: meeting.isLive ? AppColors.accent : AppColors.brandBlue,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          tooltip: 'Copy Link',
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: meeting.meetingUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Meeting URL copied to clipboard!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

