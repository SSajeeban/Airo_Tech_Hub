class Group {
  final int id;
  final String name;
  final String teacher;
  final String code;

  const Group({
    required this.id,
    required this.name,
    required this.teacher,
    required this.code,
  });
}

class Member {
  final int id;
  final String name;
  final String phone;
  final int groupId;

  const Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.groupId,
  });
}

class Notice {
  final int id;
  final int groupId;
  final String title;
  final String body;

  const Notice({
    required this.id,
    required this.groupId,
    required this.title,
    required this.body,
  });
}

class CalendarEvent {
  final int id;
  final int groupId;
  final String title;
  final String description;
  final DateTime date;
  final String startTime;
  final String endTime;

  const CalendarEvent({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
  });
}

class Membership {
  final int memberId;
  final int groupId;

  const Membership({required this.memberId, required this.groupId});
}

class MockDb {
  static const List<Group> groups = [
    Group(
      id: 1,
      name: 'Grade 10 Maths',
      teacher: 'Mr. Kumar',
      code: '12345678',
    ),
    Group(
      id: 2,
      name: 'Spoken English',
      teacher: 'Ms. Priya',
      code: 'ENGL2026',
    ),
    Group(id: 3, name: 'Office', teacher: 'A.Nismina', code: 'OFFI2026'),
  ];

  static const List<Member> members = [
    Member(id: 1, name: 'Sathees', phone: '0771234567', groupId: 1),
    Member(id: 2, name: 'Anu', phone: '0712345678', groupId: 1),
    Member(id: 3, name: 'Ravi', phone: '0761234567', groupId: 2),
    Member(id: 4, name: 'A.Nismina', phone: '0770000000', groupId: 3),
  ];

  static const List<Notice> notices = [
    Notice(id: 1, groupId: 1, title: 'Exam on Friday', body: 'Chapter 1 to 3.'),
    Notice(id: 2, groupId: 2, title: 'New class time', body: 'Starts at 6 PM.'),
  ];

  // Sample calendar events. These are temporary local data for testing.
  static final List<CalendarEvent> events = [
    CalendarEvent(
      id: 1,
      groupId: 1,
      title: 'Mathematics Class',
      description: 'Exam preparation - Chapter 1 to 3.',
      date: DateTime(2026, 11, 17),
      startTime: '09:00 AM',
      endTime: '10:00 AM',
    ),
    CalendarEvent(
      id: 2,
      groupId: 2,
      title: 'English Meeting',
      description: 'Spoken English practice session.',
      date: DateTime(2026, 11, 17),
      startTime: '02:00 PM',
      endTime: '03:00 PM',
    ),
    CalendarEvent(
      id: 3,
      groupId: 1,
      title: 'Mathematics Test',
      description: 'Monthly mathematics test.',
      date: DateTime(2026, 11, 20),
      startTime: '10:00 AM',
      endTime: '11:00 AM',
    ),
    CalendarEvent(
      id: 4,
      groupId: 2,
      title: 'English Speaking Practice',
      description: 'Group speaking activity.',
      date: DateTime(2026, 11, 27),
      startTime: '03:00 PM',
      endTime: '04:00 PM',
    ),
  ];

  static const String testOtp = '123456';

  static const List<Membership> memberships = [
    Membership(memberId: 1, groupId: 1),
    Membership(memberId: 1, groupId: 2),
    Membership(memberId: 2, groupId: 1),
    Membership(memberId: 3, groupId: 2),
    Membership(memberId: 4, groupId: 3),
  ];

  static List<Group> groupsForMember(Member member) {
    final groupIds = memberships
        .where((membership) => membership.memberId == member.id)
        .map((membership) => membership.groupId)
        .toSet();

    return groups.where((group) => groupIds.contains(group.id)).toList();
  }

  static List<CalendarEvent> eventsForGroup(int groupId) {
    return events.where((event) => event.groupId == groupId).toList();
  }

  static Group? findGroupByCode(String code) {
    final cleanedCode = code.trim().toUpperCase();

    for (final group in groups) {
      if (group.code.toUpperCase() == cleanedCode) {
        return group;
      }
    }
    return null;
  }

  static Member? findMemberByPhone(String phone) {
    final cleanedPhone = phone.replaceAll(RegExp(r'\\s+'), '');

    for (final member in members) {
      if (member.phone == cleanedPhone) {
        return member;
      }
    }
    return null;
  }
}
