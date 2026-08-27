import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/app_strings.dart';
import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/providers/eco_tip_provider.dart';
import 'package:recyclescan/core/providers/scan_history_provider.dart';
import 'package:recyclescan/features/home/widgets/category_grid_widget.dart';
import 'package:recyclescan/features/home/widgets/eco_tip_widget.dart';
import 'package:recyclescan/features/home/widgets/recent_scans_widget.dart';
import 'package:recyclescan/features/home/widgets/recycle_quiz_widget.dart';

class DynamicGreetingWidget extends StatefulWidget {
  const DynamicGreetingWidget({super.key});

  @override
  State<DynamicGreetingWidget> createState() => _DynamicGreetingWidgetState();
}

class _DynamicGreetingWidgetState extends State<DynamicGreetingWidget> {
  late String _greeting;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _startTimer();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    String newGreeting;
    if (hour < 12) {
      newGreeting = AppStrings.goodMorning;
    } else if (hour < 17) {
      newGreeting = AppStrings.goodAfternoon;
    } else {
      newGreeting = AppStrings.goodEvening;
    }

    if (!mounted) return;
    setState(() {
      _greeting = newGreeting;
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _updateGreeting();
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _greeting,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecoTip = ref.watch(ecoTipProvider);
    final history = ref.watch(scanHistoryProvider);
    final recentItems = history.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGreen, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const DynamicGreetingWidget(),
                                const SizedBox(height: 4),
                                const Text(
                                  'RecycleScan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  'Let\'s make recycling easy',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.recycling, color: Colors.white, size: 26),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eco Tip
                  EcoTipWidget(tip: ecoTip)
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideY(begin: 0.1, delay: 100.ms),

                  const SizedBox(height: 28),

                  // Recycling Categories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        AppStrings.categories,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/guide'),
                        child: const Text(
                          AppStrings.viewAll,
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 12),
                  CategoryGridWidget(
                    categories: RecyclingData.categories,
                    onCategoryTap: (categoryId) =>
                        context.push('/guide/$categoryId'),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, delay: 200.ms),

                  const SizedBox(height: 28),

                  // Recycle Quiz Card
                  RecycleQuizWidget(
                    onStartQuiz: () {
                      context.push('/quiz');
                    },
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, delay: 250.ms),

                  const SizedBox(height: 28),

                  // Recent Scans
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        AppStrings.recentScans,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (recentItems.isNotEmpty)
                        TextButton(
                          onPressed: () => context.go('/history'),
                          child: const Text(
                            AppStrings.viewAll,
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 12),
                  RecentScansWidget(
                    items: recentItems,
                    onItemTap: (item) => context.push('/result', extra: item),
                    onScanTap: () => context.push('/scanner'),
                    onDelete: (id) {
                      ref.read(scanHistoryProvider.notifier).removeItem(id);
                    },
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
