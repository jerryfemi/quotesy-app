import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'providers/database_provider.dart';
import 'routes/app_router.dart';
import 'services/database_service.dart';
import 'theme/quotesy_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseService = DatabaseService();
  await databaseService.init();
  await databaseService.ensureInitialImport();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      defaultDevice: Devices.android.googlePixel9,
      builder: (context) => ProviderScope(
        overrides: [databaseServiceProvider.overrideWithValue(databaseService)],
        child: const QuotesyApp(),
      ),
    ),
  );
}

class QuotesyApp extends StatelessWidget {
  const QuotesyApp({super.key});

  @override
  Widget build(BuildContext context,) {

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
