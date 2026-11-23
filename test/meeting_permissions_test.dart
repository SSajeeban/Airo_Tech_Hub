import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:invetory_system/admin/core/network/api_client.dart';
import 'package:invetory_system/admin/core/providers/app_providers.dart';
import 'package:invetory_system/admin/core/constants/app_colors.dart';
import 'package:invetory_system/admin/core/services/storage_service.dart';
import 'package:invetory_system/admin/core/theme/app_theme.dart';
import 'package:invetory_system/admin/features/dashboard/screens/dashboard_screen.dart';
import 'package:invetory_system/admin/features/ai_teacher/screens/ai_teacher_screen.dart';
import 'package:invetory_system/admin/features/meetings/screens/meetings_screen.dart';
import 'package:invetory_system/admin/features/shell/main_shell.dart';
import 'package:invetory_system/admin/models/app_models.dart';
import 'package:invetory_system/admin/models/user_session.dart';
import 'package:invetory_system/home_shell.dart';
import 'package:invetory_system/meetings_tab.dart';
import 'package:invetory_system/mock_data.dart';
import 'package:invetory_system/mock_meeting_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MockMeetingStore.instance.clear();
  });

  test('unrecognized roles do not default to admin access', () {
    expect(UserRole.fromString('other'), UserRole.unknown);
    expect(
      UserProfile.fromJson({
        'id': 'unknown-user',
        'email': 'unknown@example.com',
      }).role,
      UserRole.unknown,
    );
  });

  testWidgets('member meeting page is read-only and shows group meetings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: MeetingsTab(memberName: 'Sathees', groupId: 1)),
    );

    expect(find.text('No meetings yet.'), findsOneWidget);
    expect(find.text('New Meeting'), findsNothing);
    expect(find.text('Load Sample'), findsNothing);
    expect(find.text('Clear'), findsNothing);

    final meeting = _meeting(groupName: 'Advanced Mathematics Cohort 2026');
    MockMeetingStore.instance.publishMeeting(meeting, recipientGroupIds: {1});
    await tester.pump();

    expect(find.text(meeting.title), findsOneWidget);
    expect(find.text(meeting.groupName), findsOneWidget);
    expect(find.text('No meetings yet.'), findsNothing);
    expect(find.text('New Meeting'), findsNothing);
  });

  testWidgets('only subscribers get the admin meeting form', (tester) async {
    final memberStorage = await _storageForRole(UserRole.groupMember);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(memberStorage)],
        child: const MaterialApp(home: MeetingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Only admins can access meetings.'), findsOneWidget);
    expect(find.text('Create instant meeting'), findsNothing);
    expect(find.text('Schedule meeting'), findsNothing);

    final adminStorage = await _storageForRole(UserRole.subscriber);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(adminStorage)],
        child: const MaterialApp(home: MeetingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create instant meeting'), findsOneWidget);
  });

  testWidgets('dashboard calendar follows dark theme and uses 16px title', (
    tester,
  ) async {
    final storage = await _storageForRole(UserRole.subscriber);
    await storage.setThemeMode('dark');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final calendar = tester.widget<Container>(
      find.byKey(const ValueKey('dashboard-calendar-card')),
    );
    expect(
      (calendar.decoration! as BoxDecoration).color,
      const Color(0xFF18233A),
    );
    final selectedCell = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('${DateTime.now().day}'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      (selectedCell.decoration! as BoxDecoration).color,
      const Color(0xFF1B9A85),
    );
    final unselectedCell = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('${DateTime.now().add(const Duration(days: 1)).day}'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      (unselectedCell.decoration! as BoxDecoration).color,
      const Color(0xFF18233A),
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

  testWidgets('AI Teacher and its notifications follow dark mode', (
    tester,
  ) async {
    final storage = await _storageForRole(UserRole.subscriber);
    await storage.setThemeMode('light');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: ref.watch(themeModeProvider),
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  IconButton(
                    key: const ValueKey('toggle-theme'),
                    onPressed: () =>
                        ref.read(themeModeProvider.notifier).toggleTheme(),
                    icon: const Icon(Icons.dark_mode_outlined),
                  ),
                ],
              ),
              body: const AiTeacherScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('toggle-theme')));
    await tester.pumpAndSettle();

    final titleFinder = find.text('AI Teacher');
    expect(Theme.of(tester.element(titleFinder)).brightness, Brightness.dark);
    await tester.tap(find.text('Ask AI Teacher'));
    await tester.pumpAndSettle();

    final snackBarContext = tester.element(find.byType(SnackBar));
    expect(
      Theme.of(snackBarContext).snackBarTheme.backgroundColor,
      AppColors.cardDark,
    );
    expect(
      Theme.of(snackBarContext).snackBarTheme.contentTextStyle?.color,
      AppColors.inkDark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin AI button opens the generator and returns its answer', (
    tester,
  ) async {
    final storage = await _storageForRole(UserRole.subscriber);
    final router = GoRouter(
      initialLocation: '/app',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/app',
              builder: (context, state) =>
                  const Scaffold(body: Text('Dashboard')),
            ),
            GoRoute(
              path: '/app/ai-teacher',
              builder: (context, state) => const AiTeacherScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          apiClientProvider.overrideWithValue(_FakeAiApiClient(storage)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('AI Teacher'));
    await tester.pumpAndSettle();
    expect(find.text('AI Teacher'), findsOneWidget);
    expect(find.byTooltip('AI Teacher'), findsNothing);

    await tester.enterText(
      find.byType(TextField).first,
      'Explain photosynthesis.',
    );
    await tester.tap(find.text('Ask AI Teacher'));
    await tester.pumpAndSettle();

    expect(
      find.text('Generated answer: Explain photosynthesis.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin meeting is visible to members and in notifications', (
    tester,
  ) async {
    final adminStorage = await _storageForRole(UserRole.subscriber);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(adminStorage)],
        child: const MaterialApp(home: MeetingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'Admin scheduled session',
    );
    await tester.tap(find.text('Create instant meeting'));
    await tester.pumpAndSettle();

    final member = MockDb.members.first;
    final group = MockDb.groups.first;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(member: member, group: group),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Admin scheduled session'), findsOneWidget);
    expect(find.textContaining('https://meet.jit.si/'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meetings').last);
    await tester.pumpAndSettle();
    expect(find.text('Admin scheduled session'), findsOneWidget);
  });

  test('scheduled group recipients are isolated to mapped members', () {
    final meeting = _meeting(groupName: 'A/L Combined Mathematics Batch');
    final recipients = MockMeetingStore.memberGroupIdsForAdminGroup('grp_02');
    MockMeetingStore.instance.publishMeeting(
      meeting,
      recipientGroupIds: recipients,
    );

    expect(MockMeetingStore.instance.meetingsForMemberGroup(2), [meeting]);
    expect(
      MockMeetingStore.instance.notificationsForMemberGroup(2),
      hasLength(1),
    );
    expect(MockMeetingStore.instance.meetingsForMemberGroup(1), isEmpty);
    expect(MockMeetingStore.instance.notificationsForMemberGroup(1), isEmpty);
  });
}

MeetingModel _meeting({required String groupName}) => MeetingModel(
  id: 'meeting-test',
  title: 'Mock class meeting',
  groupName: groupName,
  scheduledTime: DateTime(2026, 11, 18, 14),
  durationMinutes: 60,
  meetingUrl: 'https://meet.jit.si/meeting-test',
  isLive: false,
);

Future<StorageService> _storageForRole(UserRole role) async {
  final storage = await StorageService.init();
  await storage.saveSession(
    UserSession(
      token: 'mock-token',
      user: UserProfile(
        id: 'mock-user',
        email: 'mock@example.com',
        displayName: role.toDisplayString(),
        role: role,
      ),
    ),
  );
  return storage;
}

class _FakeAiApiClient extends ApiClient {
  _FakeAiApiClient(super.storage);

  @override
  Future<String> askAiTeacher({
    required String prompt,
    required String taskType,
    required String language,
  }) async {
    return 'Generated answer: $prompt';
  }
}
