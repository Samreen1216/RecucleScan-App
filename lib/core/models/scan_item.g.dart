// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanItemAdapter extends TypeAdapter<ScanItem> {
  @override
  final int typeId = 0;

  @override
  ScanItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanItem(
      id: fields[0] as String,
      name: fields[1] as String,
      barcode: fields[2] as String,
      categoryId: fields[3] as String,
      timestamp: fields[4] as DateTime,
      brand: fields[5] as String?,
      notes: fields[6] as String?,
      imageEmoji: fields[7] as String?,
      localImagePath: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.barcode)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.brand)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.imageEmoji)
      ..writeByte(8)
      ..write(obj.localImagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
