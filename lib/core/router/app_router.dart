import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/models/scan_item.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
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
        path: '/result',
        builder: (context, state) {
          final item = state.extra as ScanItem;
          return ResultScreen(item: item);
        },
      ),
      GoRoute(
        path: '/guide/:categoryId',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          return CategoryDetailScreen(categoryId: categoryId);
        },
      ),
    ],
  );
});
