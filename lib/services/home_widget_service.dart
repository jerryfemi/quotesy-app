import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/quote.dart';
import 'database_service.dart';

const _widgetProviderName = 'QuotesyHomeWidgetProvider';
const _widgetPoolKey = 'quotesy_widget_pool_v1';
const _widgetIndexKey = 'quotesy_widget_index_v1';
const _widgetQuoteKey = 'quotesy_widget_quote_v1';
const _widgetAuthorKey = 'quotesy_widget_author_v1';
const _widgetPoolSize = 24;
const _widgetFetchSize = 100;
const _widgetPreferredMaxChars = 140;

Future<void> refreshQuotesyHomeWidget(DatabaseService service) async {
  if (kIsWeb || !Platform.isAndroid) return;

  final candidates = service.getRandomFeed(limit: _widgetFetchSize);
  final preferred = candidates
      .where((q) => q.text.trim().length <= _widgetPreferredMaxChars)
      .toList(growable: false);

  // Build the final pool from short-form quotes first, then backfill.
  final selected = <Quote>[];
  final seenIds = <String>{};

  for (final quote in preferred) {
    if (seenIds.add(quote.id)) {
      selected.add(quote);
      if (selected.length >= _widgetPoolSize) break;
    }
  }

  if (selected.length < _widgetPoolSize) {
    for (final quote in candidates) {
      if (seenIds.add(quote.id)) {
        selected.add(quote);
        if (selected.length >= _widgetPoolSize) break;
      }
    }
  }

  final feed = selected;
  debugPrint(
    '[HomeWidget] Refresh start (poolCandidates=${feed.length}, appGroup=com.jerryfemi.quotesy)',
  );
  if (feed.isEmpty) {
    await HomeWidget.saveWidgetData<String>(_widgetPoolKey, null);
    await HomeWidget.saveWidgetData<int>(_widgetIndexKey, null);
    await HomeWidget.saveWidgetData<String>(
      _widgetQuoteKey,
      'Open Quotesy to load your first quote.',
    );
    await HomeWidget.saveWidgetData<String>(_widgetAuthorKey, 'QUOTESY');
    await HomeWidget.updateWidget(androidName: _widgetProviderName);
    debugPrint('[HomeWidget] Refresh complete (fallback content written)');
    return;
  }

  final pool = feed
      .map((quote) => {'text': quote.text, 'author': quote.author})
      .toList(growable: false);

  await HomeWidget.saveWidgetData<String>(_widgetPoolKey, jsonEncode(pool));
  // -1 lets the provider increment to 0 on the next refresh/update.
  await HomeWidget.saveWidgetData<int>(_widgetIndexKey, -1);
  await HomeWidget.saveWidgetData<String>(_widgetQuoteKey, pool.first['text']);
  await HomeWidget.saveWidgetData<String>(
    _widgetAuthorKey,
    pool.first['author'],
  );

  await HomeWidget.updateWidget(androidName: _widgetProviderName);
  debugPrint('[HomeWidget] Refresh complete (poolSize=${pool.length})');
}
