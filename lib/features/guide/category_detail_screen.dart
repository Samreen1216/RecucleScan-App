import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/app_strings.dart';
import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/models/recycling_category.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final category = RecyclingData.categoriesMap[categoryId];
    if (category == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Category')),
        body: const Center(child: Text('Category not found')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: category.color,
                leading: GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/guide');
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        category.imageAsset,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                category.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 50), // Spacing for the tabs
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: AppColors.primaryGreen,
                    indicatorWeight: 3,
                    labelColor: AppColors.primaryGreen,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'What Goes In'),
                      Tab(text: 'Keep Out'),
                      Tab(text: 'Tips & Facts'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _ItemListTab(
                items: category.whatGoesIn,
                icon: Icons.check_circle_outline,
                color: AppColors.success,
                emptyText: 'No items listed',
              ),
              _ItemListTab(
                items: category.whatStaysOut,
                icon: Icons.cancel_outlined,
                color: AppColors.error,
                emptyText: 'Nothing to exclude',
              ),
              _TipsTab(category: category),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemListTab extends StatelessWidget {
  final List<String> items;
  final IconData icon;
  final Color color;
  final String emptyText;

  const _ItemListTab({
    required this.items,
    required this.icon,
    required this.color,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
          child: Text(emptyText,
              style: const TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items[index],
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 60 * index))
              .slideX(begin: 0.1, delay: Duration(milliseconds: 60 * index)),
        );
      },
    );
  }
}

class _TipsTab extends StatelessWidget {
  final RecyclingCategory category;

  const _TipsTab({required this.category});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Preparation Tips',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...category.preparationTips.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.amberLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 80 * e.key))
                .slideY(begin: 0.1, delay: Duration(milliseconds: 80 * e.key)),
          );
        }),

        const SizedBox(height: 24),

        // Fun fact
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                category.lightColor,
                category.lightColor.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: category.color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppStrings.didYouKnow,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: category.color,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                category.funFact,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
