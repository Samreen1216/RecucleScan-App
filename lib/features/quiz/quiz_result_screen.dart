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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.score == widget.total) {
        setState(() => _badgeEarned = true);
        ref.read(badgeProvider.notifier).earnBadge();
        _confettiController.play();
      }
    });
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
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                backgroundColor: AppColors.background,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryGreen, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                  title: const Text(
                    'Quiz Results',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: SafeArea(
                  top: false,
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
                          
                          const Text(
                            'Your Score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            '${widget.score} / ${widget.total}',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              color: _badgeEarned ? AppColors.amber : AppColors.primaryGreen,
                            ),
                          ).animate().fadeIn(delay: 600.ms).scale(),
                          
                          const SizedBox(height: 16),
                          
                          Text(
                            _badgeEarned 
                              ? 'Perfect Score! You earned the Quiz Master badge!'
                              : (widget.score > widget.total / 2 ? 'Great job! Keep learning.' : 'Good effort! Check the guides to learn more.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: AppColors.textPrimary,
                            ),
                          ).animate().fadeIn(delay: 800.ms),
                          
                          const SizedBox(height: 48),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.go('/home'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('BACK TO HOME'),
                            ),
                          ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.primaryGreen,
                AppColors.primaryLight,
                AppColors.mintGreen,
                AppColors.amber,
                Colors.blue,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
