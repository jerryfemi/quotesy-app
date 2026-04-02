import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes/app_router.dart';
import 'theme/quotesy_theme.dart';

Future<void> main() async {
  // Essential for app startup
  WidgetsFlutterBinding.ensureInitialized();

  // We launch immediately. Heavy services (DB, Notifications, RevenueCat) 
  // are handled in the background during the SplashScreen animation.
  runApp(
    ProviderScope(
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
