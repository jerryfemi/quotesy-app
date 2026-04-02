import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import 'routes/app_router.dart';
import 'theme/quotesy_theme.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

final screenshotControllerProvider = Provider((ref) => ScreenshotController());

Future<void> main() async {
  // Essential for app startup
  WidgetsFlutterBinding.ensureInitialized();

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

class QuotesyApp extends ConsumerStatefulWidget {
  const QuotesyApp({super.key});

  @override
  ConsumerState<QuotesyApp> createState() => _QuotesyAppState();
}

class _QuotesyAppState extends ConsumerState<QuotesyApp> {
  @override
  void initState() {
    super.initState();
    // Use a global hardware listener to bypass focus issues in Device Preview
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    super.dispose();
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (kDebugMode &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyS) {
      _takeScreenshot();
      return true; // Consume the event
    }
    return false;
  }

  Future<void> _takeScreenshot() async {
    try {
      final controller = ref.read(screenshotControllerProvider);
      final bytes = await controller.capture(
        delay: const Duration(milliseconds: 100),
      );

      if (bytes != null) {
        final fileName = 'quotesy_${DateTime.now().millisecondsSinceEpoch}.png';

        if (kIsWeb) {
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          debugPrint('[Screenshot] Saved to device: $fileName');
        } else {
          final file = XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: fileName,
          );
          await SharePlus.instance.share(
            ShareParams(
              files: [file],
              fileNameOverrides: [fileName],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Screenshot] Capture failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quotesy',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        final previewChild = DevicePreview.appBuilder(context, child);
        return Screenshot(
          controller: ref.watch(screenshotControllerProvider),
          child: previewChild,
        );
      },
      theme: darkMode,
      routerConfig: routerProvider,
    );
  }
}
