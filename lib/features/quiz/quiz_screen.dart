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

  @override
  void initState() {
    super.initState();
    // Shuffle and pick 5 questions
    _questions = QuizData.questions.toList()..shuffle();
    _questions = _questions.take(5).toList();
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

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.background,
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
          SliverFillRemaining(
            hasScrollBody: false,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
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
                  ),
                  
                  // Question Card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
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
                                  size: 40,
                                  color: AppColors.primaryGreen.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  currentQuestion.question,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ).animate(key: ValueKey(_currentIndex)).fadeIn().scale(begin: const Offset(0.95, 0.95)),
                          
                          const SizedBox(height: 30),
                          
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
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                          ),
                                        ),
                                      ),
                                      if (getIcon() != null) getIcon()!,
                                    ],
                                  ),
                                ),
                              ),
                            ).animate(key: ValueKey('$_currentIndex-$index')).fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Next / Explanation
                  if (_isAnswered)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          )
                        ],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _selectedAnswerIndex == currentQuestion.correctIndex
                                    ? Icons.thumb_up
                                    : Icons.lightbulb,
                                color: _selectedAnswerIndex == currentQuestion.correctIndex
                                    ? AppColors.success
                                    : AppColors.amber,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentQuestion.explanation,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _onNextQuestion,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(_currentIndex < _questions.length - 1 ? 'NEXT QUESTION' : 'SEE RESULTS'),
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: 1.0, end: 0.0, curve: Curves.easeOutCubic, duration: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
