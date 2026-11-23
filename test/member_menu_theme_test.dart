import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invetory_system/admin/core/constants/app_colors.dart';
import 'package:invetory_system/admin/core/constants/app_icons.dart';
import 'package:invetory_system/home_shell.dart';
import 'package:invetory_system/mock_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('member drawer follows the admin menu palette', (tester) async {
    tester.view.physicalSize = const Size(440, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          member: MockDb.members.first,
          group: MockDb.groups.first,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    final header = tester.widget<UserAccountsDrawerHeader>(
      find.byType(UserAccountsDrawerHeader),
    );
    final decoration = header.decoration as BoxDecoration;
    expect(decoration.gradient, isA<LinearGradient>());
    expect((decoration.gradient! as LinearGradient).colors, [
      AppColors.headingLight,
      AppColors.accentHover,
    ]);

    final chatTile = find.widgetWithText(ListTile, 'Chat');
    final chatIcon = tester.widget<Icon>(
      find.descendant(of: chatTile, matching: find.byIcon(AppIcons.chat)),
    );
    expect(chatIcon.color, AppColors.brandBlue);

    final homeTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Home'),
    );
    expect(homeTile.selected, isTrue);
    expect(homeTile.selectedTileColor, AppColors.surfaceLight);
  });

  testWidgets('member controls use readable dark-mode colors', (tester) async {
    tester.view.physicalSize = const Size(440, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          member: MockDb.members.first,
          group: MockDb.groups.first,
        ),
      ),
    );
    await tester.tap(find.text('Chat').last);
    await tester.pumpAndSettle();

    final statusFinder = find.text('Online');
    var status = tester.widget<Text>(statusFinder);
    var colors = Theme.of(tester.element(statusFinder)).colorScheme;
    expect(colors.brightness, Brightness.light);
    expect(status.style?.color, Colors.black);

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pump();
    status = tester.widget<Text>(statusFinder);
    colors = Theme.of(tester.element(statusFinder)).colorScheme;
    expect(colors.brightness, Brightness.dark);
    expect(status.style?.color, colors.onSurface);

    final languageSwitch = tester.widget<Container>(
      find.byKey(const ValueKey('member-language-switch')),
    );
    expect(
      (languageSwitch.decoration! as BoxDecoration).color,
      const Color(0xFF374151),
    );
    expect(tester.widget<Text>(find.text('EN')).style?.color, Colors.white);
  });

  testWidgets('member timetable card and dates switch to dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          member: MockDb.members.first,
          group: MockDb.groups.first,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();

    final calendar = tester.widget<Container>(
      find.byKey(const ValueKey('English')),
    );
    expect(
      (calendar.decoration! as BoxDecoration).color,
      const Color(0xFF1F2937),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.style?.fontSize == 16 &&
            widget.data?.contains('–') == true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('calendar is on Home, not on the Notices board', (tester) async {
    tester.view.physicalSize = const Size(440, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          member: MockDb.members.first,
          group: MockDb.groups.first,
        ),
      ),
    );
    expect(find.text('Weekly'), findsOneWidget);

    await tester.tap(find.text('Notices').last);
    await tester.pumpAndSettle();
    expect(find.text('Notice board'), findsOneWidget);
    expect(find.text('Weekly'), findsNothing);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Weekly'), findsOneWidget);
  });

  testWidgets('member notification dialog follows dark mode', (tester) async {
    tester.view.physicalSize = const Size(1200, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          member: MockDb.members.first,
          group: MockDb.groups.first,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    final dialogContext = tester.element(find.byType(AlertDialog));
    expect(Theme.of(dialogContext).brightness, Brightness.dark);
    expect(
      Theme.of(dialogContext).colorScheme.surface,
      const Color(0xFF1F2937),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI Teacher button opens the AI Teacher screen', (tester) async {
    tester.view.physicalSize = const Size(440, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          member: MockDb.members.first,
          group: MockDb.groups.first,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('AI Teacher'));
    await tester.pumpAndSettle();

    final titleFinder = find.text('AI Teacher');
    expect(
      find.text(
        'Ask a question, or create an exam paper or notes. Generated text can be saved to your Library.',
      ),
      findsOneWidget,
    );
    expect(Theme.of(tester.element(titleFinder)).brightness, Brightness.dark);

    await tester.tap(find.text('Ask AI Teacher'));
    await tester.pumpAndSettle();
    final snackBarContext = tester.element(find.byType(SnackBar));
    expect(
      Theme.of(snackBarContext).snackBarTheme.backgroundColor,
      const Color(0xFF1F2937),
    );
    expect(
      Theme.of(snackBarContext).snackBarTheme.contentTextStyle?.color,
      Theme.of(snackBarContext).colorScheme.onSurface,
    );
    expect(tester.takeException(), isNull);
  });
}
