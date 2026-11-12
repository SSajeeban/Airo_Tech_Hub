import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/app_models.dart';

enum _CalendarView { weekly, monthly, yearly }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  _CalendarView _calendarView = _CalendarView.weekly;
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  DateTime _startOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day - date.weekday % 7);
  }

  void _movePeriod(int direction) {
    setState(() {
      switch (_calendarView) {
        case _CalendarView.weekly:
          _currentDate = _currentDate.add(Duration(days: direction * 7));
        case _CalendarView.monthly:
          _currentDate = DateTime(
            _currentDate.year,
            _currentDate.month + direction,
          );
        case _CalendarView.yearly:
          _currentDate = DateTime(
            _currentDate.year + direction,
            _currentDate.month,
          );
      }
      _selectedDate = _currentDate;
    });
  }

  String _periodTitle() {
    switch (_calendarView) {
      case _CalendarView.weekly:
        final start = _startOfWeek(_currentDate);
        final end = start.add(const Duration(days: 6));
        final startText = DateFormat(
          start.year == end.year && start.month == end.month
              ? 'MMM d'
              : start.year == end.year
              ? 'MMM d'
              : 'MMM d, yyyy',
        ).format(start);
        final endText = DateFormat(
          start.year == end.year && start.month == end.month
              ? 'd, yyyy'
              : 'MMM d, yyyy',
        ).format(end);
        return '$startText – $endText';
      case _CalendarView.monthly:
        return DateFormat('MMMM yyyy').format(_currentDate);
      case _CalendarView.yearly:
        return '${_currentDate.year}';
    }
  }

  String _accountSlug(String displayName) {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    final lastPart = parts.isEmpty ? '' : parts.last;
    final slug = lastPart
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isEmpty ? 'educator' : slug;
  }

  int _meetingsInMonth(DateTime date, List<MeetingModel> meetings) {
    return meetings.where((meeting) {
      return meeting.scheduledTime.year == date.year &&
          meeting.scheduledTime.month == date.month;
    }).length;
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _currentDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final groups = ref.watch(groupsProvider);
    final members = ref.watch(membersProvider);
    final meetings = ref.watch(meetingsProvider);
    final notices = ref.watch(noticesProvider);
    final libraryItems = ref.watch(libraryItemsProvider);
    final isTamil = ref.watch(languageProvider) == 'ta';
    final displayName = session?.user.displayName.trim().isNotEmpty == true
        ? session!.user.displayName.trim()
        : 'Educator';
    final selectedMeeting = meetings
        .where(
          (meeting) =>
              meeting.scheduledTime.year == _selectedDate.year &&
              meeting.scheduledTime.month == _selectedDate.month &&
              meeting.scheduledTime.day == _selectedDate.day,
        )
        .firstOrNull;
    final storageMb = libraryItems.fold<double>(0, (total, item) {
      final match = RegExp(
        r'([\d.]+)\s*(KB|MB|GB)',
        caseSensitive: false,
      ).firstMatch(item.size);
      if (match == null) return total;
      final value = double.tryParse(match.group(1)!) ?? 0;
      switch (match.group(2)!.toUpperCase()) {
        case 'GB':
          return total + value * 1024;
        case 'KB':
          return total + value / 1024;
        default:
          return total + value;
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final wide = constraints.maxWidth >= 1100;
        final padding = compact ? 16.0 : 26.0;
        final calendar = _CalendarCard(
          view: _calendarView,
          currentDate: _currentDate,
          selectedDate: _selectedDate,
          title: _periodTitle(),
          meetings: meetings,
          onViewChanged: (view) => setState(() {
            _calendarView = view;
          }),
          onMovePeriod: _movePeriod,
          onSelectDate: _selectDate,
        );
        final eventPanel = _EventCard(
          meeting: selectedMeeting,
          selectedDate: _selectedDate,
        );

        return ListView(
          padding: EdgeInsets.fromLTRB(padding, 18, padding, 28),
          children: [
            Text(
              displayName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _NoticeBoard(notices: notices, isTamil: isTamil),
            const SizedBox(height: 18),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: calendar),
                  const SizedBox(width: 16),
                  SizedBox(width: 300, child: eventPanel),
                ],
              )
            else ...[
              calendar,
              const SizedBox(height: 14),
              eventPanel,
            ],
            const SizedBox(height: 16),
            _PlanUsageCard(
              planName: 'Pro',
              memberPortalSlug: _accountSlug(displayName),
              groupsUsed: groups.length,
              groupsLimit: 20,
              membersUsed: members.length,
              membersLimit: 200,
              storageMb: storageMb,
              meetingsUsed: _meetingsInMonth(DateTime.now(), meetings),
              meetingsLimit: 100,
            ),
          ],
        );
      },
    );
  }
}

