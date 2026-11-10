import 'package:flutter/material.dart';

class MeetingItem {
  final String title;
  final String groupName;
  final String startsAt;
  final String status; // Ended, Upcoming, Live

  const MeetingItem({
    required this.title,
    required this.groupName,
    required this.startsAt,
    required this.status,
  });
}

class MeetingsTab extends StatelessWidget {
  final String groupName;

  const MeetingsTab({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1F2A5A);

    final meetings = [
      MeetingItem(
        title: 'Meeting',
        groupName: groupName,
        startsAt: 'Oct 29, 2026, 11:30 AM',
        status: 'Ended',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Meetings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: navy,
          ),
        ),
        const SizedBox(height: 12),
        for (final m in meetings)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  m.title[0],
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(m.title),
              subtitle: Text('${m.groupName}\n${m.startsAt}'),
              isThreeLine: true,
              trailing: _StatusChip(m.status),
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Live' => const Color(0xFF1B9A85),
      'Upcoming' => Colors.orange,
      _ => const Color(0xFF1F2A5A),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
