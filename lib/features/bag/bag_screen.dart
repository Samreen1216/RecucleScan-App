import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/providers/bag_provider.dart';

class BagScreen extends ConsumerWidget {
  const BagScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(bagProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (context.canPop()) context.pop();
                else context.go('/home');
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGreen, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              ' Recycling Bag',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${items.length} item${items.length == 1 ? "" : "s"} in bag',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                        if (items.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Clear Bag?'),
                                    content: const Text('Are you sure you want to empty your recycling bag?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('CANCEL', style: TextStyle(color: Colors.black54)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          ref.read(bagProvider.notifier).clearBag();
                                          Navigator.pop(context);
                                        },
                                        child: const Text('CLEAR', style: TextStyle(color: AppColors.error)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.delete_sweep_outlined,
                                  color: Colors.white70, size: 18),
                              label: const Text(
                                'Clear All',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'Your recycling bag is empty',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    final category = RecyclingData.categoriesMap[item.categoryId];
                    
                    return Dismissible(
                      key: Key('${item.id}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        ref.read(bagProvider.notifier).removeItem(item.id);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.mintGreen.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: item.localImagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(File(item.localImagePath!), fit: BoxFit.cover),
                                  )
                                : Icon(Icons.inventory_2_outlined, color: category?.color ?? AppColors.primaryGreen),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            category?.name ?? 'Unknown',
                            style: TextStyle(color: category?.color ?? AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          trailing: const Icon(Icons.chevron_left, color: AppColors.textLight, size: 20),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}




