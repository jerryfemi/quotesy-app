import 'package:flutter/material.dart';

import '../models/quote.dart';
import '../theme/quotesy_theme.dart';

class ShareQuoteCard extends StatelessWidget {
  final Quote quote;

  const ShareQuoteCard({
    super.key,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: QColors.obsidian,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '"${quote.text}"',
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium,
            ),
            const SizedBox(height: 28),
            Container(width: 40, height: 1, color: QColors.divider),
            const SizedBox(height: 20),
            Text(
              quote.author.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge,
            ),
            if (quote.sourceSection?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                quote.sourceSection!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: QColors.textSubtle,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
