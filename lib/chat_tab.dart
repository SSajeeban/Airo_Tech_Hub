import 'package:material_ui/material_ui.dart';

import 'admin/core/constants/app_icons.dart';

import 'admin/core/constants/app_icons.dart';

enum _PresenceStatus {
  online,
  available,
  busy,
  doNotDisturb,
  beRightBack,
  appearAway,
  appearOffline,
  reset,
}

class ChatTab extends StatefulWidget {
  final String memberName;

  const ChatTab({super.key, required this.memberName});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  String _filter = 'Chats';
  _PresenceStatus _presenceStatus = _PresenceStatus.online;
  bool _isPresenceMenuOpen = false;

  static const _presenceStatuses = [
    _PresenceStatus.online,
    _PresenceStatus.available,
    _PresenceStatus.busy,
    _PresenceStatus.doNotDisturb,
    _PresenceStatus.beRightBack,
    _PresenceStatus.appearAway,
    _PresenceStatus.appearOffline,
  ];

  String _statusLabel(_PresenceStatus status) => switch (status) {
    _PresenceStatus.online => 'Online',
    _PresenceStatus.available => 'Available',
    _PresenceStatus.busy => 'Busy',
    _PresenceStatus.doNotDisturb => 'Do not disturb',
    _PresenceStatus.beRightBack => 'Be right back',
    _PresenceStatus.appearAway => 'Appear away',
    _PresenceStatus.appearOffline => 'Appear offline',
    _PresenceStatus.reset => 'Reset status',
  };

  Color _statusColor(_PresenceStatus status) => switch (status) {
    _PresenceStatus.online ||
    _PresenceStatus.available => const Color(0xFF00B884),
    _PresenceStatus.busy ||
    _PresenceStatus.doNotDisturb => const Color(0xFFFF303B),
    _PresenceStatus.beRightBack ||
    _PresenceStatus.appearAway => const Color(0xFFFFB400),
    _PresenceStatus.appearOffline ||
    _PresenceStatus.reset => const Color(0xFF94A3B8),
  };

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1B9A85);
    const filters = ['Unread', 'Channels', 'Chats'];
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Text(
                'Chat',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Channels',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _filter = 'Channels'),
                icon: Icon(
                  AppIcons.groups,
                  color: _filter == 'Channels' ? teal : colors.onSurfaceVariant,
                ),
              ),
              IconButton(
                tooltip: 'New chat',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _filter = 'Chats'),
                icon: Icon(
                  AppIcons.conversation,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(AppIcons.search),
              filled: true,
              fillColor: colors.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Material(
                      color: _filter == f
                          ? teal
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => _filter = f),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: _filter == f
                                  ? Colors.white
                                  : colors.onSurface,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Divider(height: 24, color: colors.outlineVariant),
        Expanded(
          child: Center(
            child: Text(
              _filter == 'Chats'
                  ? 'No chats yet. Start a conversation.'
                  : 'Nothing in $_filter yet.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ),
        Divider(height: 1, color: colors.outlineVariant),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _buildAvatar(teal, showStatusDot: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.memberName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _statusLabel(_presenceStatus),
                        style: TextStyle(
                          color: colors.brightness == Brightness.dark
                              ? colors.onSurface
                              : Colors.black,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_PresenceStatus>(
                  tooltip: 'Change status',
                  initialValue: _presenceStatus,
                  onOpened: () => setState(() => _isPresenceMenuOpen = true),
                  onCanceled: () => setState(() => _isPresenceMenuOpen = false),
                  onSelected: (status) => setState(() {
                    _isPresenceMenuOpen = false;
                    _presenceStatus = status == _PresenceStatus.reset
                        ? _PresenceStatus.online
                        : status;
                  }),
                  itemBuilder: _buildPresenceMenu,
                  icon: Icon(
                    _isPresenceMenuOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(Color teal, {bool showStatusDot = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: teal.withValues(alpha: 0.14),
          child: Text(
            widget.memberName.isNotEmpty
                ? widget.memberName[0].toUpperCase()
                : 'S',
            style: TextStyle(color: teal, fontWeight: FontWeight.w700),
          ),
        ),
        if (showStatusDot)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: _statusDot(_presenceStatus, size: 12),
            ),
          ),
      ],
    );
  }

  Widget _statusDot(_PresenceStatus status, {required double size}) {
    final color = _statusColor(status);
    if (status == _PresenceStatus.doNotDisturb) {
      return Icon(Icons.do_not_disturb_on, color: color, size: size + 4);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  List<PopupMenuEntry<_PresenceStatus>> _buildPresenceMenu(
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;

    return [
      PopupMenuItem<_PresenceStatus>(
        enabled: false,
        height: 76,
        child: Row(
          children: [
            _buildAvatar(const Color(0xFF1B9A85), showStatusDot: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.memberName,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Member',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(height: 8),
      for (final status in _presenceStatuses)
        PopupMenuItem<_PresenceStatus>(
          value: status,
          height: 52,
          child: Row(
            children: [
              _statusDot(status, size: 20),
              const SizedBox(width: 14),
              Expanded(child: Text(_statusLabel(status))),
              if (_presenceStatus == status)
                const Icon(Icons.check, color: Color(0xFF1B9A85), size: 20)
              else
                Icon(
                  Icons.chevron_right,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
            ],
          ),
        ),
      const PopupMenuDivider(height: 8),
      PopupMenuItem<_PresenceStatus>(
        value: _PresenceStatus.reset,
        height: 44,
        child: Text(
          'Reset status',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      ),
    ];
  }
}
