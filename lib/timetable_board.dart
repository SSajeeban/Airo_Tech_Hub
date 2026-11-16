import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: _buildCalendarCard()),
          const SizedBox(width: 16),
          Expanded(flex: 4, child: _buildEventCard()),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCalendarCard(),
        const SizedBox(height: 16),
        _buildEventCard(),
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
    final weekRangeText = AppDateHelper.formatWeekRange(startOfWeek, endOfWeek);

    return Container(
      padding: const EdgeInsets.all(20),
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
          if (i > 0) const SizedBox(width: 8),
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
    final isSelected =
        day.year == _selectedDate.year &&
        day.month == _selectedDate.month &&
        day.day == _selectedDate.day;

    final isToday =
        day.year == DateTime.now().year &&
        day.month == DateTime.now().month &&
        day.day == DateTime.now().day;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = day;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : outlineColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              AppDateHelper.formatShortDay(day),
              style: TextStyle(
                color: isSelected ? selectedColor : mutedColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isToday ? const Color(0xFF1B9A85) : textColor),
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: AppDateHelper.shortWeekdays
              .map(
                (d) => Text(
                  d,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                    fontSize: 12,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
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
            final isSelected =
                day.year == _selectedDate.year &&
                day.month == _selectedDate.month &&
                day.day == _selectedDate.day;

            return InkWell(
              onTap: () => setState(() => _selectedDate = day),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? selectedColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: outlineColor),
                ),
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
        childAspectRatio: 2.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final isSelectedMonth = _selectedDate.month == (index + 1);
        return InkWell(
          onTap: () => setState(
            () => _selectedDate = DateTime(_selectedDate.year, index + 1, 1),
          ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelectedMonth ? selectedColor : surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppDateHelper.fullMonths[index],
              style: TextStyle(
                color: isSelectedMonth ? Colors.white : textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventCard() {
    const teal = Color(0xFF1B9A85);
    final colors = Theme.of(context).colorScheme;

    final formattedSelected = AppDateHelper.formatFullDate(_selectedDate);

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(minHeight: 240),
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
            'Event',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ).copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            formattedSelected,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: teal,
            ),
          ),
          const SizedBox(height: 16),

          // Matching the reference image: "Select a meeting to see the details and join link."
          Text(
            'Select a meeting to see the details and join link.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Actionable sample session for interactive use
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.videocam_outlined, color: teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.group.name} Live Session',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ).copyWith(color: colors.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '10:30 AM – 11:30 AM',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Connecting to ${widget.group.name} meeting...',
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Join', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
