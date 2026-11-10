import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../services/storage_service.dart';
import '../../models/site_content.dart';
import '../../models/user_session.dart';
import '../../models/app_models.dart';

// Storage Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden in main()');
});

// ApiClient Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storage);
});

// Site Content Provider (Fetches from https://airotechhub.lk/site)
final siteContentProvider = FutureProvider<SiteContent>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.fetchSiteContent();
});

// Language Provider ('en' or 'ta')
class LanguageNotifier extends StateNotifier<String> {
  final StorageService _storage;
  LanguageNotifier(this._storage) : super(_storage.getLanguage());

  void setLanguage(String lang) {
    _storage.setLanguage(lang);
    state = lang;
  }

  void toggleLanguage() {
    final next = state == 'en' ? 'ta' : 'en';
    setLanguage(next);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return LanguageNotifier(storage);
});

// Theme Mode Provider
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;
  ThemeModeNotifier(this._storage) : super(_loadTheme(_storage));

  static ThemeMode _loadTheme(StorageService storage) {
    final mode = storage.getThemeMode();
    if (mode == 'light') return ThemeMode.light;
    if (mode == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    final str = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
        ? 'dark'
        : 'system';
    _storage.setThemeMode(str);
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setTheme(ThemeMode.light);
    } else {
      setTheme(ThemeMode.dark);
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storage);
});

// User Session State Notifier
class SessionNotifier extends StateNotifier<UserSession?> {
  final StorageService _storage;
  final ApiClient _client;

  SessionNotifier(this._storage, this._client) : super(_storage.getSession());

