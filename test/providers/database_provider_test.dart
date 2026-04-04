
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotesy/models/quote.dart';
import 'package:quotesy/providers/database_provider.dart';
import 'package:quotesy/services/database_service.dart';

class _FakeDatabaseService extends DatabaseService {
  List<String> selectedCategories = <String>[];
  Map<String, List<String>> selectedAuthors = <String, List<String>>{};
  List<String> persistedCategories = <String>[];
  Map<String, List<String>> persistedAuthors = <String, List<String>>{};

  List<String> lastFilterCategories = <String>[];
  Map<String, List<String>> lastFilterAuthors = <String, List<String>>{};

  final List<Quote> _quotes = <Quote>[
    Quote(id: '1', text: 'A', author: 'Author A', category: 'Cat A'),
    Quote(id: '2', text: 'B', author: 'Author B', category: 'Cat B'),
  ];

  @override
  Future<void> init() async {}

  @override
  Future<void> ensureInitialImport() async {}

  @override
  List<String> getSelectedCategories() => selectedCategories;

  @override
  Map<String, List<String>> getSelectedAuthors() => selectedAuthors;

  @override
  Future<void> setSelectedCategories(List<String> categories) async {
    persistedCategories = List<String>.from(categories);
    selectedCategories = List<String>.from(categories);
  }

  @override
  Future<void> setSelectedAuthors(Map<String, List<String>> authors) async {
    persistedAuthors = authors.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    );
    selectedAuthors = authors.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    );
  }

  @override
  List<Quote> getFilteredFeed({
    required List<String> selectedCategories,
    required Map<String, List<String>> selectedAuthors,
  }) {
    lastFilterCategories = List<String>.from(selectedCategories);
    lastFilterAuthors = selectedAuthors.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    );

    if (selectedCategories.isEmpty) {
      return _quotes;
    }

    return _quotes
        .where((quote) => selectedCategories.contains(quote.category))
        .toList(growable: false);
  }
}

class _DelayedFeedPreferencesNotifier extends FeedPreferencesNotifier {
  @override
  Future<FeedPreferencesState> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    return const FeedPreferencesState(
      selectedCategories: <String>['Cat A'],
      selectedAuthors: <String, List<String>>{},
    );
  }
}

class _ErrorFeedPreferencesNotifier extends FeedPreferencesNotifier {
  @override
  Future<FeedPreferencesState> build() async {
    throw StateError('prefs failed');
  }
}

void main() {
  group('FeedPreferencesNotifier', () {
    test(
      'setAll cleans input and persists immediately when requested',
      () async {
        final fakeDb = _FakeDatabaseService()
          ..selectedCategories = <String>['Cat B']
          ..selectedAuthors = <String, List<String>>{
            'Cat B': <String>['Author B'],
          };

        final container = ProviderContainer(
          overrides: [databaseServiceProvider.overrideWithValue(fakeDb)],
        );
        addTearDown(container.dispose);

        await container.read(feedPreferencesProvider.future);
        final notifier = container.read(feedPreferencesProvider.notifier);

        notifier.setAll(
          selectedCategories: <String>['Cat A', 'Cat A', 'Cat B'],
          selectedAuthors: <String, List<String>>{
            'Cat B': <String>['Author Z', 'Author A', 'Author A'],
            'Cat C': <String>['Ignored'],
          },
          immediate: true,
        );

        await Future<void>.delayed(const Duration(milliseconds: 20));
        final state = await container.read(feedPreferencesProvider.future);

        expect(state.selectedCategories, <String>['Cat A', 'Cat B']);
        expect(state.selectedAuthors, <String, List<String>>{
          'Cat B': <String>['Author A', 'Author Z'],
        });
        expect(fakeDb.persistedCategories, <String>['Cat A', 'Cat B']);
        expect(fakeDb.persistedAuthors, <String, List<String>>{
          'Cat B': <String>['Author A', 'Author Z'],
        });
      },
    );
  });

  group('filteredFeedProvider', () {
    test(
      'waits for feedPreferencesProvider.future before querying feed',
      () async {
        final fakeDb = _FakeDatabaseService();

        final container = ProviderContainer(
          overrides: [
            databaseServiceProvider.overrideWithValue(fakeDb),
            feedPreferencesProvider.overrideWith(
              _DelayedFeedPreferencesNotifier.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(filteredFeedProvider, (_, _) {});
        expect(sub.read().isLoading, true);
        expect(fakeDb.lastFilterCategories, isEmpty);

        await Future<void>.delayed(const Duration(milliseconds: 60));

        final value = container.read(filteredFeedProvider);
        expect(value.hasValue, true);
        expect(fakeDb.lastFilterCategories, <String>['Cat A']);
        expect(fakeDb.lastFilterAuthors, <String, List<String>>{});
      },
    );

    test('propagates feed preference loading errors', () async {
      final fakeDb = _FakeDatabaseService();

      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(fakeDb),
          feedPreferencesProvider.overrideWith(
            _ErrorFeedPreferencesNotifier.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(filteredFeedProvider, (_, _) {});
      expect(sub.read().isLoading, true);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final value = container.read(filteredFeedProvider);
      expect(value.hasError, true);
      expect(fakeDb.lastFilterCategories, isEmpty);
      expect(fakeDb.lastFilterAuthors, isEmpty);
    });
  });
}
