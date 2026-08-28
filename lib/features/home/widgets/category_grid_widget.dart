import 'package:flutter/material.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/models/recycling_category.dart';

class CategoryGridWidget extends StatelessWidget {
  final List<RecyclingCategory> categories;
  final void Function(String categoryId) onCategoryTap;

  const CategoryGridWidget({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 125, // Enough height for icon (76) + spacing (8) + 2 lines of text
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () => onCategoryTap(category.id),
            child: SizedBox(
              width: 85, // Fixed width for each category item
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: category.lightColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: category.color.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18.5),
                      child: Image.asset(
                        category.imageAsset,
                        width: 76,
                        height: 76,
                        cacheWidth: 152,
                        cacheHeight: 152,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
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
