import 'package:flutter/material.dart';

import 'chat_tab.dart';
import 'meetings_tab.dart';
import 'notices_tab.dart';
import 'mock_data.dart';
import 'app_logo.dart';
import 'library_tab.dart';

class HomeShell extends StatefulWidget {
  final Member member;
  final Group group;

  const HomeShell({super.key, required this.member, required this.group});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(member: widget.member, group: widget.group),
      const ChatTab(),
      NoticesTab(
        notices: MockDb.notices
            .where((n) => n.groupId == widget.group.id)
            .toList(),
      ),
      MeetingsTab(groupName: widget.group.name),
      const LibraryTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: const [AppBarLogo()],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            label: 'Notices',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            label: 'Meetings',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String name;
  const _ComingSoon(this.name);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$name திரை அடுத்த படியில்'));
  }
}

class _HomeTab extends StatelessWidget {
  final Member member;
  final Group group;

  const _HomeTab({required this.member, required this.group});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1F2A5A);
    const teal = Color(0xFF1B9A85);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          group.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: navy,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Notice board',
          style: TextStyle(fontWeight: FontWeight.w700, color: navy),
        ),
        const SizedBox(height: 4),
        const Text(
          'No notices for you yet.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your groups: ${group.name}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const _UsageRow(label: 'Groups', used: 2, total: 3),
                const _UsageRow(label: 'Members', used: 22, total: 25),
                const _UsageRow(
                  label: 'Storage',
                  used: 0,
                  total: 2,
                  text: '0 B / 2.0 GB',
                ),
                const _UsageRow(
                  label: 'Meetings this month',
                  used: 0,
                  total: 10,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UsageRow extends StatelessWidget {
  final String label;
  final int used;
  final int total;
  final String? text;

  const _UsageRow({
    required this.label,
    required this.used,
    required this.total,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1B9A85);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(label), Text(text ?? '$used / $total')],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: total == 0 ? 0 : used / total,
            color: teal,
            backgroundColor: Colors.grey.shade200,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}
