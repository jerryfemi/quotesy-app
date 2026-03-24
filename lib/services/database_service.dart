import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/quote.dart';

// ─────────────────────────────────────────────
// Box names & keys — single source of truth
// ─────────────────────────────────────────────
const _quotesBoxName = 'quotes_box';
const _savedBoxName = 'saved_box';
const _settingsBoxName = 'settings_box';
const _importCompleteKey = 'import_v2_complete'; 
const _categoryIndexKey = 'category_index';


class QuoteCategory {
  static const existential = 'Existential';
  static const warAndEpic = 'War & Epic';
  static const psychologyAndSelf = 'Psychology & Self';
  static const witAndWisdom = 'Wit & Wisdom';
  static const spiritualityAndFaith = 'Spirituality & Faith';
  static const loveAndYearning = 'Love & Yearning';

  static const all = [
    existential,
    warAndEpic,
    psychologyAndSelf,
    witAndWisdom,
    spiritualityAndFaith,
    loveAndYearning,
  ];
}

// Isolate payload — passed via compute()
class _ParseResult {
  final Map<String, Quote> quoteMap;
  final Map<String, List<String>> categoryIndex;

  _ParseResult({required this.quoteMap, required this.categoryIndex});
}

/// Top-level function required by compute() — must not be a class method.
_ParseResult _parseQuotesInIsolate(String jsonString) {
  final List<dynamic> jsonData = json.decode(jsonString);
  final Map<String, Quote> quoteMap = {};
  final Map<String, List<String>> categoryIndex = {};

  for (final item in jsonData) {
    final quote = Quote.fromJson(item as Map<String, dynamic>);
    quoteMap[quote.id] = quote;

    // Build the category → [ids] index in the same pass. Zero extra cost.
    categoryIndex.putIfAbsent(quote.category, () => []).add(quote.id);
  }

  return _ParseResult(quoteMap: quoteMap, categoryIndex: categoryIndex);
}

// DatabaseService
class DatabaseService {
  bool _isInitialized = false;

  Box<Quote> get _quotesBox {
    assert(_isInitialized, 'DatabaseService.init() must be awaited before accessing boxes.');
    return Hive.box<Quote>(_quotesBoxName);
  }

  Box<String> get _savedBox {
    assert(_isInitialized, 'DatabaseService.init() must be awaited before accessing boxes.');
    return Hive.box<String>(_savedBoxName);
  }

  Box get _settingsBox {
    assert(_isInitialized, 'DatabaseService.init() must be awaited before accessing boxes.');
    return Hive.box(_settingsBoxName);
  }

  // ── 1. INITIALIZATION 
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(QuoteAdapter());
    }

    await Future.wait([
      Hive.openBox<Quote>(_quotesBoxName),
      Hive.openBox<String>(_savedBoxName),
      Hive.openBox(_settingsBoxName),
    ]);

    _isInitialized = true;
  }

  // ── 2. ZERO-JANK IMPORT 
  Future<void> ensureInitialImport() async {
    final bool isImported = _settingsBox.get(_importCompleteKey, defaultValue: false);
    if (isImported) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/quotes.json');

     
      final result = await compute(_parseQuotesInIsolate, jsonString);

      await _quotesBox.clear();
      await _quotesBox.putAll(result.quoteMap);

      // Persist the category index so getQuotesByCategory never scans again.
      await _settingsBox.put(
        _categoryIndexKey,
        json.encode(result.categoryIndex),
      );

      await _settingsBox.put(_importCompleteKey, true);

      debugPrint('✅ Imported ${result.quoteMap.length} quotes across '
          '${result.categoryIndex.keys.length} categories.');
    } catch (e, stack) {
      debugPrint('❌ Import failed: $e\n$stack');
      rethrow;
    }
  }

  // ── 3. CATEGORY INDEX ───────────────────────
  Map<String, List<String>> _getCategoryIndex() {
    final raw = _settingsBox.get(_categoryIndexKey) as String?;
    if (raw == null) return {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, List<String>.from(v as List)));
  }

  // ── 4. FEED GENERATORS ──────────────────────

  /// Shuffled batch for the infinite swipe home screen.
  List<Quote> getRandomFeed({int limit = 100}) {
    final quotes = _quotesBox.values.toList()..shuffle();
    return quotes.take(limit).toList();
  }

  /// All quotes — used for search or bulk operations.
  List<Quote> getAllQuotes() => _quotesBox.values.toList();

  /// O(1) category lookup via pre-built index.
  List<Quote> getQuotesByCategory(String category, {bool shuffle = true}) {
    final index = _getCategoryIndex();
    final ids = index[category] ?? [];

    final quotes = ids
        .map((id) => _quotesBox.get(id))
        .whereType<Quote>()
        .toList();

    if (shuffle) quotes.shuffle();
    return quotes;
  }

  /// Quick count per category — for UI badges, no objects loaded.
  Map<String, int> getCategoryCounts() {
    final index = _getCategoryIndex();
    return index.map((k, v) => MapEntry(k, v.length));
  }

  // ── 5. THE VAULT (Bookmarks) ─────────────────

  bool isBookmarked(String quoteId) => _savedBox.containsKey(quoteId);

  Future<void> toggleBookmark(String quoteId) async {
    if (_savedBox.containsKey(quoteId)) {
      await _savedBox.delete(quoteId);
    } else {
      await _savedBox.put(quoteId, quoteId);
    }
  }

  /// Returns saved quotes newest-first. O(n) on vault size, not total library.
  List<Quote> getSavedQuotes() {
    return  _savedBox.values
        .map((id) => _quotesBox.get(id))
        .whereType<Quote>()
        .toList()
        .reversed
        .toList();
  }

  int get vaultCount => _savedBox.length;
}