import 'dart:io';
import 'package:flutter/material.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/app_strings.dart';
import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:recyclescan/core/models/recycling_category.dart';

class RecentScansWidget extends StatelessWidget {
  final List<ScanItem> items;
  final void Function(ScanItem item) onItemTap;
  final VoidCallback onScanTap;
  final void Function(String id)? onDelete;

  const RecentScansWidget({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.onScanTap,
    this.onDelete,
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
            const Icon(Icons.history, size: 40, color: AppColors.primaryGreen),
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final category = RecyclingData.categoriesMap[item.categoryId];
        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            if (onDelete != null) {
              onDelete!(item.id);
            }
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
          ),
          child: GestureDetector(
            onTap: () => onItemTap(item),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: category?.lightColor ?? AppColors.lightMint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (category?.color ?? AppColors.primaryGreen)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: item.localImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(item.localImagePath!),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildFallbackImage(category),
                            ),
                          )
                        : _buildFallbackImage(category),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category?.name ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: category?.color ?? AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackImage(RecyclingCategory? category) {
    if (category != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          category.imageAsset,
          width: 50,
          height: 50,
          cacheWidth: 100,
          cacheHeight: 100,
          fit: BoxFit.cover,
        ),
      );
    }
    return const Icon(
      Icons.inventory_2_outlined,
      size: 24,
      color: AppColors.textSecondary,
    );
  }
}
