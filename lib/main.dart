import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'providers/database_provider.dart';
import 'routes/app_router.dart';
import 'theme/quotesy_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      defaultDevice: Devices.android.googlePixel9,
      builder: (context) => const ProviderScope(child: QuotesyApp()),
    ),
  );
}

class QuotesyApp extends ConsumerWidget {
  const QuotesyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbInit = ref.watch(databaseInitProvider);
    final router = ref.watch(routerProvider);

    return dbInit.when(
      data: (_) => MaterialApp.router(
        title: 'Quotesy',
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: darkMode,
        routerConfig: router,
      ),
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: darkMode,
        home: const _SplashScreen(),
      ),
      error: (err, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: darkMode,
        home: _ErrorScreen(error: err),
      ),
    );
  }
}

// ── Splash ──────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quotesy',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 36,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error ────────────────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final Object error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Failed to load database.\n\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
