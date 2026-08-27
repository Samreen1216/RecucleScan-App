import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/app_strings.dart';
import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/models/recycling_category.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:recyclescan/core/providers/scan_history_provider.dart';
import 'package:recyclescan/features/result/widgets/category_badge_widget.dart';
import 'package:recyclescan/features/result/widgets/disposal_steps_widget.dart';
import 'package:intl/intl.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final ScanItem item;

  const ResultScreen({super.key, required this.item});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _isSaved = false;

  RecyclingCategory? get _category =>
      RecyclingData.categoriesMap[widget.item.categoryId];

  Future<void> _saveToHistory() async {
    if (_isSaved) return;
    HapticFeedback.mediumImpact();
    await ref
        .read(scanHistoryProvider.notifier)
        .addItem(widget.item);
    setState(() => _isSaved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Saved to history!'),
            ],
          ),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;
    if (category == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('Category not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: category.color,
            leading: GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.item.localImagePath != null
                  ? Image.file(
                      File(widget.item.localImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackBackground(category),
                    )
                  : _buildFallbackBackground(category),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Brand
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.2, delay: 50.ms),
                  
                  if (widget.item.brand != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.item.brand!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, delay: 100.ms),
                  ],
                  
                  const SizedBox(height: 20),

                  // Category badge
                  CategoryBadgeWidget(category: category)
                      .animate()
                      .fadeIn(delay: 150.ms)
                      .slideY(begin: 0.2, delay: 150.ms),

                  const SizedBox(height: 20),

                  // Barcode info
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code,
                            color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Barcode: ${widget.item.barcode}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('MMM d').format(widget.item.timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 20),

                  // Notes
                  if (widget.item.notes != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: category.lightColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: category.color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: category.color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.item.notes!,
                              style: TextStyle(
                                fontSize: 14,
                                color: category.color,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 20),
                  ],

                  // Disposal steps
                  DisposalStepsWidget(category: category)
                      .animate()
                      .fadeIn(delay: 250.ms)
                      .slideY(begin: 0.1, delay: 250.ms),

                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaved ? null : _saveToHistory,
                          icon: Icon(
                            _isSaved
                                ? Icons.check_circle
                                : Icons.bookmark_add_outlined,
                          ),
                          label: Text(
                            _isSaved
                                ? AppStrings.savedToHistory
                                : AppStrings.saveToHistory,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSaved
                                ? AppColors.success
                                : category.color,
                            disabledBackgroundColor: AppColors.success,
                            disabledForegroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/guide/${category.id}'),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: const Text('Guide'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: category.color,
                          side: BorderSide(color: category.color),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBackground(RecyclingCategory category) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [category.color, category.color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 72,
          color: Colors.white,
        ),
      ),
    );
  }
}
