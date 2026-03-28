import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../services/database_service.dart';
import '../theme/quotesy_theme.dart';
import 'quotesy_nav_bar.dart';

Future<void> showFeedFilterSheet(BuildContext context, WidgetRef ref) async {
  final nav = NavBarControllerScope.of(context);
  nav.hide();

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 190),
        reverseDuration: Duration(milliseconds: 170),
      ),
      builder: (_) => const FeedFilterSheet(),
    );
  } finally {
    nav.show();
    await ref.read(feedPreferencesProvider.notifier).flushNow();
  }
}

class FeedFilterSheet extends ConsumerStatefulWidget {
  const FeedFilterSheet({super.key});

  @override
  ConsumerState<FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends ConsumerState<FeedFilterSheet> {
  static const double _collapsedSnap = 0.52;
  static const double _expandedSnap = 0.85;

  final Set<String> _expandedCategories = <String>{};

  @override
  Widget build(BuildContext context) {
    final topAuthorsByCategory = <String, List<String>>{};
    final loadingCategories = <String>{};
    for (final category in QuoteCategory.all) {
      final asyncAuthors = ref.watch(topAuthorsByCategoryProvider(category));
      topAuthorsByCategory[category] = asyncAuthors.maybeWhen(
        data: (value) => value,
        orElse: () => const <String>[],
      );
      if (asyncAuthors.isLoading) {
        loadingCategories.add(category);
      }
    }

    final prefsState = ref
        .watch(feedPreferencesProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => FeedPreferencesState.empty,
        );

    final categoryCounts = ref
        .watch(categoryCountsProvider)
        .maybeWhen(data: (value) => value, orElse: () => const <String, int>{});

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _collapsedSnap,
      minChildSize: _collapsedSnap,
      maxChildSize: _expandedSnap,
      snap: true,
      snapSizes: const [_collapsedSnap, _expandedSnap],
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: QColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Text(
                      'Your Feed',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() => _expandedCategories.clear());
                        ref.read(feedPreferencesProvider.notifier).reset();
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: QColors.amberGlow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  'Choose categories, then expand any category to refine by author.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: QColors.textSubtle,
                    height: 1.35,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  itemCount: QuoteCategory.all.length,
                  itemBuilder: (context, index) {
                    final category = QuoteCategory.all[index];
                    final isSelected = prefsState.selectedCategories.contains(
                      category,
                    );
                    final isExpanded = _expandedCategories.contains(category);
                    final count = categoryCounts[category] ?? 0;
                    final topAuthors =
                        topAuthorsByCategory[category] ?? const <String>[];
                    final authorsLoading = loadingCategories.contains(category);

                    final selectedSubset = prefsState.selectedAuthors[category];
                    final selectedAuthors = !isSelected
                        ? <String>{}
                        : (selectedSubset == null
                              ? topAuthors.toSet()
                              : selectedSubset.toSet());

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.fromLTRB(10, 4, 8, 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.white.withValues(alpha: 0.04),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _CategoryRow(
                              category: category,
                              quoteCount: count,
                              isSelected: isSelected,
                              isExpanded: isExpanded,
                              onToggleCategory: () =>
                                  _toggleCategory(prefsState, category),
                              onToggleExpanded: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedCategories.remove(category);
                                  } else {
                                    _expandedCategories.add(category);
                                  }
                                });
                              },
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: isExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        34,
                                        6,
                                        0,
                                        2,
                                      ),
                                      child: authorsLoading
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: QColors.textSubtle,
                                                    ),
                                              ),
                                            )
                                          : topAuthors.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: Text(
                                                'No high-frequency authors in this category yet.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: QColors.textSubtle,
                                                ),
                                              ),
                                            )
                                          : Column(
                                              children: topAuthors
                                                  .map(
                                                    (author) => _AuthorRow(
                                                      author: author,
                                                      isSelected:
                                                          selectedAuthors
                                                              .contains(author),
                                                      onToggle: () =>
                                                          _toggleAuthor(
                                                            prefsState,
                                                            category,
                                                            topAuthors,
                                                            author,
                                                          ),
                                                    ),
                                                  )
                                                  .toList(growable: false),
                                            ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleCategory(FeedPreferencesState state, String category) {
    HapticFeedback.selectionClick();

    final categories = state.selectedCategories.toSet();
    final selectedAuthors = Map<String, List<String>>.from(
      state.selectedAuthors,
    );

    if (categories.contains(category)) {
      categories.remove(category);
      selectedAuthors.remove(category);
    } else {
      categories.add(category);
      // Compact mode: all authors selected is implied by missing map entry.
      selectedAuthors.remove(category);
    }

    ref
        .read(feedPreferencesProvider.notifier)
        .setAll(
          selectedCategories: categories.toList(growable: false),
          selectedAuthors: selectedAuthors,
        );
  }

  void _toggleAuthor(
    FeedPreferencesState state,
    String category,
    List<String> topAuthors,
    String author,
  ) {
    HapticFeedback.selectionClick();

    final categories = state.selectedCategories.toSet()..add(category);
    final selectedAuthors = Map<String, List<String>>.from(
      state.selectedAuthors,
    );

    final currentSubset = selectedAuthors[category];
    final effective = currentSubset != null
        ? currentSubset.toSet()
        : (state.selectedCategories.contains(category)
              ? topAuthors.toSet()
              : <String>{});

    if (effective.contains(author)) {
      effective.remove(author);
    } else {
      effective.add(author);
    }

    if (effective.isEmpty) {
      categories.remove(category);
      selectedAuthors.remove(category);
      setState(() => _expandedCategories.remove(category));
    } else if (effective.length == topAuthors.length) {
      // Compact mode: all selected => remove explicit subset.
      selectedAuthors.remove(category);
    } else {
      final sorted = effective.toList(growable: false)..sort();
      selectedAuthors[category] = sorted;
    }

    ref
        .read(feedPreferencesProvider.notifier)
        .setAll(
          selectedCategories: categories.toList(growable: false),
          selectedAuthors: selectedAuthors,
        );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final int quoteCount;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onToggleCategory;
  final VoidCallback onToggleExpanded;

  const _CategoryRow({
    required this.category,
    required this.quoteCount,
    required this.isSelected,
    required this.isExpanded,
    required this.onToggleCategory,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onToggleCategory,
          child: _CircleCheck(isChecked: isSelected),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onToggleCategory,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$quoteCount quotes',
                    style: const TextStyle(
                      fontSize: 12,
                      color: QColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onToggleExpanded,
          icon: AnimatedRotation(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            turns: isExpanded ? 0.25 : 0,
            child: const Icon(
              Icons.chevron_right_rounded,
              color: QColors.textSubtle,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthorRow extends StatelessWidget {
  final String author;
  final bool isSelected;
  final VoidCallback onToggle;

  const _AuthorRow({
    required this.author,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: _CircleCheck(isChecked: isSelected),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  author,
                  style: const TextStyle(
                    fontSize: 13,
                    color: QColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleCheck extends StatelessWidget {
  final bool isChecked;

  const _CircleCheck({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isChecked ? QColors.amberGlow : Colors.transparent,
        border: Border.all(
          color: isChecked
              ? QColors.amberGlow
              : Colors.white.withValues(alpha: 0.30),
          width: 1.2,
        ),
      ),
      child: isChecked
          ? const Center(
              child: Icon(Icons.check, size: 14, color: Colors.white),
            )
          : null,
    );
  }
}
