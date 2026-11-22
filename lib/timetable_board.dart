import 'package:flutter/material.dart';

import 'mock_data.dart';
import 'app_settings.dart';

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

  static String formatShortDay(DateTime d) =>
      AppSettings.instance.tr(shortWeekdays[d.weekday % 7]);

  static String formatWeekRange(DateTime start, DateTime end) {
    final tr = AppSettings.instance.tr;
    return '${start.day} ${tr(months[start.month - 1])} – ${end.day} ${tr(months[end.month - 1])} ${end.year}';
  }

  static String formatFullDate(DateTime d) {
    final tr = AppSettings.instance.tr;
    return '${formatShortDay(d)}, ${d.day} ${tr(months[d.month - 1])} ${d.year}';
  }

  static String formatClock(DateTime d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${d.day} ${AppSettings.instance.tr(months[d.month - 1])} ${d.year} | ${twoDigits(d.hour)}:${twoDigits(d.minute)}:${twoDigits(d.second)}';
  }
}

class TimetableBoard extends StatefulWidget {
  final Group group;
  final Member member;
  final bool? isDark;

  const TimetableBoard({
    super.key,
    required this.group,
    required this.member,
    this.isDark,
  });

  @override
  State<TimetableBoard> createState() => _TimetableBoardState();
}

class _TimetableBoardState extends State<TimetableBoard> {
  String _tr(String value) => AppSettings.instance.tr(value);
  late DateTime _selectedDate;
  String _viewMode = 'Weekly'; // 'Weekly', 'Monthly', 'Yearly'

  bool get _isDark =>
      widget.isDark ??
      (Theme.of(context).brightness == Brightness.dark ||
          AppSettings.instance.themeMode == ThemeMode.dark);

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