class _NoticeBoard extends StatelessWidget {
  const _NoticeBoard({required this.notices, required this.isTamil});

  final List<NoticeModel> notices;
  final bool isTamil;

  @override
  Widget build(BuildContext context) {
    final latest = [...notices]
      ..sort((left, right) => right.publishedAt.compareTo(left.publishedAt));
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTamil ? 'அறிவிப்பு பலகை' : 'Notice board',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        if (latest.isEmpty)
          Text(
            isTamil ? 'அறிவிப்புகள் எதுவும் இல்லை.' : 'No notices yet.',
            style: TextStyle(color: colors.onSurfaceVariant),
          )
        else
          ...latest
              .take(2)
              .map(
                (notice) => Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    children: [
                      if (notice.isPinned)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.push_pin, size: 14),
                        ),
                      Expanded(
                        child: Text(
                          isTamil ? notice.titleTa : notice.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.view,
    required this.currentDate,
    required this.selectedDate,
    required this.title,
    required this.meetings,
    required this.onViewChanged,
    required this.onMovePeriod,
    required this.onSelectDate,
  });

  final _CalendarView view;
  final DateTime currentDate;
  final DateTime selectedDate;
  final String title;
  final List<MeetingModel> meetings;
  final ValueChanged<_CalendarView> onViewChanged;
  final ValueChanged<int> onMovePeriod;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final borderColor = isDark
                    ? const Color(0xFFB8C6D9)
                    : AppColors.lineLight;
                final secondaryText = isDark
                    ? const Color(0xFFCBD5E1)
                    : AppColors.mutedLight;
                final labels = {
                  _CalendarView.weekly: 'Weekly',
                  _CalendarView.monthly: 'Monthly',
                  _CalendarView.yearly: 'Yearly',
                };

                final viewSelector = Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: borderColor, width: 1.5),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _CalendarView.values.indexed.expand((entry) {
                        final (index, option) = entry;
                        return [
                          if (index > 0)
                            Container(
                              width: 1.5,
                              height: 32,
                              color: borderColor.withValues(alpha: 0.8),
                            ),
                          Material(
                            color: option == view
                                ? const Color(0xFF1687B8)
                                : Colors.transparent,
                            child: InkWell(
                              onTap: () => onViewChanged(option),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 9,
                                ),
                                child: Text(
                                  labels[option]!,
                                  style: TextStyle(
                                    color: option == view
                                        ? const Color(0xFF071525)
                                        : secondaryText,
                                    fontSize: 15,
                                    fontWeight: option == view
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ];
                      }).toList(),
                    ),
                  ),
                );
                final previousButton = IconButton(
                  tooltip: 'Previous',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onMovePeriod(-1),
                  icon: const Icon(AppIcons.previous, size: 30),
                );
                final nextButton = IconButton(
                  tooltip: 'Next',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onMovePeriod(1),
                  icon: const Icon(AppIcons.next, size: 30),
                );
                Widget dateSelector({required bool compact}) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) onSelectDate(date);
                    },
                    child: Container(
                      width: compact ? double.infinity : null,
                      constraints: compact
                          ? null
                          : BoxConstraints(maxWidth: constraints.maxWidth),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2E3C53)
                              : AppColors.lineLight,
                        ),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 16,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            AppIcons.calendar,
                            size: 20,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              compact
                                  ? DateFormat(
                                      'd MMM yyyy',
                                    ).format(selectedDate)
                                  : title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFE2E8F0)
                                    : AppColors.inkLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: secondaryText,
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      viewSelector,
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          previousButton,
                          Expanded(
                            child: Center(child: dateSelector(compact: true)),
                          ),
                          nextButton,
                        ],
                      ),
                    ],
                  );
                }

                return Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    viewSelector,
                    previousButton,
                    dateSelector(compact: false),
                    nextButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            switch (view) {
              _CalendarView.weekly => _WeekView(
                currentDate: currentDate,
                selectedDate: selectedDate,
                meetings: meetings,
                onSelectDate: onSelectDate,
              ),
              _CalendarView.monthly => _MonthView(
                currentDate: currentDate,
                selectedDate: selectedDate,
                meetings: meetings,
                onSelectDate: onSelectDate,
              ),
              _CalendarView.yearly => _YearView(
                currentDate: currentDate,
                meetings: meetings,
                onSelectMonth: (month) {
                  onViewChanged(_CalendarView.monthly);
                  onSelectDate(DateTime(currentDate.year, month));
                },
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.currentDate,
    required this.selectedDate,
    required this.meetings,
    required this.onSelectDate,
  });

  final DateTime currentDate;
  final DateTime selectedDate;
  final List<MeetingModel> meetings;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final start = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day - currentDate.weekday % 7,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth >= 550
            ? (constraints.maxWidth - 48) / 7
            : 76.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(7, (index) {
              final date = start.add(Duration(days: index));
              final selected = DateUtils.isSameDay(date, selectedDate);
              final count = meetings.where((meeting) {
                return DateUtils.isSameDay(meeting.scheduledTime, date);
              }).length;
              return Container(
                width: cellWidth,
                height: 118,
                margin: EdgeInsets.only(right: index == 6 ? 0 : 8),
                child: _DayTile(
                  date: date,
                  selected: selected,
                  meetingCount: count,
                  onTap: () => onSelectDate(date),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.date,
    required this.selected,
    required this.meetingCount,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final int meetingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = colors.primary;
    return Material(
      color: selected
          ? primary.withValues(alpha: 0.08)
          : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEE').format(date),
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: selected ? colors.onPrimary : colors.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (meetingCount > 0) ...[
                const Spacer(),
                Text(
                  '$meetingCount event${meetingCount == 1 ? '' : 's'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: primary, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.currentDate,
    required this.selectedDate,
    required this.meetings,
    required this.onSelectDate,
  });

  final DateTime currentDate;
  final DateTime selectedDate;
  final List<MeetingModel> meetings;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(currentDate.year, currentDate.month);
    final gridStart = DateTime(
      firstOfMonth.year,
      firstOfMonth.month,
      1 - firstOfMonth.weekday % 7,
    );
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: List.generate(7, (index) {
            final day = DateTime(2024, 1, 7 + index);
            return Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    DateFormat('E').format(day),
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        ...List.generate(6, (week) {
          return Row(
            children: List.generate(7, (day) {
              final date = gridStart.add(Duration(days: week * 7 + day));
              final inMonth = date.month == currentDate.month;
              final selected = DateUtils.isSameDay(date, selectedDate);
              final hasMeetings = meetings.any(
                (meeting) => DateUtils.isSameDay(meeting.scheduledTime, date),
              );
              return Expanded(
                child: AspectRatio(
                  aspectRatio: 1.15,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Material(
                      color: selected ? colors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => onSelectDate(date),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color: selected
                                    ? colors.onPrimary
                                    : inMonth
                                    ? colors.onSurface
                                    : colors.onSurfaceVariant.withValues(
                                        alpha: 0.45,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (hasMeetings)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? colors.onPrimary
                                      : colors.primary,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              const SizedBox(height: 5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}

class _YearView extends StatelessWidget {
  const _YearView({
    required this.currentDate,
    required this.meetings,
    required this.onSelectMonth,
  });

  final DateTime currentDate;
  final List<MeetingModel> meetings;
  final ValueChanged<int> onSelectMonth;

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.sizeOf(context).width < 560 ? 2 : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: 76,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final month = index + 1;
        final count = meetings.where((meeting) {
          return meeting.scheduledTime.year == currentDate.year &&
              meeting.scheduledTime.month == month;
        }).length;
        return OutlinedButton(
          onPressed: () => onSelectMonth(month),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(DateFormat('MMMM').format(DateTime(2000, month))),
              ),
              if (count > 0)
                Text(
                  '$count',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.meeting, required this.selectedDate});

  final MeetingModel? meeting;
  final DateTime selectedDate;

  Future<void> _launchMeeting(BuildContext context) async {
    final selectedMeeting = meeting;
    if (selectedMeeting == null) return;
    final uri = Uri.tryParse(selectedMeeting.meetingUrl);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the meeting link.')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (meeting == null)
              Text(
                'Select a meeting to see the details and join link.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              )
            else ...[
              Text(
                meeting!.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(meeting!.groupName),
              const SizedBox(height: 8),
              Text(
                '${DateFormat('EEE, d MMM yyyy').format(meeting!.scheduledTime)} · ${DateFormat('h:mm a').format(meeting!.scheduledTime)}',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _launchMeeting(context),
                icon: const Icon(AppIcons.meetings),
                label: const Text('Open meeting'),
              ),
            ],
            if (meeting == null)
              const SizedBox(height: 2)
            else
              Text(
                'Selected ${DateFormat('d MMM yyyy').format(selectedDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanUsageCard extends StatelessWidget {
  const _PlanUsageCard({
    required this.planName,
    required this.memberPortalSlug,
    required this.groupsUsed,
    required this.groupsLimit,
    required this.membersUsed,
    required this.membersLimit,
    required this.storageMb,
    required this.meetingsUsed,
    required this.meetingsLimit,
  });

  final String planName;
  final String memberPortalSlug;
  final int groupsUsed;
  final int groupsLimit;
  final int membersUsed;
  final int membersLimit;
  final double storageMb;
  final int meetingsUsed;
  final int meetingsLimit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan · $planName',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(height: 6),
            Text('Member portal slug: $memberPortalSlug'),
            const SizedBox(height: 16),
            _UsageMeter(
              label: 'Groups',
              valueLabel: '$groupsUsed / $groupsLimit',
              value: groupsUsed,
              limit: groupsLimit,
            ),
            const SizedBox(height: 13),
            _UsageMeter(
              label: 'Members',
              valueLabel: '$membersUsed / $membersLimit',
              value: membersUsed,
              limit: membersLimit,
            ),
            const SizedBox(height: 13),
            _UsageMeter(
              label: 'Storage',
              valueLabel:
                  '${storageMb.toStringAsFixed(storageMb < 10 ? 1 : 0)} MB / 50 GB',
              value: storageMb,
              limit: 50 * 1024,
            ),
            const SizedBox(height: 13),
            _UsageMeter(
              label: 'Meetings this month',
              valueLabel: '$meetingsUsed / $meetingsLimit',
              value: meetingsUsed,
              limit: meetingsLimit,
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageMeter extends StatelessWidget {
  const _UsageMeter({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.limit,
  });

  final String label;
  final String valueLabel;
  final num value;
  final num limit;

  @override
  Widget build(BuildContext context) {
    final progress = limit <= 0 ? 0.0 : (value / limit).clamp(0.0, 1.0);
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(valueLabel, style: TextStyle(color: colors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: colors.surfaceContainerHighest,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}
