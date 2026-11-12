import 'package:flutter/material.dart';

import 'mock_data.dart';

class NoticesTab extends StatelessWidget {
  final List<Notice> notices;

  const NoticesTab({super.key, required this.notices});

  @override
  Widget build(BuildContext context) {
    final navy = Theme.of(context).colorScheme.onSurface;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Notice board',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: navy,
          ),
        ),
        const SizedBox(height: 12),
        if (notices.isEmpty)
          Text(
            'No notices for you yet.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          )
        else
          for (final n in notices)
            Card(
              child: ListTile(title: Text(n.title), subtitle: Text(n.body)),
            ),
      ],
    );
  }
}
