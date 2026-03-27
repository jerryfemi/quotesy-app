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
const _preferencesBoxName = 'preferences_box';
const _importCompleteKey = 'import_v3_complete';
const _categoryIndexKey = 'category_index_v3';
const _selectedCategoriesKey = 'selected_categories_v1';
const _selectedAuthorsKey = 'selected_authors_v1';
const _homeGestureHintSeenKey = 'home_gesture_hint_seen_v1';

class QuoteCategory {
  static const existential = 'Existential';
  static const warAndEpic = 'War & Epic';
  static const psychologyAndSelf = 'Psychology & Self';
  static const witAndWisdom = 'Wit & Wisdom';
  static const spiritualityAndFaith = 'Spirituality & Faith';
  static const loveAndYearning = 'Love & Yearning';

  static const all = [
    psychologyAndSelf,
    existential,
    loveAndYearning,
    witAndWisdom,
    spiritualityAndFaith,
    warAndEpic,
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
  final Map<String, int> idOccurrences = {};

  for (final item in jsonData) {
    final parsedQuote = Quote.fromJson(item as Map<String, dynamic>);
    final rawId = parsedQuote.id;
    final occurrence = (idOccurrences[rawId] ?? 0) + 1;
    idOccurrences[rawId] = occurrence;

    final storageId = occurrence == 1 ? rawId : '$rawId#$occurrence';
    final quote = Quote(
      id: storageId,
      text: parsedQuote.text,
      author: parsedQuote.author,
      category: parsedQuote.category,
      source: parsedQuote.source,
      sourceSection: parsedQuote.sourceSection,
    );

    quoteMap[storageId] = quote;

    // Build the category → [ids] index in the same pass. Zero extra cost.
    categoryIndex.putIfAbsent(quote.category, () => []).add(storageId);
  }

  return _ParseResult(quoteMap: quoteMap, categoryIndex: categoryIndex);
}

// DatabaseService
class DatabaseService {
  bool _isInitialized = false;
  int? _cachedFilteredSignature;
  List<Quote>? _cachedFilteredFeed;
  final Map<String, List<String>> _topAuthorsCache = {};
  static const int _topAuthorsMinQuotes = 10;
  static const int _topAuthorsMax = 10;

  Box<Quote> get _quotesBox {
    assert(
      _isInitialized,
      'DatabaseService.init() must be awaited before accessing boxes.',
    );
    return Hive.box<Quote>(_quotesBoxName);
  }

  Box<String> get _savedBox {
    assert(
      _isInitialized,
      'DatabaseService.init() must be awaited before accessing boxes.',
    );
    return Hive.box<String>(_savedBoxName);
  }

  Box get _settingsBox {
    assert(
      _isInitialized,
      'DatabaseService.init() must be awaited before accessing boxes.',
    );
    return Hive.box(_settingsBoxName);
  }

  Box get _preferencesBox {
    assert(
      _isInitialized,
      'DatabaseService.init() must be awaited before accessing boxes.',
    );
    return Hive.box(_preferencesBoxName);
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
      Hive.openBox(_preferencesBoxName),
    ]);

