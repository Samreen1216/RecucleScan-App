import 'package:flutter/material.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/app_strings.dart';
import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/models/scan_item.dart';

class RecentScansWidget extends StatelessWidget {
  final List<ScanItem> items;
  final void Function(ScanItem item) onItemTap;
  final VoidCallback onScanTap;

  const RecentScansWidget({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mintGreen.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text(
              AppStrings.noRecentScans,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onScanTap,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Start Scanning'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final category = RecyclingData.categoriesMap[item.categoryId];
          return GestureDetector(
            onTap: () => onItemTap(item),
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: category?.lightColor ?? AppColors.lightMint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (category?.color ?? AppColors.primaryGreen)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.imageEmoji ?? '📦',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
