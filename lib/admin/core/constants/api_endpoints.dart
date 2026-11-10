class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://airotechhub.lk';
  static const String memberPortalUrl = 'https://app.airotechhub.lk';

  // Public Endpoints
  static const String site = '/site';
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Subscriber & Workspace Endpoints
  static const String dashboard = '/dashboard';
  static const String groups = '/groups';
  static String groupMembers(String groupId) => '/groups/$groupId/members';
  static String groupJoinLink(String groupId) => '/groups/$groupId/join-link';
  static const String members = '/groups/members';
  static String memberPhoto(String memberId) => '/groups/members/$memberId/photo';
  static String memberPayments(String memberId) => '/groups/members/$memberId/payments';

  // Chat & Notices
  static const String chatConversations = '/chat/conversations';
  static String chatMessages(String conversationId) => '/chat/conversations/$conversationId/messages';
  static const String notices = '/notices';
  static const String noticesTranslate = '/notices/translate';

  // Meetings
  static const String meetings = '/meetings';
  static String meetingJoin(String meetingId) => '/meetings/$meetingId/join';
  static String meetingEnd(String meetingId) => '/meetings/$meetingId/end';
  static const String recordings = '/meetings/recordings';

  // Payments
  static const String payments = '/payments';
  static const String paymentSchedules = '/payments/schedules';
  static String markPaymentPaid(String id) => '/payments/$id/paid';

  // Library & AI Teacher
  static const String media = '/media';
  static const String mediaFolders = '/media/folders';
  static const String mediaUpload = '/media/upload';
  static const String aiTeacherAsk = '/ai-teacher/ask';
  static const String aiTeacherDocuments = '/ai-teacher/documents';

  // Profile & Branding
  static const String applicationsMine = '/applications/mine';
  static const String applicationsMineProfile = '/applications/mine/profile';
  static const String applicationsMineLogo = '/applications/mine/logo';
}

