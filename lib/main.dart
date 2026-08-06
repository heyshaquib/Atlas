/// Atlas — Premium Bookmark Manager for Android
/// Entry point with Riverpod provider scope and WorkManager initialization.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/services/dead_link_checker.dart';
import 'package:atlas/services/trash_cleanup_worker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';

// WorkManager callback dispatcher (top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final db = AppDatabase();

    switch (task) {
      case 'deadLinkCheck':
        final checker = DeadLinkChecker(db);
        await checker.checkAll();
        checker.dispose();
        break;
      case 'trashCleanup':
        final prefs = await SharedPreferences.getInstance();
        final days = prefs.getInt('trash_auto_clear_days') ?? -1;
        final worker = TrashCleanupWorker(db);
        await worker.cleanup(days);
        break;
    }

    return true;
  });
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Lock to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Enable edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Trigger Google Fonts to start loading the Outfit font
  // and wait for all pending fonts to finish loading
  GoogleFonts.outfit();
  await GoogleFonts.pendingFonts();

  // Initialize WorkManager
  await Workmanager().initialize(callbackDispatcher);

  // Register periodic tasks
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
  final deadLinkFreq = prefs.getString('dead_link_check_frequency') ?? 'weekly';

  if (deadLinkFreq != 'never') {
    final frequency = deadLinkFreq == 'daily'
        ? const Duration(hours: 24)
        : const Duration(days: 7);
    await Workmanager().registerPeriodicTask(
      'deadLinkCheck',
      'deadLinkCheck',
      frequency: frequency,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  await Workmanager().registerPeriodicTask(
    'trashCleanup',
    'trashCleanup',
    frequency: const Duration(days: 1),
  );

  runApp(ProviderScope(child: AtlasApp(initialOnboardingDone: onboardingDone)));
}
