import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/app_svgs.dart';
import 'package:recyclescan/core/providers/badge_provider.dart';
import 'package:recyclescan/shared/widgets/app_svg_icon.dart';
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
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));

    // Only play confetti if score is passing/good (>= 3 out of 5)
    // NEVER play confetti on 0/5 or poor scores
    if (widget.score >= 3) {
      _confettiController.play();
    }

    // Award Quiz Master badge for perfect score
    if (widget.score == widget.total && widget.total > 0) {
      _badgeEarned = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(badgeProvider.notifier).earnBadge();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getHeadline() {
    if (widget.score == widget.total && widget.total > 0) return 'Perfect Score!';
    if (widget.score >= 3) return 'Great Job!';
    if (widget.score > 0) return 'Keep Learning!';
    return 'Oops! Better Luck Next Time';
  }

  String _getFeedbackMessage() {
    if (widget.score == widget.total && widget.total > 0) {
      return 'Outstanding! You answered every question correctly and earned the Quiz Master badge!';
    } else if (widget.score >= 3) {
      return 'Great effort! You have solid recycling knowledge. Keep sorting and sustaining!';
    } else if (widget.score > 0) {
      return 'Good effort! Check out the Recycling Guides in the app to discover more eco-friendly tips.';
    } else {
      return 'Don’t worry — keep learning and try the quiz again!';
    }
  }

  String _getSvgAsset() {
    if (_badgeEarned) return AppSvgs.trophyBadge;
    if (widget.score >= 3) return AppSvgs.ecoLeaf;
    if (widget.score > 0) return AppSvgs.lightbulb;
    return AppSvgs.quizBadge;
  }

  Color _getIconColor() {
    if (_badgeEarned) return AppColors.amber;
    if (widget.score >= 3) return AppColors.primaryGreen;
    if (widget.score > 0) return AppColors.primaryGreen;
    return AppColors.textSecondary;
  }

  Color _getIconBgColor() {
    if (_badgeEarned) return AppColors.amber.withValues(alpha: 0.15);
    if (widget.score >= 3) return AppColors.primaryLight.withValues(alpha: 0.15);
    if (widget.score > 0) return AppColors.mintGreen.withValues(alpha: 0.3);
    return Colors.black.withValues(alpha: 0.05);
  }

  Color _getScoreColor() {
    if (_badgeEarned) return AppColors.amber;
    if (widget.score >= 3) return AppColors.primaryGreen;
    if (widget.score > 0) return AppColors.primaryGreen;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
              SliverToBoxAdapter(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon / Badge
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _getIconBgColor(),
                            shape: BoxShape.circle,
                          ),
                          child: AppSvgIcon(
                            _getSvgAsset(),
                            size: 72,
                            color: _getIconColor(),
                          ),
                        ).animate().scale(delay: 150.ms, duration: 500.ms, curve: Curves.elasticOut),
                        
                        const SizedBox(height: 24),

                        // Headline
                        Text(
                          _getHeadline(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 12),
                        
                        const Text(
                          'Your Final Score',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          '${widget.score} / ${widget.total}',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: _getScoreColor(),
                          ),
                        ).animate().fadeIn(delay: 500.ms).scale(),
                        
                        const SizedBox(height: 14),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(
                            _getFeedbackMessage(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.45,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ).animate().fadeIn(delay: 650.ms),
                        
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.pushReplacement('/quiz'),
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: const Text('TRY ANOTHER QUIZ'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.15, end: 0),
                        
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.go('/home'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'BACK TO HOME',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.15, end: 0),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Confetti celebration overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 25,
              emissionFrequency: 0.05,
              gravity: 0.3,
              colors: const [
                AppColors.primaryGreen,
                AppColors.primaryLight,
                AppColors.mintGreen,
                AppColors.amber,
                Colors.orange,
                Colors.lightBlue,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
