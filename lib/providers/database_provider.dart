import 'package:flutter_riverpod/flutter_riverpod.dart';
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


/// Shuffled batch of 100 quotes for the Home infinite swipe.
final randomFeedProvider = FutureProvider<List<Quote>>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final service = ref.read(databaseServiceProvider);
  return service.getRandomFeed(limit: 100);
});

/// All quotes — for search screens
final allQuotesProvider = FutureProvider<List<Quote>>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final service = ref.read(databaseServiceProvider);
  return service.getAllQuotes();
});

/// Quotes by category — for the Explore screen category drill-down.
final quotesByCategoryProvider =
    FutureProvider.family<List<Quote>, String>((ref, category) async {
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

final savedQuotesProvider = AsyncNotifierProvider<SavedQuotesNotifier, List<Quote>>(
  SavedQuotesNotifier.new,
);