import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import 'admin/models/app_models.dart';
import 'mock_meeting_store.dart';

import 'app_settings.dart';

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

  factory MeetingItem.fromModel(MeetingModel meeting) => MeetingItem(
    id: meeting.id,
    title: meeting.title,
    groupName: meeting.groupName,
    startsAt: DateFormat('dd MMM yyyy, h:mm a').format(meeting.scheduledTime),
    status: meeting.isLive ? 'Live' : 'Upcoming',
    joinUrl: meeting.meetingUrl,
  );
}

class MeetingsTab extends StatefulWidget {
  final String memberName;
  final int groupId;
  final bool isTamil;

  const MeetingsTab({
    super.key,
    required this.groupId,
    this.memberName = 'A.Nismina',
    this.isTamil = false,
  });

  @override
  State<MeetingsTab> createState() => _MeetingsTabState();
}

class _MeetingsTabState extends State<MeetingsTab> {
  String _tr(String value) => AppSettings.instance.tr(value);

  MockMeetingStore get _meetingStore => MockMeetingStore.instance;

  @override
  void initState() {
    super.initState();
    _meetingStore.addListener(_onMeetingsChanged);
  }

  @override
  void dispose() {
    _meetingStore.removeListener(_onMeetingsChanged);
    super.dispose();
  }

  void _onMeetingsChanged() {
    if (mounted) setState(() {});
  }

  List<MeetingItem> get _meetings => _meetingStore
      .meetingsForMemberGroup(widget.groupId)
      .map(MeetingItem.fromModel)
      .toList();

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1B9A85);
    final colors = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 750;
    final meetings = _meetings;
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
            text: _tr('Meetings'),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerTitle,
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
                        flex: 4,
                        child: Text(
                          _tr('Meeting'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _tr('Starts'),
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
                          _tr('Status'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _tr('Actions'),
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
                if (meetings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Text(
                      _tr('No meetings yet.'),
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < meetings.length; i++)
                    _buildMeetingRow(
                      meetings[i],
                      i == meetings.length - 1,
                      isWide,
                      teal,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.groupName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
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
                  _tr('Join'),
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
