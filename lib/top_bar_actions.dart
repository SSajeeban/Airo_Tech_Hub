import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import 'app_settings.dart';

class LiveClock extends StatefulWidget {
  const LiveClock({super.key});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          DateFormat('hh:mm:ss a').format(_now),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        Text(
          DateFormat('dd MMM yyyy').format(_now),
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}

class _LanguageSwitch extends StatefulWidget {
  const _LanguageSwitch();

  @override
  State<_LanguageSwitch> createState() => _LanguageSwitchState();
}

class _LanguageSwitchState extends State<_LanguageSwitch> {
  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    final isDark = s.themeMode == ThemeMode.dark;
    const accent = Color(0xFF1B9A85);
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('EN', !s.isTamil, accent, () {
            if (s.isTamil) s.toggleLanguage();
            setState(() {});
          }),
          const SizedBox(width: 2),
          _segment('த', s.isTamil, accent, () {
            if (!s.isTamil) s.toggleLanguage();
            setState(() {});
          }),
        ],
      ),
    );
  }

  Widget _segment(
    String label,
    bool selected,
    Color accent,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 28,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

List<Widget> topBarActions() {
  final s = AppSettings.instance;
  return [
    const LiveClock(),
    const _LanguageSwitch(),
    IconButton(
      tooltip: 'Theme',
      icon: Icon(
        s.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
        size: 20,
      ),
      onPressed: s.toggleTheme,
    ),
  ];
}
