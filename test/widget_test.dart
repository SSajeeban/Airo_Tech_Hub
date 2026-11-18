import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:invetory_system/app_settings.dart';
import 'package:invetory_system/main.dart';
import 'package:invetory_system/mock_data.dart';
import 'package:invetory_system/timetable_board.dart';

void main() {
  test('Tamil home labels and sample notices are translated', () {
    final previousLanguage = AppSettings.instance.language;
    AppSettings.instance.setLanguage('Tamil');
    addTearDown(() => AppSettings.instance.setLanguage(previousLanguage));

    const translations = {
      'Your groups': 'உங்கள் குழுக்கள்',
      'Groups': 'குழுக்கள்',
      'Members': 'உறுப்பினர்கள்',
      'Storage': 'சேமிப்பு இடம்',
      'Meetings this month': 'இந்த மாதக் கூட்டங்கள்',
      'New class time': 'புதிய வகுப்பு நேரம்',
      'Starts at 6 PM.': 'மாலை 6 மணிக்கு தொடங்கும்.',
    };

    for (final entry in translations.entries) {
      expect(AppSettings.instance.tr(entry.key), entry.value);
    }
  });

  testWidgets('Airo Techhub app loads successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AiroApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Timetable transitions smoothly when language changes', (
    WidgetTester tester,
  ) async {
    final previousLanguage = AppSettings.instance.language;
    AppSettings.instance.setLanguage('English');
    addTearDown(() => AppSettings.instance.setLanguage(previousLanguage));

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () =>
                      setState(() => AppSettings.instance.setLanguage('Tamil')),
                  child: const Text('Tamil'),
                ),
                Expanded(
                  child: TimetableBoard(
                    group: MockDb.groups.first,
                    member: MockDb.members.first,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Weekly'), findsOneWidget);
    await tester.tap(find.text('Tamil'));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 225));
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('வாராந்திரம்'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 275));
    expect(find.text('Weekly'), findsNothing);
    expect(find.text('வாராந்திரம்'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Calendar date selection animates in weekly and monthly views', (
    WidgetTester tester,
  ) async {
    final previousLanguage = AppSettings.instance.language;
    AppSettings.instance.setLanguage('English');
    addTearDown(() => AppSettings.instance.setLanguage(previousLanguage));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TimetableBoard(
              group: MockDb.groups.first,
              member: MockDb.members.first,
            ),
          ),
        ),
      ),
    );

    final today = DateTime.now();
    final weeklyDate = today.weekday == DateTime.sunday
        ? today.add(const Duration(days: 1))
        : today.subtract(const Duration(days: 1));
    var dateNumber = find.text('${weeklyDate.day}');
    expect(
      find.ancestor(of: dateNumber, matching: find.byType(AnimatedContainer)),
      findsOneWidget,
    );
    await tester.tap(dateNumber);
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();

    final monthlyDate = weeklyDate.day == 1 ? 2 : 1;
    dateNumber = find.text('$monthlyDate');
    expect(
      find.ancestor(of: dateNumber, matching: find.byType(AnimatedContainer)),
      findsOneWidget,
    );
    await tester.tap(dateNumber);
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sinhala timetable controls fit on narrow screens', (
    WidgetTester tester,
  ) async {
    final previousLanguage = AppSettings.instance.language;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    AppSettings.instance.setLanguage('Sinhala');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TimetableBoard(
              group: MockDb.groups.first,
              member: MockDb.members.first,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    AppSettings.instance.setLanguage(previousLanguage);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
