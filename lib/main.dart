import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'routes/app_router.dart';
import 'theme/quotesy_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize RevenueCat
  // await Purchases.setLogLevel(LogLevel.debug);
  // await Purchases.configure(PurchasesConfiguration('test_mCEpBRaEhFytinrhqwqhnAxdRMG'));

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      defaultDevice: Devices.android.googlePixel9,
      builder: (context) => const ProviderScope(child: QuotesyApp()),
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
