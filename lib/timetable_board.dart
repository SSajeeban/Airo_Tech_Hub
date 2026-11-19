import 'package:material_ui/material_ui.dart';

import 'mock_data.dart';

class AppDateHelper {
  static const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const fullMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const shortWeekdays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static String formatShortDay(DateTime d) {
    return shortWeekdays[d.weekday % 7];
  }

  static String formatWeekRange(DateTime start, DateTime end) {
    return '${start.day} ${months[start.month - 1]} – ${end.day} ${months[end.month - 1]} ${end.year}';
  }

  static String formatFullDate(DateTime d) {
    return '${formatShortDay(d)}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String formatClock(DateTime d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} | ${twoDigits(d.hour)}:${twoDigits(d.minute)}:${twoDigits(d.second)}';
  }
}

class TimetableBoard extends StatefulWidget {
  final Group group;
  final Member member;

  const TimetableBoard({super.key, required this.group, required this.member});

  @override
  State<TimetableBoard> createState() => _TimetableBoardState();
}

class _TimetableBoardState extends State<TimetableBoard> {
  late DateTime _selectedDate;
  String _viewMode = 'Weekly'; // 'Weekly', 'Monthly', 'Yearly'

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _onPrev() {
    setState(() {
      if (_viewMode == 'Weekly') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      } else if (_viewMode == 'Monthly') {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month - 1,
          _selectedDate.day,
        );
      } else {
        _selectedDate = DateTime(
          _selectedDate.year - 1,
          _selectedDate.month,
          _selectedDate.day,
        );
      }
    });
  }

  void _onNext() {
    setState(() {
      if (_viewMode == 'Weekly') {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      } else if (_viewMode == 'Monthly') {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + 1,
          _selectedDate.day,
        );
      } else {
        _selectedDate = DateTime(
          _selectedDate.year + 1,
          _selectedDate.month,
          _selectedDate.day,
        );
      }
    });
  }

  void _onToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Week starts on Sunday
    final daysToSubtract = date.weekday % 7;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  bool _hasEvents(DateTime date) {
    return _eventsForDate(date).isNotEmpty;
  }

  List<CalendarEvent> _eventsForDate(DateTime date) {
    return MockDb.eventsForGroup(widget.group.id)
        .where(
          (event) =>
              event.date.year == date.year &&
              event.date.month == date.month &&
              event.date.day == date.day,
        )
        .toList();
  }

  void _showEventsForDate(DateTime date) {
    final events = _eventsForDate(date);

    //
    if (events.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(AppDateHelper.formatFullDate(date)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: events.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final event = events[index];

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F4F0),
                  child: Icon(Icons.event, color: Color(0xFF1B9A85)),
                ),
                title: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${event.startTime} - ${event.endTime}\n'
                  '${event.description}',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF1B9A85)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    final hasSelectedDateEvents = _hasEvents(_selectedDate);

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: hasSelectedDateEvents ? 6 : 1,
            child: _buildCalendarCard(),
          ),
          if (hasSelectedDateEvents) ...[
            const SizedBox(width: 16),
            Expanded(flex: 4, child: _buildEventCard()),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCalendarCard(),
        if (hasSelectedDateEvents) ...[
          const SizedBox(height: 16),
          _buildEventCard(),
        ],
      ],
    );
  }

  Widget _buildCalendarCard() {
    const navy = Color(0xFF1F2A5A);
    const teal = Color(0xFF1B9A85);
    final colors = Theme.of(context).colorScheme;
    final selectedColor = Theme.of(context).brightness == Brightness.dark
        ? teal
        : navy;

    final startOfWeek = _getStartOfWeek(_selectedDate);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final weekRangeText = _viewMode == 'Weekly'
        ? AppDateHelper.formatWeekRange(startOfWeek, endOfWeek)
        : _viewMode == 'Monthly'
        ? '${AppDateHelper.fullMonths[_selectedDate.month - 1]} ${_selectedDate.year}'
        : '${_selectedDate.year}';

    return Container(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width < 400 ? 12 : 20,
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
          // Header: Date range (e.g. "8 Nov – 14 Nov 2026")
          Text(
            weekRangeText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
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
                    _buildViewButton('Weekly', teal, colors.onSurface),
                    _buildViewButton('Monthly', teal, colors.onSurface),
                    _buildViewButton('Yearly', teal, colors.onSurface),
                  ],
                ),
              ),

              // Controls: < Today >
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavIconButton(
                    Icons.chevron_left,
                    _onPrev,
                    colors.onSurface,
                    colors.outlineVariant,
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: _onToday,
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
                      'Today',
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
                    _onNext,
                    colors.onSurface,
                    colors.outlineVariant,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Days Row
          if (_viewMode == 'Weekly')
            _buildWeeklyDaysRow(
              startOfWeek,
              selectedColor,
              colors.onSurface,
              colors.onSurfaceVariant,
              colors.surface,
              colors.outlineVariant,
            )
          else if (_viewMode == 'Monthly')
            _buildMonthlyView(
              selectedColor,
              colors.onSurface,
              colors.onSurfaceVariant,
              colors.outlineVariant,
            )
          else
            _buildYearlyView(
              selectedColor,
              colors.onSurface,
              colors.surfaceContainerHighest,
            ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String label, Color teal, Color textColor) {
    final isSelected = _viewMode == label;
    return InkWell(
      onTap: () => setState(() => _viewMode = label),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? teal : Colors.transparent,
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

  Widget _buildWeeklyDaysRow(
    DateTime startOfWeek,
    Color selectedColor,
    Color textColor,
    Color mutedColor,
    Color surfaceColor,
    Color outlineColor,
  ) {
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Row(
      children: [
        for (int i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _buildDayColumn(
              days[i],
              selectedColor,
              textColor,
              mutedColor,
              surfaceColor,
              outlineColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDayColumn(
    DateTime day,
    Color selectedColor,
    Color textColor,
    Color mutedColor,
    Color surfaceColor,
    Color outlineColor,
  ) {
    final isSelected = DateUtils.isSameDay(day, _selectedDate);
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    final hasEvents = _hasEvents(day);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 16,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppDateHelper.formatShortDay(day),
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
            onTap: () {
              setState(() {
                _selectedDate = day;
              });
              if (_hasEvents(day)) {
                _showEventsForDate(day);
              }
            },
            borderRadius: BorderRadius.circular(9),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : surfaceColor,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isSelected ? selectedColor : outlineColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isToday ? const Color(0xFF1B9A85) : textColor),
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (hasEvents)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1B9A85),
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
      ],
    );
  }

  Widget _buildMonthlyView(
    Color selectedColor,
    Color textColor,
    Color mutedColor,
    Color outlineColor,
  ) {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final daysInMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    ).day;
    final startWeekday = firstDay.weekday % 7;

    return Column(
      children: [
        Row(
          children: AppDateHelper.shortWeekdays.map((dayName) {
            return Expanded(
              child: Center(
                child: Text(
                  dayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                    fontSize: 10,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
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
            final day = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              dayNumber,
            );
            final isSelected = DateUtils.isSameDay(day, _selectedDate);
            final isToday = DateUtils.isSameDay(day, DateTime.now());
            final hasEvents = _hasEvents(day);

            return InkWell(
              onTap: () {
                setState(() => _selectedDate = day);
                if (_hasEvents(day)) {
                  _showEventsForDate(day);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? selectedColor : outlineColor,
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
                            : (isToday ? const Color(0xFF1B9A85) : textColor),
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (hasEvents)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1B9A85),
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

  bool _monthHasEvents(int month) {
    return MockDb.eventsForGroup(widget.group.id).any(
      (event) =>
          event.date.year == _selectedDate.year && event.date.month == month,
    );
  }

  Widget _buildYearlyView(
    Color selectedColor,
    Color textColor,
    Color surfaceColor,
  ) {
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
        final isSelectedMonth = _selectedDate.month == month;
        final hasEvents = _monthHasEvents(month);

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = DateTime(_selectedDate.year, month, 1);
              _viewMode = 'Monthly';
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelectedMonth ? selectedColor : surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelectedMonth
                    ? selectedColor
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppDateHelper.fullMonths[index],
                  style: TextStyle(
                    color: isSelectedMonth ? Colors.white : textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (hasEvents) ...[
                  const SizedBox(height: 5),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelectedMonth
                          ? Colors.white
                          : const Color(0xFF1B9A85),
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

  Widget _buildEventCard() {
    const teal = Color(0xFF1B9A85);
    final colors = Theme.of(context).colorScheme;
    final events = _eventsForDate(_selectedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 150),
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
          Text(
            'Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            AppDateHelper.formatFullDate(_selectedDate),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: teal,
            ),
          ),
          const SizedBox(height: 14),
          if (events.isEmpty)
            Text(
              'No events scheduled for this date.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            )
          else
            ...events.map(
              (event) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: teal, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${event.startTime} - ${event.endTime}',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            event.description,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
