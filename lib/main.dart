import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'providers/database_provider.dart';
import 'services/database_service.dart';

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

    return MaterialApp(
      title: 'Quotesy',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: dbInit.when(
        data: (_) => const _ReadyScreen(),
        loading: () => const _SplashScreen(),
        error: (err, stack) => _ErrorScreen(error: err),
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

// ── Ready (temporary — replace with GoRouter shell) ─
class _ReadyScreen extends ConsumerWidget {
  const _ReadyScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(categoryCountsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: counts.when(
            data: (map) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quotesy',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${map.values.fold(0, (a, b) => a + b)} curated quotes loaded.',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
                const SizedBox(height: 32),
                ...QuoteCategory.all.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 15)),
                        Text('${map[cat] ?? 0}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e',
                style: const TextStyle(color: Colors.redAccent)),
          ),
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