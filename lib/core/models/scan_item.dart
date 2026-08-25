import 'package:hive/hive.dart';

part 'scan_item.g.dart';

@HiveType(typeId: 0)
class ScanItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String barcode;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String? brand;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final String? imageEmoji;

  ScanItem({
    required this.id,
    required this.name,
    required this.barcode,
    required this.categoryId,
    required this.timestamp,
    this.brand,
    this.notes,
    this.imageEmoji,
  });

  ScanItem copyWith({
    String? id,
    String? name,
    String? barcode,
    String? categoryId,
    DateTime? timestamp,
    String? brand,
    String? notes,
    String? imageEmoji,
  }) {
    return ScanItem(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      timestamp: timestamp ?? this.timestamp,
      brand: brand ?? this.brand,
      notes: notes ?? this.notes,
      imageEmoji: imageEmoji ?? this.imageEmoji,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'categoryId': categoryId,
      'timestamp': timestamp.toIso8601String(),
      'brand': brand,
      'notes': notes,
      'imageEmoji': imageEmoji,
    };
  }
}
