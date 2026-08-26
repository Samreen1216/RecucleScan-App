import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/providers/badge_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

class QuizResultScreen extends ConsumerStatefulWidget {
  final int score;
  final int total;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
  });

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> {
  late ConfettiController _confettiController;
  bool _badgeEarned = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // 4 out of 5 to earn a badge
    if (widget.score >= 4) {
      _badgeEarned = true;
      _confettiController.play();
      Future.microtask(() {
        ref.read(badgeProvider.notifier).earnBadge();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon/Illustration
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _badgeEarned ? AppColors.amber.withValues(alpha: 0.1) : AppColors.primaryLight.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _badgeEarned ? Icons.workspace_premium_rounded : Icons.recycling_rounded,
                        size: 80,
                        color: _badgeEarned ? AppColors.amber : AppColors.primaryGreen,
                      ),
                    ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.elasticOut),
                    
                    const SizedBox(height: 32),
                    
                    // Score
                    Text(
                      'You scored ${widget.score}/${widget.total}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),
                    
                    const SizedBox(height: 16),
                    
                    // Message
                    Text(
                      _badgeEarned 
                          ? 'Outstanding! You really know your recycling.\nYou earned a new Eco Badge! 🌟'
                          : 'Good effort! Keep learning about recycling to earn a badge next time. 📚',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                    
                    const SizedBox(height: 48),
                    
                    // Back to Home Button
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5),
                  ],
                ),
              ),
            ),
          ),
          
          // Confetti
          if (_badgeEarned)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.yellow, Colors.orange, Colors.purple],
              ),
            ),
        ],
      ),
    );
  }
}