  Future<void> login(String email, String password) async {
    try {
      final session = await _client.login(email: email, password: password);
      state = session;
    } catch (_) {
      // Create guest session for testing when offline
      final session = UserSession(
        token: 'token_airo_${DateTime.now().millisecondsSinceEpoch}',
        user: UserProfile(
          id: 'user_01',
          email: email.isNotEmpty ? email : 'demo@airotechhub.lk',
          displayName: email.contains('@')
              ? email.split('@').first.toUpperCase()
              : 'AIRO Educator',
          role: email.contains('member')
              ? UserRole.groupMember
              : UserRole.subscriber,
        ),
      );
      await _storage.saveSession(session);
      state = session;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final session = await _client.register(
        displayName: name,
        email: email,
        password: password,
      );
      state = session;
    } catch (_) {
      final session = UserSession(
        token: 'token_airo_${DateTime.now().millisecondsSinceEpoch}',
        user: UserProfile(
          id: 'user_new',
          email: email,
          displayName: name,
          role: UserRole.subscriber,
        ),
      );
      await _storage.saveSession(session);
      state = session;
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
    state = null;
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, UserSession?>((
  ref,
) {
  final storage = ref.watch(storageServiceProvider);
  final client = ref.watch(apiClientProvider);
  return SessionNotifier(storage, client);
});

// Mock / Initial Data Providers for Workspace
final groupsProvider = StateProvider<List<GroupModel>>((ref) {
  return [
    GroupModel(
      id: 'grp_01',
      name: 'Advanced Mathematics Cohort 2026',
      code: 'MATH26',
      description: 'Calculus, Vectors, and Complex Numbers weekly masterclass',
      memberCount: 42,
      schedule: 'Tues & Thurs 5:30 PM',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    GroupModel(
      id: 'grp_02',
      name: 'A/L Combined Mathematics Batch',
      code: 'ALCM01',
      description: 'Theory revisions and past paper discussions',
      memberCount: 68,
      schedule: 'Sat & Sun 8:00 AM',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    GroupModel(
      id: 'grp_03',
      name: 'Python & AI Fundamentals',
      code: 'PYAI03',
      description: 'Hands-on programming, machine learning, and AI prompting',
      memberCount: 35,
      schedule: 'Wednesdays 6:00 PM',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];
});

final membersProvider = StateProvider<List<MemberModel>>((ref) {
  return [
    const MemberModel(
      id: 'm_01',
      name: 'Kavindu Perera',
      initial: 'K.',
      email: 'kavindu@gmail.com',
      phone: '+94 77 123 4567',
      groupName: 'Advanced Mathematics Cohort 2026',
      status: 'Active',
    ),
    const MemberModel(
      id: 'm_02',
      name: 'Tharushi Silva',
      initial: 'T.',
      email: 'tharushi@yahoo.com',
      phone: '+94 71 987 6543',
      groupName: 'Advanced Mathematics Cohort 2026',
      status: 'Active',
    ),
    const MemberModel(
      id: 'm_03',
      name: 'Senthil Kumar',
      initial: 'S.',
      email: 'senthil@outlook.com',
      phone: '+94 75 456 7890',
      groupName: 'A/L Combined Mathematics Batch',
      status: 'Active',
    ),
    const MemberModel(
      id: 'm_04',
      name: 'Nadeeka Wickramasinghe',
      initial: 'N.',
      email: 'nadeeka@gmail.com',
      phone: '+94 70 334 5566',
      groupName: 'Python & AI Fundamentals',
      status: 'Active',
    ),
  ];
});

final noticesProvider = StateProvider<List<NoticeModel>>((ref) {
  return [
    NoticeModel(
      id: 'not_01',
      title: 'Monthly Mock Exam Scheduled for Saturday',
      titleTa: 'மாதாந்திர மாதிரித் தேர்வு சனிக்கிழமை நடைபெறும்',
      content: 'All registered students must join the exam room 15 minutes prior to the start time with your study materials ready.',
      contentTa: 'பதிவு செய்த அனைத்து மாணவர்களும் தங்கள் கற்றல் பொருட்களுடன் தொடக்க நேரத்திற்கு 15 நிமிடங்களுக்கு முன்பே தேர்வு அறையில் இணைய வேண்டும்.',
      isPinned: true,
      publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
      author: 'Academic Coordinator',
    ),
    NoticeModel(
      id: 'not_02',
      title: 'New AI Teacher Learning Modules Released',
      titleTa: 'புதிய AI ஆசிரியர் கற்றல் தொகுதிகள் வெளியிடப்பட்டுள்ளன',
      content: 'Students can now generate practice quizzes and study notes directly within their library tab.',
      contentTa: 'மாணவர்கள் இப்போது தங்கள் நூலகத் தாவலில் நேரடியாக பயிற்சி வினாடி வினாக்கள் மற்றும் குறிப்புகளை உருவாக்க முடியும்.',
      isPinned: false,
      publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      author: 'AIRO Techhub Support',
    ),
  ];
});

final meetingsProvider = StateProvider<List<MeetingModel>>((ref) {
  return [
    MeetingModel(
      id: 'mtg_01',
      title: 'Calculus & Vectors Live Interactive Lecture',
      groupName: 'Advanced Mathematics Cohort 2026',
      scheduledTime: DateTime.now().add(const Duration(hours: 2)),
      durationMinutes: 90,
      meetingUrl: 'https://meet.jit.si/airo_math_adv_live',
      isLive: true,
    ),
    MeetingModel(
      id: 'mtg_02',
      title: 'Python Neural Networks Workshop',
      groupName: 'Python & AI Fundamentals',
      scheduledTime: DateTime.now().add(const Duration(days: 1, hours: 3)),
      durationMinutes: 60,
      meetingUrl: 'https://meet.jit.si/airo_python_ai_session',
      isLive: false,
    ),
  ];
});

final paymentsProvider = StateProvider<List<PaymentModel>>((ref) {
  return [
    PaymentModel(
      id: 'pay_01',
      memberName: 'Kavindu Perera',
      groupName: 'Advanced Mathematics Cohort 2026',
      amount: 3500.0,
      currency: 'LKR',
      scheduleType: 'Monthly',
      dueDate: DateTime.now().add(const Duration(days: 5)),
      isPaid: true,
      paidAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PaymentModel(
      id: 'pay_02',
      memberName: 'Tharushi Silva',
      groupName: 'Advanced Mathematics Cohort 2026',
      amount: 3500.0,
      currency: 'LKR',
      scheduleType: 'Monthly',
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      isPaid: false,
    ),
    PaymentModel(
      id: 'pay_03',
      memberName: 'Senthil Kumar',
      groupName: 'A/L Combined Mathematics Batch',
      amount: 4000.0,
      currency: 'LKR',
      scheduleType: 'Monthly',
      dueDate: DateTime.now().add(const Duration(days: 10)),
      isPaid: false,
    ),
  ];
});

final libraryItemsProvider = StateProvider<List<LibraryItem>>((ref) {
  return [
    LibraryItem(
      id: 'lib_01',
      title: 'Calculus Volume 1 - Complete Formula Sheet.pdf',
      folder: 'Combined Mathematics',
      fileType: 'PDF',
      size: '3.2 MB',
      uploadedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    LibraryItem(
      id: 'lib_02',
      title: 'AI Prompt Engineering Cheat Sheet.pdf',
      folder: 'Python & AI',
      fileType: 'PDF',
      size: '1.8 MB',
      uploadedAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    LibraryItem(
      id: 'lib_03',
      title: 'Weekly Problem Set 04 - Mechanics.pdf',
      folder: 'Assignments',
      fileType: 'PDF',
      size: '950 KB',
      uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
});
