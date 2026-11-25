import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invetory_system/app_settings.dart';
import 'package:invetory_system/portal_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('portal landing page uses the white theme on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    AppSettings.instance.setLanguage('English');
    await tester.pumpWidget(
      const MaterialApp(home: PortalScreen(memberPage: Placeholder())),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.white,
    );
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to continue to your portal'), findsOneWidget);
    expect(find.text('Student or member'), findsOneWidget);
    expect(find.text('AI assistant'), findsOneWidget);
    final adminButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Admin'),
    );
    expect(
      adminButton.style?.backgroundColor?.resolve({}),
      const Color(0xFF1B9A85),
    );
    expect(find.text('app.airotechhub.lk'), findsNothing);
    expect(find.text('© ${DateTime.now().year} Airo Techhub'), findsOneWidget);
    final footerRect = tester.getRect(
      find.byKey(const ValueKey('portal-footer')),
    );
    expect(tester.view.physicalSize.height - footerRect.bottom, lessThan(30));
    expect(
      tester.widget<Text>(find.text('Student or member')).style?.color,
      const Color(0xFF1F2937),
    );
    expect(find.byType(Image), findsOneWidget);
    await tester.ensureVisible(find.text('AI assistant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI assistant'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
