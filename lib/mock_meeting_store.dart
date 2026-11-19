import 'package:flutter/foundation.dart';

import 'admin/models/app_models.dart';
import 'mock_data.dart';

class MockMeetingNotification {
  final MeetingModel meeting;
  final Set<int> recipientGroupIds;
  final DateTime deliveredAt;

  const MockMeetingNotification({
    required this.meeting,
    required this.recipientGroupIds,
    required this.deliveredAt,
  });

  bool isForGroup(int groupId) => recipientGroupIds.contains(groupId);
}

class MockMeetingStore extends ChangeNotifier {
  MockMeetingStore._();

  static final MockMeetingStore instance = MockMeetingStore._();

  // Bridges the separate Admin and Member demo fixtures until server IDs exist.
  static const Map<String, int> _adminGroupToMemberGroup = {
    'grp_01': 1,
    'grp_02': 2,
    'grp_03': 3,
  };

  final List<MockMeetingNotification> _notifications = [];

  static Set<int> memberGroupIdsForAdminGroup(String? adminGroupId) {
    if (adminGroupId == null) {
      return MockDb.groups.map((group) => group.id).toSet();
    }

    final memberGroupId = _adminGroupToMemberGroup[adminGroupId];
    return memberGroupId == null ? const {} : {memberGroupId};
  }

  List<MeetingModel> meetingsForMemberGroup(int groupId) => [
    for (final notification in _notifications)
      if (notification.isForGroup(groupId)) notification.meeting,
  ];

  List<MockMeetingNotification> notificationsForMemberGroup(int groupId) => [
    for (final notification in _notifications)
      if (notification.isForGroup(groupId)) notification,
  ];

  void publishMeeting(
    MeetingModel meeting, {
    required Set<int> recipientGroupIds,
  }) {
    final notification = MockMeetingNotification(
      meeting: meeting,
      recipientGroupIds: Set.unmodifiable(recipientGroupIds),
      deliveredAt: DateTime.now(),
    );
    _notifications.removeWhere((existing) => existing.meeting.id == meeting.id);
    _notifications.insert(0, notification);
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    _notifications.clear();
    notifyListeners();
  }
}
