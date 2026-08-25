import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recyclescan/app.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:recyclescan/core/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ScanItemAdapter());
  await HiveService.openBoxes();
  runApp(
    const ProviderScope(
      child: RecycleScanApp(),
    ),
  );
}
