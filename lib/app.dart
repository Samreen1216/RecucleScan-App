import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:recyclescan/core/constants/app_colors.dart';
import 'package:recyclescan/core/router/app_router.dart';
import 'package:google_fonts/google_fonts.dart';

class RecycleScanApp extends ConsumerStatefulWidget {
  const RecycleScanApp({super.key});

  @override
  ConsumerState<RecycleScanApp> createState() => _RecycleScanAppState();
}

class _RecycleScanAppState extends ConsumerState<RecycleScanApp> {
  StreamSubscription<Uri?>? _sub;

  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId('group.com.example.recyclescan');
    
    // Handle initial launch from widget
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetClick);
    
    // Listen for widget clicks while app is open
    _sub = HomeWidget.widgetClicked.listen(_handleWidgetClick);
  }

  void _handleWidgetClick(Uri? uri) {
    if (uri != null) {
      final route = uri.path; // e.g. /scanner
      if (route.isNotEmpty) {
        final router = ref.read(appRouterProvider);
        router.push(route);
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'RecycleScan',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      routerConfig: router,
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        secondary: AppColors.mintGreen,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primaryGreen),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.mintGreen),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.mintGreen.withValues(alpha: 0.5)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
    );
  }
}

