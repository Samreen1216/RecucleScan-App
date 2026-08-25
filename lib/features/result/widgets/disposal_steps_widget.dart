import 'package:flutter/material.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/app_strings.dart';
import 'package:recyclescan/core/models/recycling_category.dart';

class DisposalStepsWidget extends StatelessWidget {
  final RecyclingCategory category;

  const DisposalStepsWidget({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.howToDispose,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Preparation Tips
        _SectionCard(
          title: AppStrings.preparationTips,
          icon: Icons.tips_and_updates_outlined,
          color: AppColors.amber,
          bgColor: AppColors.amberLight,
          items: category.preparationTips,
          numbered: true,
        ),

        const SizedBox(height: 12),

        // Do's
        _SectionCard(
          title: AppStrings.doList,
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          bgColor: AppColors.lightMint,
          items: category.whatGoesIn,
        ),

        const SizedBox(height: 12),

        // Don'ts
        _SectionCard(
          title: AppStrings.dontList,
          icon: Icons.cancel_outlined,
          color: AppColors.error,
          bgColor: const Color(0xFFFFF5F5),
          items: category.whatStaysOut,
        ),

        const SizedBox(height: 12),

        // Fun fact
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: category.lightColor,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: category.color.withOpacity(0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌟', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.didYouKnow,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: category.color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.funFact,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final List<String> items;
  final bool numbered;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.items,
    this.numbered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: numbered
                        ? Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          )
                        : Icon(
                            Icons.circle,
                            size: 6,
                            color: color,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
