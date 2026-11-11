import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/landing/screens/landing_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/group_join_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/groups/screens/groups_screen.dart';
import '../../features/groups/screens/group_form_screen.dart';
import '../../features/groups/screens/group_detail_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/meetings/screens/meetings_screen.dart';
import '../../features/library/screens/library_screen.dart';
import '../../features/recording/screens/recording_screen.dart';
import '../../features/members/screens/members_screen.dart';
import '../../features/members/screens/member_form_screen.dart';
import '../../features/members/screens/member_detail_screen.dart';
import '../../features/notices/screens/notices_screen.dart';
import '../../features/payments/screens/payments_screen.dart';
import '../../features/ai_teacher/screens/ai_teacher_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/legal/screens/legal_screens.dart';
import '../../models/app_models.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Public Landing
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),

      // Auth Routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/group-join',
        builder: (context, state) => const GroupJoinScreen(),
      ),

      // AI Teacher Quick Demo from Landing
      GoRoute(
        path: '/ai-teacher-demo',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('AI Teacher')),
          body: const AiTeacherScreen(),
        ),
      ),

      // Legal Routes
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/cookies',
        builder: (context, state) => const CookiePolicyScreen(),
      ),

      // Authenticated Workspace Shell
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/app',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/app/members',
            builder: (context, state) => const MembersScreen(),
          ),
          GoRoute(
            path: '/app/members/new',
            builder: (context, state) => const MemberFormScreen(),
          ),
          GoRoute(
            path: '/app/members/:memberId',
            builder: (context, state) =>
                MemberDetailScreen(memberId: state.pathParameters['memberId']!),
          ),
          GoRoute(
            path: '/app/groups',
            builder: (context, state) => const GroupsScreen(),
          ),
          GoRoute(
            path: '/app/groups/new',
            builder: (context, state) => const GroupFormScreen(),
          ),
          GoRoute(
            path: '/app/groups/edit',
            builder: (context, state) {
              final extra = state.extra;
              return GroupFormScreen(group: extra is GroupModel ? extra : null);
            },
          ),
          GoRoute(
            path: '/app/groups/:groupId',
            builder: (context, state) =>
                GroupDetailScreen(groupId: state.pathParameters['groupId']!),
          ),
          GoRoute(
            path: '/app/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/app/meetings',
            builder: (context, state) => const MeetingsScreen(),
          ),
          GoRoute(
            path: '/app/library',
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: '/app/recording',
            builder: (context, state) => const RecordingScreen(),
          ),
          GoRoute(
            path: '/app/ai-teacher',
            builder: (context, state) => const AiTeacherScreen(),
          ),
        ],
      ),

      // Standalone Workspace Detail Routes
      GoRoute(
        path: '/app/notices',
        builder: (context, state) => const NoticesScreen(),
      ),
      GoRoute(
        path: '/app/payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: '/app/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
