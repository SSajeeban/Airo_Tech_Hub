import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invetory_system/app_settings.dart';
import 'package:invetory_system/application_screen.dart';
import 'package:invetory_system/mock_data.dart';

void main() {
  testWidgets('member application picker follows the portal layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AppSettings.instance.setLanguage('English');
    await tester.pumpWidget(
      MaterialApp(home: ApplicationScreen(member: MockDb.members.first)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Choose an application'), findsOneWidget);
    expect(find.text('Grade 10 Maths'), findsOneWidget);
    expect(find.text('Spoken English'), findsOneWidget);
    expect(find.text('Back to the site'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'CONTINUE'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Grade 10 Maths'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'CONTINUE'))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
}
