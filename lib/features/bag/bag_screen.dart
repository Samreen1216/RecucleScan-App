import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/providers/bag_provider.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:intl/intl.dart';

class BagScreen extends ConsumerWidget {
  const BagScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(bagProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Recycling Bag'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Bag?'),
                    content: const Text('Are you sure you want to empty your recycling bag?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(bagProvider.notifier).clearBag();
                          Navigator.pop(context);
                        },
                        child: const Text('CLEAR'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyState(context)
          : _buildBagList(context, ref, items),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Your bag is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan items and add them to your bag\nto keep track of what to recycle.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.push('/scanner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Scan Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBagList(BuildContext context, WidgetRef ref, List<ScanItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isRecyclable = item.categoryId.toLowerCase() != 'general';
        
        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            ref.read(bagProvider.notifier).removeItem(item.id);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Added ${DateFormat.yMMMd().format(item.timestamp)}'),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isRecyclable ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isRecyclable ? 'RECYCLABLE' : 'LANDFILL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isRecyclable ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              onTap: () => context.push('/guide/${item.categoryId}'),
            ),
          ),
        );
      },
    );
  }
}
