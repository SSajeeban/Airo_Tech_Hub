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
  ];

  static const List<Member> members = [
    Member(id: 1, name: 'Sathees', phone: '0771234567', groupId: 1),
    Member(id: 2, name: 'Anu', phone: '0712345678', groupId: 1),
    Member(id: 3, name: 'Ravi', phone: '0761234567', groupId: 2),
  ];

  static const List<Notice> notices = [
    Notice(id: 1, groupId: 1, title: 'Exam on Friday', body: 'Chapter 1 to 3.'),
    Notice(id: 2, groupId: 2, title: 'New class time', body: 'Starts at 6 PM.'),
  ];

  static const String testOtp = '123456';

    static const List<Membership> memberships = [
    Membership(memberId: 1, groupId: 1),
    Membership(memberId: 1, groupId: 2),
    Membership(memberId: 2, groupId: 1),
    Membership(memberId: 3, groupId: 2),
  ];

  static List<Group> groupsForMember(Member member) {
    final ids = memberships
        .where((m) => m.memberId == member.id)
        .map((m) => m.groupId)
        .toList();
    return groups.where((g) => ids.contains(g.id)).toList();
  }

  static Group? findGroupByCode(String code) {
    for (final group in groups) {
      if (group.code == code) {
        return group;
      }
    }
    return null;
  }

  static Member? findMemberByPhone(String phone) {
    final cleaned = phone.replaceAll(' ', '');
    for (final member in members) {
      if (member.phone == cleaned) {
        return member;
      }
    }
    return null;
  }
}
