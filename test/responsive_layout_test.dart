import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invetory_system/admin/core/providers/app_providers.dart';
import 'package:invetory_system/admin/core/services/storage_service.dart';
import 'package:invetory_system/admin/features/shell/main_shell.dart';
import 'package:invetory_system/attendance_screen.dart';
import 'package:invetory_system/home_shell.dart';
import 'package:invetory_system/mock_data.dart';
import 'package:invetory_system/phone_sign_in_screen.dart';
import 'package:invetory_system/portal_screen.dart';
import 'package:invetory_system/timetable_board.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _viewports = [
  Size(320, 568),
  Size(360, 800),
  Size(393, 851),
  Size(430, 932),
  Size(768, 1024),
  Size(568, 320),
];

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

void main() {
  testWidgets('portal layout fits common phone, tablet, and landscape sizes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in _viewports) {
      _setViewport(tester, size);
      await tester.pumpWidget(
        const MaterialApp(home: PortalScreen(memberPage: Placeholder())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Viewport: $size');
    }
  });

  testWidgets(
    'phone sign-in layout fits common phone, tablet, and landscape sizes',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final size in _viewports) {
        _setViewport(tester, size);
        await tester.pumpWidget(const MaterialApp(home: PhoneSignInScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Viewport: $size');
      }
    },
  );

  testWidgets(
    'attendance layout fits common phone, tablet, and landscape sizes',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final size in _viewports) {
        _setViewport(tester, size);
        await tester.pumpWidget(
          const MaterialApp(
            home: AttendanceScreen(groupName: 'Responsive test group'),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Viewport: $size');
      }
    },
  );

  testWidgets(
    'timetable layout fits common phone, tablet, and landscape sizes',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final size in _viewports) {
        _setViewport(tester, size);
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
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Viewport: $size');
      }
    },
  );

  testWidgets('admin navigation and toolbar fit common viewport sizes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = StorageService(preferences);
    final router = GoRouter(
      initialLocation: '/app',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/app',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Admin content'))),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in _viewports) {
      _setViewport(tester, size);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Viewport: $size');
    }

    _setViewport(tester, const Size(320, 568));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-compact-settings')));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(find.text('සිංහල'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('member navigation and toolbar fit common viewport sizes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in _viewports) {
      _setViewport(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeShell(
            member: MockDb.members.first,
            group: MockDb.groups.first,
          ),
        ),
      );
      await tester.pump();

      final exception = tester.takeException();
      expect(exception, isNull, reason: 'Viewport: $size');
    }

    _setViewport(tester, const Size(320, 568));
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          member: MockDb.members.first,
          group: MockDb.groups.first,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('member-compact-settings')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Tamil'), findsOneWidget);
    expect(find.text('Sinhala'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
