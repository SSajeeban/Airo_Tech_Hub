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

  void _onToday() {
    setState(() {
      _currentDate = DateTime.now();
      _selectedDate = DateTime.now();
    });
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

  String _periodTitle(bool isTamil) {
    switch (_calendarView) {
      case _CalendarView.weekly:
        final start = _startOfWeek(_currentDate);
        final end = start.add(const Duration(days: 6));
        if (isTamil) {
          const taMonths = [
            'ஜன',
            'பிப்',
            'மார்',
            'ஏப்',
            'மே',
            'ஜூன்',
            'ஜூலை',
            'ஆக',
            'செப்',
            'அக்',
            'நவ',
            'டிச'
          ];
          return '${start.day} ${taMonths[start.month - 1]} – ${end.day} ${taMonths[end.month - 1]} ${end.year}';
        }
        final f = DateFormat('d MMM');
        return '${f.format(start)} – ${f.format(end)} ${_currentDate.year}';
      case _CalendarView.monthly:
        if (isTamil) {
          const taFullMonths = [
            'ஜனவரி',
            'பிப்ரவரி',
            'மார்ச்',
            'ஏப்ரல்',
            'மே',
            'ஜூன்',
            'ஜூலை',
            'ஆகஸ்ட்',
            'செப்டம்பர்',
            'அக்டோபர்',
            'நவம்பர்',
            'டிசம்பர்'
          ];
          return '${taFullMonths[_currentDate.month - 1]} ${_currentDate.year}';
        }
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
          title: _periodTitle(isTamil),
          meetings: meetings,
          isTamil: isTamil,
          onViewChanged: (view) => setState(() {
            _calendarView = view;
          }),
          onMovePeriod: _movePeriod,
          onSelectDate: _selectDate,
          onToday: _onToday,
        );
        final eventPanel = _EventCard(
          meeting: selectedMeeting,
          selectedDate: _selectedDate,
          isTamil: isTamil,
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
              planName: isTamil ? 'புரோ' : 'Pro',
              memberPortalSlug: _accountSlug(displayName),
              groupsUsed: groups.length,
              groupsLimit: 20,
              membersUsed: members.length,
              membersLimit: 200,
              storageMb: storageMb,
              meetingsUsed: _meetingsInMonth(DateTime.now(), meetings),
              meetingsLimit: 100,
              isTamil: isTamil,
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
    required this.isTamil,
    required this.onViewChanged,
    required this.onMovePeriod,
    required this.onSelectDate,
    required this.onToday,
  });

  final _CalendarView view;
  final DateTime currentDate;
  final DateTime selectedDate;
  final String title;
  final List<MeetingModel> meetings;
  final bool isTamil;
  final ValueChanged<_CalendarView> onViewChanged;
  final ValueChanged<int> onMovePeriod;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1F2A5A);
    const teal = Color(0xFF1B9A85);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? teal : navy;

    return Container(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 400 ? 12 : 20,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date range (e.g. "15 Nov – 21 Nov 2026")
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) onSelectDate(date);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // View switches + Nav buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Segmented Tabs: Weekly, Monthly, Yearly
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewButton(
                      _CalendarView.weekly,
                      isTamil ? 'வாராந்திர' : 'Weekly',
                      teal,
                      colors.onSurface,
                    ),
                    _buildViewButton(
                      _CalendarView.monthly,
                      isTamil ? 'மாதாந்திர' : 'Monthly',
                      teal,
                      colors.onSurface,
                    ),
                    _buildViewButton(
                      _CalendarView.yearly,
                      isTamil ? 'வருடாந்திர' : 'Yearly',
                      teal,
                      colors.onSurface,
                    ),
                  ],
                ),
              ),

              // Controls: < Today >
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavIconButton(
                    Icons.chevron_left,
                    () => onMovePeriod(-1),
                    colors.onSurface,
                    colors.outlineVariant,
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: onToday,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      side: BorderSide(color: colors.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isTamil ? 'இன்று' : 'Today',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildNavIconButton(
                    Icons.chevron_right,
                    () => onMovePeriod(1),
                    colors.onSurface,
                    colors.outlineVariant,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Day Views
          switch (view) {
            _CalendarView.weekly => _WeekView(
              currentDate: currentDate,
              selectedDate: selectedDate,
              meetings: meetings,
              isTamil: isTamil,
              onSelectDate: onSelectDate,
              selectedColor: selectedColor,
              tealColor: teal,
            ),
            _CalendarView.monthly => _MonthView(
              currentDate: currentDate,
              selectedDate: selectedDate,
              meetings: meetings,
              isTamil: isTamil,
              onSelectDate: onSelectDate,
              selectedColor: selectedColor,
              tealColor: teal,
            ),
            _CalendarView.yearly => _YearView(
              currentDate: currentDate,
              meetings: meetings,
              isTamil: isTamil,
              selectedColor: selectedColor,
              tealColor: teal,
              onSelectMonth: (month) {
                onViewChanged(_CalendarView.monthly);
                onSelectDate(DateTime(currentDate.year, month));
              },
            ),
          },
        ],
      ),
    );
  }

  Widget _buildViewButton(
    _CalendarView targetView,
    String label,
    Color activeColor,
    Color textColor,
  ) {
    final isSelected = view == targetView;
    return InkWell(
      onTap: () => onViewChanged(targetView),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildNavIconButton(
    IconData icon,
    VoidCallback onPressed,
    Color iconColor,
    Color borderColor,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.currentDate,
    required this.selectedDate,
    required this.meetings,
    required this.isTamil,
    required this.onSelectDate,
    required this.selectedColor,
    required this.tealColor,
  });

  final DateTime currentDate;
  final DateTime selectedDate;
  final List<MeetingModel> meetings;
  final bool isTamil;
  final ValueChanged<DateTime> onSelectDate;
  final Color selectedColor;
  final Color tealColor;

  @override
  Widget build(BuildContext context) {
    final startOfWeek = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day - currentDate.weekday % 7,
    );
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (int i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _DayColumn(
              date: days[i],
              isSelected: DateUtils.isSameDay(days[i], selectedDate),
              isToday: DateUtils.isSameDay(days[i], DateTime.now()),
              meetingCount: meetings
                  .where((m) => DateUtils.isSameDay(m.scheduledTime, days[i]))
                  .length,
              isTamil: isTamil,
              selectedColor: selectedColor,
              tealColor: tealColor,
              textColor: colors.onSurface,
              mutedColor: colors.onSurfaceVariant,
              surfaceColor: colors.surface,
              outlineColor: colors.outlineVariant,
              onTap: () => onSelectDate(days[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.meetingCount,
    required this.isTamil,
    required this.selectedColor,
    required this.tealColor,
    required this.textColor,
    required this.mutedColor,
    required this.surfaceColor,
    required this.outlineColor,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final int meetingCount;
  final bool isTamil;
  final Color selectedColor;
  final Color tealColor;
  final Color textColor;
  final Color mutedColor;
  final Color surfaceColor;
  final Color outlineColor;
  final VoidCallback onTap;

  static const _taDayNames = [
    'திங்',
    'செவ்',
    'புதன்',
    'வியா',
    'வெள்',
    'சனி',
    'ஞாயி',
  ];

  @override
  Widget build(BuildContext context) {
    final hasEvents = meetingCount > 0;
    final dayLabel = isTamil
        ? _taDayNames[date.weekday - 1]
        : DateFormat('EEE').format(date);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 16,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dayLabel,
              style: TextStyle(
                color: isSelected ? selectedColor : mutedColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : surfaceColor,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isSelected
                      ? selectedColor
                      : (isToday ? tealColor : outlineColor),
                  width: isToday && !isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: isSelected ? Colors.white : textColor,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (hasEvents)
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: tealColor,
              shape: BoxShape.circle,
            ),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.currentDate,
    required this.selectedDate,
    required this.meetings,
    required this.isTamil,
    required this.onSelectDate,
    required this.selectedColor,
    required this.tealColor,
  });

  final DateTime currentDate;
  final DateTime selectedDate;
  final List<MeetingModel> meetings;
  final bool isTamil;
  final ValueChanged<DateTime> onSelectDate;
  final Color selectedColor;
  final Color tealColor;

  static const _enDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _taDays = ['ஞாயி', 'திங்', 'செவ்', 'புதன்', 'வியா', 'வெள்', 'சனி'];

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(currentDate.year, currentDate.month, 1);
    final daysInMonth = DateTime(
      currentDate.year,
      currentDate.month + 1,
      0,
    ).day;
    final startWeekday = firstOfMonth.weekday % 7;
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: List.generate(7, (index) {
            return Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    isTamil ? _taDays[index] : _enDays[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: 1,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startWeekday) return const SizedBox();

            final dayNumber = index - startWeekday + 1;
            final date = DateTime(
              currentDate.year,
              currentDate.month,
              dayNumber,
            );
            final isSelected = DateUtils.isSameDay(date, selectedDate);
            final isToday = DateUtils.isSameDay(date, DateTime.now());
            final hasMeetings = meetings.any(
              (meeting) => DateUtils.isSameDay(meeting.scheduledTime, date),
            );

            return InkWell(
              onTap: () => onSelectDate(date),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? selectedColor
                        : (isToday ? tealColor : colors.outlineVariant),
                    width: isToday && !isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isToday ? tealColor : colors.onSurface),
                        fontWeight: isSelected || isToday
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (hasMeetings)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : tealColor,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 5),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _YearView extends StatelessWidget {
  const _YearView({
    required this.currentDate,
    required this.meetings,
    required this.isTamil,
    required this.onSelectMonth,
    required this.selectedColor,
    required this.tealColor,
  });

  final DateTime currentDate;
  final List<MeetingModel> meetings;
  final bool isTamil;
  final ValueChanged<int> onSelectMonth;
  final Color selectedColor;
  final Color tealColor;

  static const _enMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _taMonths = [
    'ஜன', 'பிப்', 'மார்', 'ஏப்', 'மே', 'ஜூன்',
    'ஜூலை', 'ஆக', 'செப்', 'அக்', 'நவ', 'டிச',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.35,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final isSelectedMonth = currentDate.month == month;
        final hasEvents = meetings.any((meeting) {
          final t = meeting.scheduledTime;
          return t.year == currentDate.year && t.month == month;
        });

        return InkWell(
          onTap: () => onSelectMonth(month),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelectedMonth
                  ? selectedColor
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelectedMonth ? selectedColor : colors.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isTamil ? _taMonths[index] : _enMonths[index],
                  style: TextStyle(
                    color: isSelectedMonth ? Colors.white : colors.onSurface,
                    fontWeight: isSelectedMonth
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (hasEvents) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelectedMonth ? Colors.white : tealColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.meeting,
    required this.selectedDate,
    required this.isTamil,
  });

  final MeetingModel? meeting;
  final DateTime selectedDate;
  final bool isTamil;

  static const _taDays = [
    'திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி', 'சனி', 'ஞாயிறு'
  ];
  static const _taFullMonths = [
    'ஜனவரி', 'பிப்ரவரி', 'மார்ச்', 'ஏப்ரல்', 'மே', 'ஜூன்',
    'ஜூலை', 'ஆகஸ்ட்', 'செப்டம்பர்', 'அக்டோபர்', 'நவம்பர்', 'டிசம்பர்'
  ];
  static const _taShortMonths = [
    'ஜன', 'பிப்', 'மார்', 'ஏப்', 'மே', 'ஜூன்',
    'ஜூலை', 'ஆக', 'செப்', 'அக்', 'நவ', 'டிச'
  ];

  String _formatMeetingDateTime(DateTime dt) {
    final timeStr = DateFormat('h:mm a').format(dt);
    if (isTamil) {
      final dayName = _taDays[dt.weekday - 1];
      final monthName = _taFullMonths[dt.month - 1];
      return '$dayName, ${dt.day} $monthName ${dt.year} · $timeStr';
    }
    return '${DateFormat('EEE, d MMM yyyy').format(dt)} · $timeStr';
  }

  String _formatSelectedDate(DateTime dt) {
    if (isTamil) {
      final monthName = _taShortMonths[dt.month - 1];
      return '${dt.day} $monthName ${dt.year}';
    }
    return DateFormat('d MMM yyyy').format(dt);
  }

  Future<void> _launchMeeting(BuildContext context) async {
    final selectedMeeting = meeting;
    if (selectedMeeting == null) return;
    final uri = Uri.tryParse(selectedMeeting.meetingUrl);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTamil
                  ? 'கூட்ட இணைப்பைத் திறக்க முடியவில்லை.'
                  : 'Unable to open the meeting link.',
            ),
          ),
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
              isTamil ? 'நிகழ்வு' : 'Event',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (meeting == null)
              Text(
                isTamil
                    ? 'விவரங்கள் மற்றும் இணையும் இணைப்பைப் பார்க்க ஒரு கூட்டத்தைத் தேர்ந்தெடுக்கவும்.'
                    : 'Select a meeting to see the details and join link.',
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
              Text(_formatMeetingDateTime(meeting!.scheduledTime)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _launchMeeting(context),
                icon: const Icon(AppIcons.meetings),
                label: Text(isTamil ? 'கூட்டத்தில் இணையவும்' : 'Open meeting'),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '${isTamil ? 'தேர்ந்தெடுக்கப்பட்டது' : 'Selected'} ${_formatSelectedDate(selectedDate)}',
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
    required this.isTamil,
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
  final bool isTamil;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTamil ? 'திட்டம் · $planName' : 'Plan · $planName',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(height: 6),
            Text(
              isTamil
                  ? 'உறுப்பினர் போர்டல் முகவரி: $memberPortalSlug'
                  : 'Member portal slug: $memberPortalSlug',
            ),
            const SizedBox(height: 16),
            _UsageMeter(
              label: isTamil ? 'குழுக்கள்' : 'Groups',
              valueLabel: '$groupsUsed / $groupsLimit',
              value: groupsUsed,
              limit: groupsLimit,
            ),
            const SizedBox(height: 13),
            _UsageMeter(
              label: isTamil ? 'உறுப்பினர்கள்' : 'Members',
              valueLabel: '$membersUsed / $membersLimit',
              value: membersUsed,
              limit: membersLimit,
            ),
            const SizedBox(height: 13),
            _UsageMeter(
              label: isTamil ? 'சேமிப்பகம்' : 'Storage',
              valueLabel:
                  '${storageMb.toStringAsFixed(storageMb < 10 ? 1 : 0)} MB / 50 GB',
              value: storageMb,
              limit: 50 * 1024,
            ),
            const SizedBox(height: 13),
            _UsageMeter(
              label: isTamil ? 'இந்த மாத கூட்டங்கள்' : 'Meetings this month',
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
