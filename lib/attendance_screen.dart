import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import 'app_settings.dart';

class AttendanceScreen extends StatefulWidget {
  final String groupName;

  const AttendanceScreen({super.key, required this.groupName});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _tr(String value) => AppSettings.instance.tr(value);

  DateTime _selectedMonth = DateTime.now();

  // Temporary mock attendance records.
  final Map<int, bool> _sampleRecords = {
    1: true,
    2: true,
    3: true,
    4: true,
    5: false,
    6: true,
    8: true,
    9: true,
    10: true,
    11: true,
    12: false,
    13: true,
    15: true,
    16: true,
    17: true,
    18: true,
    19: false,
    20: true,
    22: true,
    23: true,
  };

  Map<int, bool> get _records {
    final now = DateTime.now();

    if (_selectedMonth.year != now.year || _selectedMonth.month != now.month) {
      return {};
    }

    return Map.fromEntries(
      _sampleRecords.entries.where((entry) => entry.key <= now.day),
    );
  }

  void _changeMonth(int amount) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + amount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final records = _records;
    final total = records.length;
    final present = records.values.where((v) => v).length;
    final absent = total - present;
    final percentage = total == 0 ? 0.0 : present / total;

    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    final firstWeekday =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7;

    return Scaffold(
      appBar: AppBar(title: Text(_tr('My Attendance'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.groupName, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_tr('Sample attendance data')),
          const SizedBox(height: 16),

          // Attendance summary
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_tr('Overall Attendance')),
                  const SizedBox(height: 8),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: percentage, minHeight: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _statCard(_tr('Total Classes'), total, Colors.blue),
              _statCard(_tr('Present'), present, Colors.green),
              _statCard(_tr('Absent'), absent, Colors.red),
            ],
          ),

          const SizedBox(height: 16),

          // Monthly calendar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          '${_tr(DateFormat('MMMM').format(_selectedMonth))} ${_selectedMonth.year}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final day in [
                        'Sun',
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                      ])
                        Center(
                          child: Text(
                            _tr(day),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      for (int i = 0; i < firstWeekday; i++) const SizedBox(),

                      for (int day = 1; day <= daysInMonth; day++)
                        _calendarDay(day, records[day]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _legend('Present', Colors.green),
                      _legend('Absent', Colors.red),
                      _legend('No record', Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(_tr('Attendance History'), style: theme.textTheme.titleLarge),

          const SizedBox(height: 12),

          if (records.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_tr('No attendance records')),
              ),
            ),

          for (final day
              in (records.keys.toList()..sort((a, b) => b.compareTo(a))))
            Card(
              child: ListTile(
                leading: Icon(
                  records[day]!
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: records[day]! ? Colors.green : Colors.red,
                ),
                title: Text(widget.groupName),
                subtitle: Text(
                  '$day ${_tr(DateFormat('MMM').format(_selectedMonth))} ${_selectedMonth.year}',
                ),
                trailing: Text(
                  _tr(records[day]! ? 'Present' : 'Absent'),
                  style: TextStyle(
                    color: records[day]! ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calendarDay(int day, bool? status) {
    final color = status == null
        ? Colors.grey
        : status
        ? Colors.green
        : Colors.red;

    return Center(
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
        ),
        child: Text(
          '$day',
          style: TextStyle(
            color: status == null
                ? Theme.of(context).colorScheme.onSurface
                : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(_tr(label)),
      ],
    );
  }
}
