import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:recyclescan/core/services/hive_service.dart';
import 'package:recyclescan/features/guide/category_detail_screen.dart';
import 'package:recyclescan/features/guide/guide_screen.dart';
import 'package:recyclescan/features/history/history_screen.dart';
import 'package:recyclescan/features/home/home_screen.dart';
import 'package:recyclescan/features/onboarding/onboarding_screen.dart';
import 'package:recyclescan/features/result/result_screen.dart';
import 'package:recyclescan/features/scanner/scanner_screen.dart';
import 'package:recyclescan/features/settings/settings_screen.dart';
import 'package:recyclescan/features/splash/splash_screen.dart';
import 'package:recyclescan/shared/widgets/app_shell.dart';
import 'package:recyclescan/features/quiz/quiz_screen.dart';
import 'package:recyclescan/features/quiz/quiz_result_screen.dart';
import 'package:recyclescan/features/bag/bag_screen.dart';

final initialLocationProvider = Provider<String>((ref) => '/home');

final appRouterProvider = Provider<GoRouter>((ref) {
  final initialLocation = ref.watch(initialLocationProvider);
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/guide',
            builder: (context, state) => const GuideScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/result/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          final item = state.extra is ScanItem
              ? state.extra as ScanItem
              : (id != null ? HiveService.getScanItemById(id) : null);
          return ResultScreen(item: item, itemId: id);
        },
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final item = state.extra is ScanItem ? state.extra as ScanItem : null;
          return ResultScreen(item: item);
        },
      ),
      GoRoute(
        path: '/quiz',
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: '/quiz-result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return QuizResultScreen(
            score: extra['score'] as int,
            total: extra['total'] as int,
          );
        },
      ),
      GoRoute(
        path: '/guide/:categoryId',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          return CategoryDetailScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/bag',
        builder: (context, state) => const BagScreen(),
      ),
    ],
  );
});
