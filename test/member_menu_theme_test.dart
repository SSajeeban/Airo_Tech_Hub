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

  testWidgets('member presence label uses readable dark-mode text', (
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
  });
}
