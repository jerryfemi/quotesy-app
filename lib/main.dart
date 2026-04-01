import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'models/streak_model.dart';
import 'providers/database_provider.dart';
import 'routes/app_router.dart';
import 'services/notification_service.dart';
import 'theme/quotesy_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // RevenueCat 
  await Purchases.setLogLevel(LogLevel.debug);
  await Purchases.configure(
    PurchasesConfiguration('goog_xrjdqrwqgLqwUvrGwcDUnxBBHKP'),
  );

  // Notifications 
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  // Database (must finish before we can read filters / streak) 
  final container = ProviderContainer();
  final db = container.read(databaseServiceProvider);
  await db.init();
  await db.ensureInitialImport();

  // Reschedule-on-Open sync 
  final quotes = await db.getFilteredFeed(
    selectedCategories: db.getSelectedCategories(),
    selectedAuthors: db.getSelectedAuthors(),
  );
  final streak = container.read(streakProvider);

  await notificationService.syncScheduledNotifications(
    quotes: quotes,
    streak: streak,
  );

  // Launch  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: DevicePreview(
        enabled: kDebugMode,
        defaultDevice: Devices.android.googlePixel9,
        builder: (context) => const QuotesyApp(),
      ),
    ),
  );
}

class QuotesyApp extends StatelessWidget {
  const QuotesyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quotesy',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: darkMode,
      routerConfig: routerProvider,
    );
  }
}
