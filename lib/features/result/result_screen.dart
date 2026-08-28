import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/models/recycling_category.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:recyclescan/core/providers/bag_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final ScanItem item;

  const ResultScreen({super.key, required this.item});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {

  RecyclingCategory? get _category =>
      RecyclingData.categoriesMap[widget.item.categoryId];

  bool get _isRecyclable => widget.item.categoryId.toLowerCase() != 'general';

  @override
  Widget build(BuildContext context) {
    final category = _category;
    if (category == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('Category not found')),
      );
    }

    final isInBag = ref.watch(bagProvider).any((i) => i.id == widget.item.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Scan Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Image Section
            _buildImageSection(category).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            
            // 2. Main Result Card
            _buildMainResultCard(category).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            // 3. How to Dispose
            _buildHowToDispose(category).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            // 4. Why It Matters
            _buildWhyItMatters(category).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            // 5. Bag Button
            _buildBagButton(isInBag).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),

            // 6. Bottom Actions
            _buildBottomActions(category).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(RecyclingCategory category) {
    return Column(
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: category.lightColor,
            image: widget.item.localImagePath != null
                ? DecorationImage(
                    image: FileImage(File(widget.item.localImagePath!)),
                    fit: BoxFit.cover,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.item.localImagePath == null
              ? Icon(Icons.inventory_2_outlined, size: 60, color: category.color)
              : null,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 14, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Text(
                'AI IDENTIFIED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.item.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        if (widget.item.brand != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.item.brand!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainResultCard(RecyclingCategory category) {
    final Color bgColor = _isRecyclable ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1);
    final Color fgColor = _isRecyclable ? AppColors.success : AppColors.error;
    final String statusText = _isRecyclable ? 'RECYCLABLE' : 'LANDFILL';
    final IconData statusIcon = _isRecyclable ? Icons.check_circle : Icons.cancel;
    final String binName = _isRecyclable ? '${category.name} Recycling Bin' : 'General Waste Bin';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fgColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: fgColor, size: 28),
              const SizedBox(width: 10),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: fgColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            category.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.recycleSymbol,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                binName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowToDispose(RecyclingCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HOW TO DISPOSE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.black54,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ...category.preparationTips.asMap().entries.map((entry) {
          int index = entry.key + 1;
          String tip = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '0$index',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Step',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWhyItMatters(RecyclingCategory category) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.public, size: 18, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text(
                'WHY IT MATTERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            category.funFact,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBagButton(bool isInBag) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        if (!isInBag) {
          ref.read(bagProvider.notifier).addItem(widget.item);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isInBag ? Colors.black87 : AppColors.primaryGreen,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isInBag ? Icons.check : Icons.add_shopping_cart,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            isInBag ? 'ADDED TO RECYCLING BAG' : 'ADD TO RECYCLING BAG',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(RecyclingCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () => context.push('/guide/${category.id}'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            side: const BorderSide(color: Colors.black12, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'VIEW FULL GUIDE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.push('/scanner'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'SCAN ANOTHER ITEM',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
