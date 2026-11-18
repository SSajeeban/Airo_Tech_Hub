import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invetory_system/admin/core/providers/app_providers.dart';
import 'package:invetory_system/admin/core/services/storage_service.dart';
import 'package:invetory_system/admin/features/meetings/screens/meetings_screen.dart';
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
