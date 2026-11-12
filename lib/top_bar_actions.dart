import 'dart:async';

import 'package:flutter/material.dart';
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

List<Widget> topBarActions() {
  final s = AppSettings.instance;
  return [
    const LiveClock(),
    IconButton(
      tooltip: s.isTamil ? 'Switch to English' : 'தமிழுக்கு மாறவும்',
      icon: const Icon(Icons.translate, size: 20),
      onPressed: s.toggleLanguage,
    ),
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
