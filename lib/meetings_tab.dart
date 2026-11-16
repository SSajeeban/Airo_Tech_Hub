import 'package:flutter/material.dart';

class MeetingItem {
  final String id;
  final String title;
  final String groupName;
  final String startsAt;
  final String status; // 'Live', 'Upcoming', 'Ended'
  final String? joinUrl;

  const MeetingItem({
    required this.id,
    required this.title,
    required this.groupName,
    required this.startsAt,
    required this.status,
    this.joinUrl,
  });
}

class MeetingsTab extends StatefulWidget {
  final String memberName;
  final String groupName;
  final bool isTamil;

  const MeetingsTab({
    super.key,
    required this.groupName,
    this.memberName = 'A.Nismina',
    this.isTamil = false,
  });

  @override
  State<MeetingsTab> createState() => _MeetingsTabState();
}

class _MeetingsTabState extends State<MeetingsTab> {
  // Initial empty list matching the exact reference screenshot ("No meetings yet.")
  final List<MeetingItem> _meetings = [];

  void _showNewMeetingDialog() {
    final titleColor = Theme.of(context).colorScheme.onSurface;
    final titleController = TextEditingController(
      text: '${widget.groupName} Catchup',
    );
    final timeController = TextEditingController(text: 'Today, 5:00 PM');
    String selectedStatus = 'Upcoming';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            widget.isTamil ? 'புதிய கூட்டம் அமைக்க' : 'Schedule New Meeting',
            style: TextStyle(fontWeight: FontWeight.bold, color: titleColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: widget.isTamil
                      ? 'கூட்டம் தலைப்பு'
                      : 'Meeting Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: widget.isTamil ? 'ஆரம்ப நேரம்' : 'Starts At',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: widget.isTamil ? 'நிலை' : 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Live', child: Text('Live')),
                  DropdownMenuItem(value: 'Upcoming', child: Text('Upcoming')),
                  DropdownMenuItem(value: 'Ended', child: Text('Ended')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedStatus = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(widget.isTamil ? 'ரத்து' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                setState(() {
                  _meetings.add(
                    MeetingItem(
                      id: 'meet_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      groupName: widget.groupName,
                      startsAt: timeController.text.trim(),
                      status: selectedStatus,
                    ),
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.isTamil
                          ? 'கூட்டம் சேர்க்கப்பட்டது!'
                          : 'Meeting scheduled successfully!',
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B9A85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(widget.isTamil ? 'சேர்' : 'Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _loadSampleMeetings() {
    setState(() {
      _meetings.clear();
      _meetings.addAll([
        MeetingItem(
          id: '1',
          title: '${widget.groupName} Daily Sync',
          groupName: widget.groupName,
          startsAt: '10 Nov 2026 | 16:30',
          status: 'Live',
        ),
        MeetingItem(
          id: '2',
          title: 'Review & Planning Session',
          groupName: widget.groupName,
          startsAt: '12 Nov 2026 | 10:00',
          status: 'Upcoming',
        ),
      ]);
    });
  }

  void _clearMeetings() {
    setState(() {
      _meetings.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1F2A5A);
    const teal = Color(0xFF1B9A85);
    final colors = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 750;
    final headerTitle = RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${widget.memberName} / ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
          TextSpan(
            text: widget.isTamil ? 'கூட்டங்கள்' : 'Meetings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
    final headerActions = Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 4,
      children: [
        if (_meetings.isNotEmpty)
          TextButton.icon(
            onPressed: _clearMeetings,
            icon: const Icon(Icons.clear_all, size: 16),
            label: Text(widget.isTamil ? 'அழி' : 'Clear'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
          ),
        if (_meetings.isEmpty)
          TextButton.icon(
            onPressed: _loadSampleMeetings,
            icon: const Icon(Icons.playlist_add, size: 16, color: teal),
            label: Text(
              widget.isTamil ? 'மாதிரி கூட்டம்' : 'Load Sample',
              style: const TextStyle(color: teal),
            ),
          ),
        FilledButton.icon(
          onPressed: _showNewMeetingDialog,
          icon: const Icon(Icons.add, size: 18),
          label: Text(widget.isTamil ? 'புதிய கூட்டம்' : 'New Meeting'),
          style: FilledButton.styleFrom(
            backgroundColor: teal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            Row(
              children: [
                Expanded(child: headerTitle),
                const SizedBox(width: 16),
                headerActions,
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerTitle,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: headerActions),
              ],
            ),
          const SizedBox(height: 20),

          // Main Meeting Table Card matching reference image
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Table Header Row: "Meeting", "Starts", "Status", "Actions"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    border: Border(
                      bottom: BorderSide(color: colors.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: isWide ? 4 : 4,
                        child: Text(
                          widget.isTamil ? 'கூட்டம்' : 'Meeting',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: isWide ? 3 : 3,
                        child: Text(
                          widget.isTamil ? 'ஆரம்பம்' : 'Starts',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: isWide ? 3 : 2,
                        child: Text(
                          widget.isTamil ? 'நிலை' : 'Status',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: isWide ? 2 : 2,
                        child: Text(
                          widget.isTamil ? 'செயல்கள்' : 'Actions',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Content (Empty State or List)
                if (_meetings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Text(
                      widget.isTamil
                          ? 'கூட்டங்கள் எதுவும் இல்லை.'
                          : 'No meetings yet.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < _meetings.length; i++)
                    _buildMeetingRow(
                      _meetings[i],
                      i == _meetings.length - 1,
                      isWide,
                      teal,
                      navy,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingRow(
    MeetingItem item,
    bool isLast,
    bool isWide,
    Color teal,
    Color navy,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          // Meeting Name
          Expanded(
            flex: isWide ? 4 : 4,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.videocam_outlined,
                    color: Color(0xFF1B9A85),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Starts At
          Expanded(
            flex: isWide ? 3 : 3,
            child: Text(
              item.startsAt,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ),

          // Status Badge
          Expanded(
            flex: isWide ? 3 : 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(item.status),
            ),
          ),

          // Actions
          Expanded(
            flex: isWide ? 2 : 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Connecting to ${item.title}...')),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  widget.isTamil ? 'இணை' : 'Join',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'Live':
        bg = const Color(0xFF1B9A85).withValues(alpha: 0.15);
        fg = const Color(0xFF1B9A85);
        break;
      case 'Upcoming':
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