  Widget _buildDateNumber(
    int dayNumber, {
    required bool isSelected,
    required bool isToday,
    required Color textColor,
    required double fontSize,
  }) {
    return AnimatedScale(
      scale: isSelected ? 1.08 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (isToday ? const Color(0xFF1B9A85) : textColor),
          fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
          fontSize: fontSize,
        ),
        child: Text('$dayNumber'),
      ),
    );
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
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1B9A85).withValues(alpha: 0.2)
                          : const Color(0xFFE3F4F0),
                  child: const Icon(Icons.event, color: Color(0xFF1B9A85)),
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

    // Provide a Material ancestor for all InkWell widgets in this board.
    return Material(
      color: Colors.transparent,
      child: isWide
          ? Row(
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
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCalendarCard(),
                if (hasSelectedDateEvents) ...[
                  const SizedBox(height: 16),
                  _buildEventCard(),
                ],
              ],
            ),
    );
  }

  Widget _buildCalendarCard() {
    final dark = _isDark;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.99, end: 1).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: _buildCalendarCardContent(
        key: ValueKey('${AppSettings.instance.language}_$dark'),
      ),
    );
  }

  Widget _buildCalendarCardContent({required Key key}) {
    const navy = Color(0xFF1F2A5A);
    const teal = Color(0xFF1B9A85);
    final isDark = _isDark;

    // Palette explicitly tuned for dark/light theme to match home page background
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final dayBoxBg = isDark ? const Color(0xFF111827) : Colors.white;
    final dayBoxBorder =
        isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);
    final selectedColor = isDark ? teal : navy;

    final startOfWeek = _getStartOfWeek(_selectedDate);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final weekRangeText = _viewMode == 'Weekly'
        ? AppDateHelper.formatWeekRange(startOfWeek, endOfWeek)
        : _viewMode == 'Monthly'
        ? '${_tr(AppDateHelper.fullMonths[_selectedDate.month - 1])} ${_selectedDate.year}'
        : '${_selectedDate.year}';

    return Container(
      key: key,
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width < 400 ? 12 : 20,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date range (e.g. "22 Nov – 28 Nov 2026")
          Text(
            weekRangeText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // View switches + Nav buttons
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;

              final viewButtons = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildViewButton(
                    _tr('Weekly'),
                    teal,
                    textPrimary,
                    cardBorder,
                    isDark ? const Color(0xFF111827) : Colors.transparent,
                  ),
                  _buildViewButton(
                    _tr('Monthly'),
                    teal,
                    textPrimary,
                    cardBorder,
                    isDark ? const Color(0xFF111827) : Colors.transparent,
                  ),
                  _buildViewButton(
                    _tr('Yearly'),
                    teal,
                    textPrimary,
                    cardBorder,
                    isDark ? const Color(0xFF111827) : Colors.transparent,
                  ),
                ],
              );

              final navControls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavIconButton(
                    Icons.chevron_left,
                    _onPrev,
                    textPrimary,
                    cardBorder,
                    isDark ? const Color(0xFF111827) : Colors.transparent,
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
                      backgroundColor:
                          isDark ? const Color(0xFF111827) : Colors.transparent,
                      side: BorderSide(color: cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _tr('Today'),
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildNavIconButton(
                    Icons.chevron_right,
                    _onNext,
                    textPrimary,
                    cardBorder,
                    isDark ? const Color(0xFF111827) : Colors.transparent,
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    viewButtons,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.center, child: navControls),
                  ],
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [...viewButtons.children, navControls],
              );
            },
          ),
          const SizedBox(height: 20),

          // Days Row
          if (_viewMode == 'Weekly')
            _buildWeeklyDaysRow(
              startOfWeek,
              selectedColor,
              textPrimary,
              textSecondary,
              dayBoxBg,
              dayBoxBorder,
            )
          else if (_viewMode == 'Monthly')
            _buildMonthlyView(
              selectedColor,
              textPrimary,
              textSecondary,
              dayBoxBorder,
              dayBoxBg,
            )
          else
            _buildYearlyView(
              selectedColor,
              textPrimary,
              dayBoxBg,
              dayBoxBorder,
            ),
        ],
      ),
    );
  }

  Widget _buildViewButton(
    String label,
    Color teal,
    Color textColor,
    Color borderColor, [
    Color? unselectedBg,
  ]) {
    final englishLabel = label == _tr('Weekly')
        ? 'Weekly'
        : label == _tr('Monthly')
        ? 'Monthly'
        : 'Yearly';
    final isSelected = _viewMode == englishLabel;
    return InkWell(
      onTap: () => setState(() => _viewMode = englishLabel),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? teal : (unselectedBg ?? Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? teal : borderColor, width: 1),
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
    Color borderColor, [
    Color? bgColor,
  ]) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.transparent,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
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
            },
            borderRadius: BorderRadius.circular(9),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
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
                  _buildDateNumber(
                    day.day,
                    isSelected: isSelected,
                    isToday: isToday,
                    textColor: textColor,
                    fontSize: 13,
                  ),
                  const SizedBox(height: 3),
                  if (hasEvents)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOutCubic,
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
    Color dayBgColor,
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
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : dayBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? selectedColor : outlineColor,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDateNumber(
                      dayNumber,
                      isSelected: isSelected,
                      isToday: isToday,
                      textColor: textColor,
                      fontSize: 12,
                    ),
                    const SizedBox(height: 3),
                    if (hasEvents)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOutCubic,
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
    Color outlineColor,
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
                color: isSelectedMonth ? selectedColor : outlineColor,
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
    final isDark = _isDark;
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);
    final itemBg =
        isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final events = _eventsForDate(_selectedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 150),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('Events'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
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
              _tr('No events scheduled for this date.'),
              style: TextStyle(color: textSecondary, fontSize: 13),
            )
          else
            ...events.map(
              (event) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: itemBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
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
                              color: textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${event.startTime} - ${event.endTime}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            event.description,
                            style: TextStyle(
                              color: textSecondary,
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
