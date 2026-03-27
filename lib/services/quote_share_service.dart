import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quote.dart';
import '../widgets/share_quote_card.dart';

Future<void> shareQuoteImage(
  BuildContext context,
  Quote quote, {
  double mobilePixelRatio = 3.0,
}) async {
  final screenshotController = ScreenshotController();

  try {
    final fileName = 'quotesy_${quote.id}';
    final imageBytes = await screenshotController.captureFromWidget(
      InheritedTheme.captureAll(
        context,
        MediaQuery(
          data: MediaQuery.of(context),
          child: Directionality(
            textDirection: Directionality.of(context),
            child: SizedBox(
              width: 1080,
              height: 1920,
              child: ShareQuoteCard(quote: quote),
            ),
          ),
        ),
      ),
      delay: const Duration(milliseconds: 40),
      pixelRatio: kIsWeb ? 2.0 : mobilePixelRatio,
    );

    final file = XFile.fromData(
      imageBytes,
      mimeType: 'image/png',
      name: '$fileName.png',
    );

    await SharePlus.instance.share(
      ShareParams(
        text: ' ${quote.author}',
        files: [file],
        fileNameOverrides: ['$fileName.png'],
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share quote right now.')),
      );
    }
  }
}
