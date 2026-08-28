import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recyclescan/app.dart';
import 'package:recyclescan/core/models/scan_item.dart';
import 'package:recyclescan/core/router/app_router.dart';
import 'package:recyclescan/core/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(ScanItemAdapter());
  

  runApp(
    ProviderScope(
      overrides: [
        // Always start at Splash Screen so the user gets the beautiful launch animation!
        initialLocationProvider.overrideWithValue('/splash'),
      ],
      child: const RecycleScanApp(),
    ),
  );
}

