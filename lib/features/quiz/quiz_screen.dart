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

  void _onNextPressed() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isAnswered = false;
        _selectedAnswerIndex = null;
      });
    } else {
      // Go to results
      context.pushReplacement('/quiz-result', extra: {
        'score': _score,
        'total': _questions.length,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Recycle Quiz',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        minHeight: 8,
                        backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question Text
                    Text(
                      currentQuestion.question,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ).animate(key: ValueKey(_currentIndex)).fadeIn().slideX(),
                    
                    const SizedBox(height: 32),
                    
                    // Options
                    ...List.generate(currentQuestion.options.length, (index) {
                      final isSelected = _selectedAnswerIndex == index;
                      final isCorrect = index == currentQuestion.correctIndex;
                      
                      Color backgroundColor = Colors.white;
                      Color borderColor = Colors.grey.withValues(alpha: 0.3);
                      Color textColor = AppColors.textPrimary;
                      
                      if (_isAnswered) {
                        if (isCorrect) {
                          backgroundColor = Colors.green.withValues(alpha: 0.1);
                          borderColor = Colors.green;
                          textColor = Colors.green[800]!;
                        } else if (isSelected) {
                          backgroundColor = Colors.red.withValues(alpha: 0.1);
                          borderColor = Colors.red;
                          textColor = Colors.red[800]!;
                        }
                      } else if (isSelected) {
                        backgroundColor = AppColors.primaryGreen.withValues(alpha: 0.1);
                        borderColor = AppColors.primaryGreen;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _onOptionSelected(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    currentQuestion.options[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected || (_isAnswered && isCorrect) ? FontWeight.w700 : FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                if (_isAnswered)
                                  if (isCorrect)
                                    const Icon(Icons.check_circle_rounded, color: Colors.green)
                                  else if (isSelected)
                                    const Icon(Icons.cancel_rounded, color: Colors.red),
                              ],
                            ),
                          ),
                        ),
                      ).animate(key: ValueKey('$_currentIndex-$index')).fadeIn(delay: Duration(milliseconds: 50 * index)).slideX();
                    }),

                    // Explanation (if answered)
                    if (_isAnswered) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primaryGreen),
                                SizedBox(width: 8),
                                Text(
                                  'Did you know?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentQuestion.explanation,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(),
                    ],
                  ],
                ),
              ),
            ),
            
            // Bottom Button
            if (_isAnswered)
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentIndex < _questions.length - 1 ? 'Next Question' : 'See Results',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ).animate().fadeIn().scale(),
              ),
          ],
        ),
      ),
    );
  }
}