    _isInitialized = true;
  }

  // ── 2. ZERO-JANK IMPORT
  Future<void> ensureInitialImport() async {
    final bool isImported = _settingsBox.get(
      _importCompleteKey,
      defaultValue: false,
    );
    if (isImported) return;

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/quotes.json',
      );

      final result = await compute(_parseQuotesInIsolate, jsonString);

      await _quotesBox.clear();
      await _savedBox.clear();
      await _quotesBox.putAll(result.quoteMap);

      // Persist the category index so getQuotesByCategory never scans again.
      await _settingsBox.put(
        _categoryIndexKey,
        json.encode(result.categoryIndex),
      );

      await _settingsBox.put(_importCompleteKey, true);

      debugPrint(
        '✅ Imported ${result.quoteMap.length} quotes across '
        '${result.categoryIndex.keys.length} categories.',
      );
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

  // ── 5. FEED PREFERENCES ─────────────────────

  List<String> getSelectedCategories() {
    final raw = _preferencesBox.get(_selectedCategoriesKey);
    if (raw is List) {
      return raw
          .whereType<String>()
          .map((category) => category.trim())
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    }
    return const [];
  }

  Map<String, List<String>> getSelectedAuthors() {
    final raw = _preferencesBox.get(_selectedAuthorsKey) as String?;
    if (raw == null || raw.isEmpty) return const {};

    final decoded = json.decode(raw) as Map<String, dynamic>;
    final mapped = decoded.map(
      (category, authors) => MapEntry(
        category,
        List<String>.from(authors as List)
            .map((author) => author.trim())
            .where((author) => author.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
      ),
    );

    mapped.removeWhere((_, authors) => authors.isEmpty);
    return mapped;
  }

  Future<void> setSelectedCategories(List<String> categories) async {
    final normalized = categories
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    await _preferencesBox.put(_selectedCategoriesKey, normalized);
    _invalidateFilteredFeedCache();
  }

  Future<void> setSelectedAuthors(Map<String, List<String>> selectedAuthors) async {
    final normalized = <String, List<String>>{};

    selectedAuthors.forEach((category, authors) {
      final cleaned = authors
          .map((author) => author.trim())
          .where((author) => author.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (cleaned.isNotEmpty) {
        normalized[category] = cleaned;
      }
    });

    final encoded = json.encode(normalized);
    await _preferencesBox.put(_selectedAuthorsKey, encoded);
    _invalidateFilteredFeedCache();
  }

  bool hasSeenHomeGestureHint() {
    return _preferencesBox.get(_homeGestureHintSeenKey, defaultValue: false) ==
        true;
  }

  Future<void> setHomeGestureHintSeen([bool seen = true]) async {
    await _preferencesBox.put(_homeGestureHintSeenKey, seen);
  }

  List<String> getTopAuthorsByCategory(String category) {
    final cached = _topAuthorsCache[category];
    if (cached != null) {
      return cached;
    }

    final index = _getCategoryIndex();
    final ids = index[category] ?? const <String>[];
    final counts = <String, int>{};

    for (final id in ids) {
      final quote = _quotesBox.get(id);
      if (quote == null) continue;
      counts.update(quote.author, (count) => count + 1, ifAbsent: () => 1);
    }

    final filtered = counts.entries
        .where((entry) => entry.value >= _topAuthorsMinQuotes)
        .toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });

    final result = filtered
      .take(_topAuthorsMax)
      .map((entry) => entry.key)
      .toList(growable: false);

    _topAuthorsCache[category] = result;
    return result;
  }

  List<Quote> getFilteredFeed({
    required List<String> selectedCategories,
    required Map<String, List<String>> selectedAuthors,
  }) {
    final normalizedCategories = selectedCategories
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();

    final normalizedAuthors = <String, List<String>>{};
    selectedAuthors.forEach((category, authors) {
      final cleaned = authors
          .map((author) => author.trim())
          .where((author) => author.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort();

      if (cleaned.isNotEmpty) {
        normalizedAuthors[category] = cleaned;
      }
    });

    final hasCategorySelections = normalizedCategories.isNotEmpty;
    final hasAuthorSelections = normalizedAuthors.isNotEmpty;

    // Empty selection means "show all" (shuffled), not a single default category.
    if (!hasCategorySelections && !hasAuthorSelections) {
      return _quotesBox.values.toList()..shuffle();
    }

    final effectiveCategories = hasCategorySelections
      ? normalizedCategories
        : hasAuthorSelections
        ? normalizedAuthors.keys.toList(growable: false)
            : const <String>[];

    final signature = _buildFilterSignature(effectiveCategories, normalizedAuthors);
    if (_cachedFilteredSignature == signature && _cachedFilteredFeed != null) {
      return _cachedFilteredFeed!;
    }

    final categoryIndex = _getCategoryIndex();

    final filtered = <Quote>[];
    for (final category in effectiveCategories) {
      final ids = categoryIndex[category] ?? const <String>[];
      final authorSubset = normalizedAuthors[category];

      for (final id in ids) {
        final quote = _quotesBox.get(id);
        if (quote == null) continue;

        if (authorSubset != null && authorSubset.isNotEmpty) {
          if (!authorSubset.contains(quote.author)) continue;
        }

        filtered.add(quote);
      }
    }

    filtered.shuffle();
    _cachedFilteredSignature = signature;
    _cachedFilteredFeed = filtered;
    return filtered;
  }

  void _invalidateFilteredFeedCache() {
    _cachedFilteredSignature = null;
    _cachedFilteredFeed = null;
  }

  int _buildFilterSignature(
    List<String> selectedCategories,
    Map<String, List<String>> selectedAuthors,
  ) {
    final sortedCategories = [...selectedCategories]..sort();
    final parts = <Object>[...sortedCategories];
    final keys = selectedAuthors.keys.toList()..sort();

    for (final key in keys) {
      final authors = [...selectedAuthors[key] ?? const <String>[]]..sort();
      if (authors.isNotEmpty) {
        parts.add(key);
        parts.addAll(authors);
      }
    }

    return Object.hashAll(parts);
  }

  // ── 6. THE VAULT (Bookmarks) ─────────────────

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
    return _savedBox.values
        .map((id) => _quotesBox.get(id))
        .whereType<Quote>()
        .toList()
        .reversed
        .toList();
  }

  int get vaultCount => _savedBox.length;
}
