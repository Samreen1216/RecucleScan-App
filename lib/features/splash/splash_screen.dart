import 'package:recyclescan/core/services/hive_service.dart';
import 'package:recyclescan/core/services/widget_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    // 1. Parallelize initializations with a snappy display timer
    final minDisplayTimer = Future.delayed(const Duration(milliseconds: 800));
    final prefsFuture = SharedPreferences.getInstance();
    final hiveFuture = HiveService.openBoxes();

    final results = await Future.wait([
      minDisplayTimer,
      prefsFuture,
      hiveFuture,
    ]);

    if (!mounted) return;

    // 2. Check onboarding status and navigate
    final prefs = results[1] as SharedPreferences;
    final hasOnboarded = prefs.getBool('has_onboarded') ?? false;

    if (hasOnboarded) {
      // Sync fresh widget data
      WidgetService.updateWidgetData(allItems: HiveService.getAllScanItems());
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.recycling,
                  size: 60,
                  color: AppColors.primaryGreen,
                ),
              ),
            )
                .animate()
                .scale(
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 28),

            // App name
            const Text(
              'RecycleScan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 150.ms, duration: 350.ms)
                .slideY(begin: 0.2, end: 0, delay: 150.ms, duration: 350.ms),

            const SizedBox(height: 10),

            const Text(
              'Scan. Learn. Recycle.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            )
                .animate()
                .fadeIn(delay: 250.ms, duration: 350.ms),

            const SizedBox(height: 60),

            // Loading indicator
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Colors.white.withValues(alpha: 0.8),
                strokeWidth: 3,
              ),
            ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}


