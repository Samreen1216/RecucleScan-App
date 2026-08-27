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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.microtask(_navigate);
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
    if (!mounted) return;
    if (hasOnboarded) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),

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
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 500.ms),

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
                .fadeIn(delay: 500.ms, duration: 500.ms),

            const SizedBox(height: 80),

            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white.withValues(alpha: 0.8),
                strokeWidth: 3,
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
