class GroupModel {
  final String id;
  final String name;
  final String code;
  final String description;
  final int memberCount;
  final String schedule;
  final DateTime createdAt;
  final Map<String, String> customFields;

  const GroupModel({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.memberCount,
    required this.schedule,
    required this.createdAt,
    this.customFields = const {},
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String? ?? '',
      name:
          json['name'] as String? ?? json['title'] as String? ?? 'Class Cohort',
      code: json['code'] as String? ?? 'AIR01',
      description: json['description'] as String? ?? '',
      memberCount:
          json['memberCount'] as int? ?? json['membersCount'] as int? ?? 0,
      schedule: json['schedule'] as String? ?? 'Mon & Wed 6:00 PM',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      customFields: (json['customFields'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }
}

class MemberModel {
  final String id;
  final String name;
  final String initial;
  final String email;
  final String phone;
  final String groupName;
  final String status;
  final String? photoUrl;
  final String? groupId;
  final List<String> groupIds;
  final String? fullName;
  final String? dateOfBirth;
  final String? address;
  final Map<String, String> customFields;
  final List<String> documents;
  final DateTime? joinedAt;

  const MemberModel({
    required this.id,
    required this.name,
    required this.initial,
    required this.email,
    required this.phone,
    required this.groupName,
    required this.status,
    this.photoUrl,
    this.groupId,
    this.groupIds = const [],
    this.fullName,
    this.dateOfBirth,
    this.address,
    this.customFields = const {},
    this.documents = const [],
    this.joinedAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Student',
      initial: json['initial'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      groupName:
          json['groupName'] as String? ?? json['group'] as String? ?? 'General',
      status: json['status'] as String? ?? 'Active',
      photoUrl: json['photoUrl'] as String?,
      groupId: json['groupId'] as String?,
      groupIds: (json['groupIds'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(),
      fullName: json['fullName'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      address: json['address'] as String?,
      customFields: (json['customFields'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      documents: (json['documents'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(),
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'] as String)
          : null,
    );
  }
}

class NoticeModel {
  final String id;
  final String title;
  final String titleTa;
  final String content;
  final String contentTa;
  final bool isPinned;
  final DateTime publishedAt;
  final String author;
  final String audience;
  final DateTime? expiresAt;

  const NoticeModel({
    required this.id,
    required this.title,
    required this.titleTa,
    required this.content,
    required this.contentTa,
    required this.isPinned,
    required this.publishedAt,
    required this.author,
    this.audience = 'All groups',
    this.expiresAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleTa: json['titleTa'] as String? ?? '',
      content: json['content'] as String? ?? '',
      contentTa: json['contentTa'] as String? ?? '',
      isPinned: json['isPinned'] as bool? ?? false,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      author: json['author'] as String? ?? 'Instructor',
      audience: json['audience'] as String? ?? 'All groups',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }
}

class MeetingModel {
  final String id;
  final String title;
  final String groupName;
  final DateTime scheduledTime;
  final int durationMinutes;
  final String meetingUrl;
  final bool isLive;

  const MeetingModel({
    required this.id,
    required this.title,
    required this.groupName,
    required this.scheduledTime,
    required this.durationMinutes,
    required this.meetingUrl,
    required this.isLive,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Online Session',
      groupName: json['groupName'] as String? ?? 'All Students',
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.tryParse(json['scheduledTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      meetingUrl:
          json['meetingUrl'] as String? ??
          'https://meet.jit.si/airo_${json['id'] ?? 'class'}',
      isLive: json['isLive'] as bool? ?? false,
    );
  }
}

class PaymentModel {
  final String id;
  final String? memberId;
  final String memberName;
  final String groupName;
  final double amount;
  final String currency;
  final String scheduleType; // Daily, Weekly, Monthly, Yearly
  final DateTime dueDate;
  final bool isPaid;
  final DateTime? paidAt;
  final String title;
  final String note;
  final DateTime? startsOn;
  final String? scheduleId;
  final String appliesTo;

  const PaymentModel({
    required this.id,
    this.memberId,
    required this.memberName,
    required this.groupName,
    required this.amount,
    required this.currency,
    required this.scheduleType,
    required this.dueDate,
    required this.isPaid,
    this.paidAt,
    this.title = '',
    this.note = '',
    this.startsOn,
    this.scheduleId,
    this.appliesTo = 'Group',
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String? ?? '',
      memberId: json['memberId'] as String?,
      memberName: json['memberName'] as String? ?? 'Student',
      groupName: json['groupName'] as String? ?? 'Batch A',
      amount: (json['amount'] as num?)?.toDouble() ?? 2500.0,
      currency: json['currency'] as String? ?? 'LKR',
      scheduleType: json['scheduleType'] as String? ?? 'Monthly',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'] as String)
          : null,
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      startsOn: json['startsOn'] != null
          ? DateTime.tryParse(json['startsOn'] as String)
          : null,
      scheduleId: json['scheduleId'] as String?,
      appliesTo: json['appliesTo'] as String? ?? 'Group',
    );
  }
}

class LibraryItem {
  final String id;
  final String title;
  final String folder;
  final String fileType;
  final String size;
  final DateTime uploadedAt;
  final String? url;

  const LibraryItem({
    required this.id,
    required this.title,
    required this.folder,
    required this.fileType,
    required this.size,
    required this.uploadedAt,
    this.url,
  });

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Document',
      folder: json['folder'] as String? ?? 'Course Material',
      fileType: json['fileType'] as String? ?? 'PDF',
      size: json['size'] as String? ?? '2.4 MB',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      url: json['url'] as String?,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final String? attachmentUrl;

  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.attachmentUrl,
  });
}
