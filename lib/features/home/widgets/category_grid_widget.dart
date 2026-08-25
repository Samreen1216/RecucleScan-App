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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () => onCategoryTap(category.id),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: category.lightColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: category.color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
