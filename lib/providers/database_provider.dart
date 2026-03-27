import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/quote.dart';
import '../services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final databaseInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(databaseServiceProvider);
  await service.init();
  await service.ensureInitialImport();
});

class FeedPreferencesState {
  final List<String> selectedCategories;
  final Map<String, List<String>> selectedAuthors;

  const FeedPreferencesState({
    required this.selectedCategories,
    required this.selectedAuthors,
  });

  bool get hasActiveFilters =>
      selectedCategories.isNotEmpty || selectedAuthors.isNotEmpty;

  FeedPreferencesState copyWith({
    List<String>? selectedCategories,
    Map<String, List<String>>? selectedAuthors,
  }) {
    return FeedPreferencesState(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedAuthors: selectedAuthors ?? this.selectedAuthors,
    );
  }

  static const empty = FeedPreferencesState(
    selectedCategories: [],
    selectedAuthors: {},
  );
}

class FeedPreferencesNotifier extends AsyncNotifier<FeedPreferencesState> {
  Timer? _writeDebounce;

  FeedPreferencesState _currentState() {
    return state.maybeWhen(
      data: (value) => value,
      orElse: () => FeedPreferencesState.empty,
    );
  }

  @override
  Future<FeedPreferencesState> build() async {
    ref.onDispose(() {
      _writeDebounce?.cancel();
    });

    await ref.watch(databaseInitProvider.future);
    final service = ref.read(databaseServiceProvider);
    return FeedPreferencesState(
      selectedCategories: service.getSelectedCategories(),
      selectedAuthors: service.getSelectedAuthors(),
    );
  }

  void setSelectedCategories(List<String> categories) {
    final current = _currentState();
    final cleanedCategories = categories.toSet().toList()..sort();

    final cleanedAuthors = <String, List<String>>{};
    for (final category in cleanedCategories) {
      final existing = current.selectedAuthors[category];
      if (existing != null && existing.isNotEmpty) {
        cleanedAuthors[category] = [...existing]..sort();
      }
    }

    final next = current.copyWith(
      selectedCategories: cleanedCategories,
      selectedAuthors: cleanedAuthors,
    );
    state = AsyncData(next);
    _schedulePersist(next);
  }

  void setSelectedAuthors(Map<String, List<String>> selectedAuthors) {
    final current = _currentState();

    final cleanedAuthors = <String, List<String>>{};
    selectedAuthors.forEach((category, authors) {
      final cleaned = authors.toSet().toList()..sort();
      if (cleaned.isNotEmpty) {
        cleanedAuthors[category] = cleaned;
      }
    });

    final categories = current.selectedCategories.toSet();
    categories.addAll(cleanedAuthors.keys);

    final next = current.copyWith(
      selectedCategories: categories.toList()..sort(),
      selectedAuthors: cleanedAuthors,
    );
    state = AsyncData(next);
    _schedulePersist(next);
  }

  void setAll({
    required List<String> selectedCategories,
    required Map<String, List<String>> selectedAuthors,
    bool immediate = false,
  }) {
    final cleanedCategories = selectedCategories.toSet().toList()..sort();
    final cleanedAuthors = <String, List<String>>{};

    selectedAuthors.forEach((category, authors) {
      if (!cleanedCategories.contains(category)) return;
      final cleaned = authors.toSet().toList()..sort();
      if (cleaned.isNotEmpty) {
        cleanedAuthors[category] = cleaned;
      }
    });

    final next = FeedPreferencesState(
      selectedCategories: cleanedCategories,
      selectedAuthors: cleanedAuthors,
    );
    state = AsyncData(next);
    if (immediate) {
      unawaited(flushNow());
    } else {
      _schedulePersist(next);
    }
  }

  void reset() {
    final next = FeedPreferencesState.empty;
    state = const AsyncData(FeedPreferencesState.empty);
    _schedulePersist(next);
  }

  Future<void> flushNow() async {
    _writeDebounce?.cancel();
    final current = state.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    if (current == null) {
      return;
    }
    final service = ref.read(databaseServiceProvider);
    await service.setSelectedCategories(current.selectedCategories);
    await service.setSelectedAuthors(current.selectedAuthors);
  }

  void _schedulePersist(FeedPreferencesState value) {
    _writeDebounce?.cancel();
    _writeDebounce = Timer(const Duration(milliseconds: 300), () async {
      final service = ref.read(databaseServiceProvider);
      await service.setSelectedCategories(value.selectedCategories);
      await service.setSelectedAuthors(value.selectedAuthors);
    });
  }
}

final feedPreferencesProvider =
    AsyncNotifierProvider<FeedPreferencesNotifier, FeedPreferencesState>(
      FeedPreferencesNotifier.new,
    );

/// Filtered feed for Home. Uses persisted feed preferences.
final filteredFeedProvider = FutureProvider<List<Quote>>((ref) async {
  await ref.watch(databaseInitProvider.future);
  // Watching this makes the feed reactively rebuild when preferences change.
  ref.watch(feedPreferencesProvider);

  final service = ref.read(databaseServiceProvider);
  return service.getFilteredFeed();
});

final topAuthorsByCategoryProvider =
    FutureProvider.family<List<String>, String>((ref, category) async {
      await ref.watch(databaseInitProvider.future);
      final service = ref.read(databaseServiceProvider);
      return service.getTopAuthorsByCategory(category);
    });

/// All quotes — for search screens
final allQuotesProvider = FutureProvider<List<Quote>>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final service = ref.read(databaseServiceProvider);
  return service.getAllQuotes();
});

/// Quotes by category — for the Explore screen category drill-down.
final quotesByCategoryProvider = FutureProvider.family<List<Quote>, String>((
  ref,
  category,
) async {
  await ref.watch(databaseInitProvider.future);
  final service = ref.read(databaseServiceProvider);
  return service.getQuotesByCategory(category);
});

/// Category counts — for UI badges on Explore cards.
final categoryCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final service = ref.read(databaseServiceProvider);
  return service.getCategoryCounts();
});

class SavedQuotesNotifier extends AsyncNotifier<List<Quote>> {
  @override
  Future<List<Quote>> build() async {
    await ref.watch(databaseInitProvider.future);
    return ref.read(databaseServiceProvider).getSavedQuotes();
  }

  Future<void> toggle(String quoteId) async {
    final service = ref.read(databaseServiceProvider);
    await service.toggleBookmark(quoteId);
    state = AsyncData(service.getSavedQuotes());
  }

  bool isBookmarked(String quoteId) {
    return ref.read(databaseServiceProvider).isBookmarked(quoteId);
  }
}

final savedQuotesProvider =
    AsyncNotifierProvider<SavedQuotesNotifier, List<Quote>>(
      SavedQuotesNotifier.new,
    );
