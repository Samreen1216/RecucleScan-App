import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/constants/app_strings.dart';
import 'package:recyclescan/core/constants/recycling_data.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:recyclescan/core/providers/scan_history_provider.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(AppStrings.confirmClear,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(AppStrings.confirmClearDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(scanHistoryProvider.notifier).clearAll();
    }
  }

  Future<void> _deleteItem(String id) async {
    await ref.read(scanHistoryProvider.notifier).removeItem(id);
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(scanHistoryProvider);
    final notifier = ref.read(scanHistoryProvider.notifier);

    List<ScanItem> filtered = _searchQuery.isNotEmpty
        ? notifier.search(_searchQuery)
        : history;

    if (_filterCategory != null) {
      filtered =
          filtered.where((i) => i.categoryId == _filterCategory).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: AppColors.background,
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              '📋 ${AppStrings.historyTitle}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${history.length} item${history.length == 1 ? '' : 's'} scanned',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                        if (history.isNotEmpty)
                          TextButton.icon(
                            onPressed: _confirmClearAll,
                            icon: const Icon(Icons.delete_sweep_outlined,
                                color: Colors.white70, size: 18),
                            label: const Text(
                              AppStrings.clearAll,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Search + Filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchHistory,
                      hintStyle: const TextStyle(
                          color: AppColors.textLight, fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Category filter chips
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _filterCategory == null,
                          onTap: () =>
                              setState(() => _filterCategory = null),
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        ...RecyclingData.categories.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: cat.name,
                              isSelected: _filterCategory == cat.id,
                              onTap: () => setState(
                                  () => _filterCategory = cat.id),
                              color: cat.color,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📭', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 16),
                    Text(
                      history.isEmpty
                          ? AppStrings.noHistory
                          : 'No results for "$_searchQuery"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    if (history.isEmpty) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/scanner'),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan an Item'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HistoryItemCard(
                        item: item,
                        onTap: () =>
                            context.push('/result', extra: item),
                        onDelete: () => _deleteItem(item.id),
                      )
                          .animate()
                          .fadeIn(
                              delay: Duration(milliseconds: 40 * index))
                          .slideX(
                              begin: 0.05,
                              delay: Duration(milliseconds: 40 * index)),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  final ScanItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryItemCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final category = RecyclingData.categoriesMap[item.categoryId];
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
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
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: (category?.color ?? AppColors.primaryGreen)
                    .withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: category?.lightColor ?? AppColors.lightMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item.imageEmoji ?? '📦',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (category != null) ...[
                          Icon(category.icon,
                              size: 13, color: category.color),
                          const SizedBox(width: 4),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: category.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          '• ${DateFormat('MMM d, y').format(item.timestamp)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
