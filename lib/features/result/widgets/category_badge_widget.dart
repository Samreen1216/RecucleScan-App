import 'package:flutter/material.dart';
import 'package:recyclescan/core/models/recycling_category.dart';

class CategoryBadgeWidget extends StatelessWidget {
  final RecyclingCategory category;

  const CategoryBadgeWidget({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: category.lightColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: category.color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: category.color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              category.icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goes in: ${category.name} Bin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: category.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Text(
            category.recycleSymbol,
            style: const TextStyle(fontSize: 32),
          ),
        ],
      ),
    );
  }
}
