import 'package:material_ui/material_ui.dart';

import 'mock_data.dart';
import 'timetable_board.dart';

class NoticesTab extends StatelessWidget {
  final List<Notice> notices;
  final Group? group;
  final Member? member;

  const NoticesTab({super.key, required this.notices, this.group, this.member});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Notice board',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ).copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: 12),
        if (notices.isEmpty)
          Text(
            'No notices for you yet.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
          )
        else
          for (final n in notices)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                title: Text(
                  n.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(n.body),
              ),
            ),

        const SizedBox(height: 24),

        // Timetable board attached to the notice board
        if (group != null && member != null)
          TimetableBoard(group: group!, member: member!),
      ],
    );
  }
}
