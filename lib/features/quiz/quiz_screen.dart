import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/quiz_data.dart';
import 'package:recyclescan/core/models/quiz_question.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late List<QuizQuestion> _questions;
  int _currentIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  int _score = 0;
  bool _isExitDialogShowing = false;

  @override
  void initState() {
    super.initState();
    // Load fresh random questions
    _questions = QuizData.getRandomQuestions(count: 5);
  }

  void _onOptionSelected(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;
      if (index == _questions[_currentIndex].correctIndex) {
        _score++;
      }
    });
  }

  void _onNextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswerIndex = null;
        _isAnswered = false;
      });
    } else {
      context.pushReplacement('/quiz-result', extra: {'score': _score, 'total': _questions.length});
    }
  }

  Future<void> _onBackPressed() async {
    if (_isExitDialogShowing) return;
    _isExitDialogShowing = true;

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Are you sure you want to exit?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Your quiz progress will be lost if you exit now.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'EXIT',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    _isExitDialogShowing = false;

    if (shouldExit == true && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: _onBackPressed,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
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
                titlePadding: const EdgeInsets.only(left: 48, bottom: 16, right: 20),
                title: const Text(
                  'Recycle Quiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, _isAnswered ? 160 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Bar
                  Row(
                    children: [
                      Text(
                        '${_currentIndex + 1} / ${_questions.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.mintGreen.withValues(alpha: 0.3),
                            color: AppColors.primaryGreen,
                            minHeight: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  
                  // Question Card (Auto-height, responsive, no fixed limits)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 38,
                          color: AppColors.primaryGreen.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          currentQuestion.question,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ).animate(key: ValueKey(_currentIndex)).fadeIn().scale(begin: const Offset(0.97, 0.97)),
                  
                  const SizedBox(height: 20),
                  
                  // Options
                  ...List.generate(currentQuestion.options.length, (index) {
                    final isSelected = _selectedAnswerIndex == index;
                    final isCorrect = index == currentQuestion.correctIndex;
                    
                    Color getBorderColor() {
                      if (!_isAnswered) return isSelected ? AppColors.primaryGreen : AppColors.divider;
                      if (isCorrect) return AppColors.success;
                      if (isSelected && !isCorrect) return AppColors.error;
                      return AppColors.divider;
                    }
                    
                    Color getBgColor() {
                      if (!_isAnswered) return isSelected ? AppColors.mintGreen : Colors.white;
                      if (isCorrect) return AppColors.success.withValues(alpha: 0.1);
                      if (isSelected && !isCorrect) return AppColors.error.withValues(alpha: 0.1);
                      return Colors.white;
                    }
                    
                    Widget? getIcon() {
                      if (!_isAnswered) return null;
                      if (isCorrect) return const Icon(Icons.check_circle, color: AppColors.success);
                      if (isSelected && !isCorrect) return const Icon(Icons.cancel, color: AppColors.error);
                      return null;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _onOptionSelected(index),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                          decoration: BoxDecoration(
                            color: getBgColor(),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: getBorderColor(),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  currentQuestion.options[index],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              if (getIcon() != null) ...[
                                const SizedBox(width: 8),
                                getIcon()!,
                              ],
                            ],
                          ),
                        ),
                      ),
                    ).animate(key: ValueKey('$_currentIndex-$index')).fadeIn(delay: (40 * index).ms).slideX(begin: 0.06, end: 0);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isAnswered
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  )
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _selectedAnswerIndex == currentQuestion.correctIndex
                              ? Icons.thumb_up_rounded
                              : Icons.lightbulb_rounded,
                          color: _selectedAnswerIndex == currentQuestion.correctIndex
                              ? AppColors.success
                              : AppColors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentQuestion.explanation,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _onNextQuestion,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentIndex < _questions.length - 1 ? 'NEXT QUESTION' : 'SEE RESULTS',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 1.0, end: 0.0, curve: Curves.easeOutCubic, duration: 300.ms)
          : null,
      ),
    );
  }
}
