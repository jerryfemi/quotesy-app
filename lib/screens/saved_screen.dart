import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote.dart';
import '../providers/database_provider.dart';
import '../services/database_service.dart';
import '../theme/quotesy_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Filter tab definition — fixed list, always shown in this order.
// ─────────────────────────────────────────────────────────────────────────────
class _FilterTab {
  final String label;
  final String? category; // null = "All Saved"
  const _FilterTab(this.label, this.category);
}

const _tabs = [
  _FilterTab('ALL SAVED', null),
  _FilterTab('PHILOSOPHY', QuoteCategory.existential),
  _FilterTab('POETRY', QuoteCategory.loveAndYearning),
  _FilterTab('PSYCHOLOGY', QuoteCategory.psychologyAndSelf),
  _FilterTab('WAR & EPIC', QuoteCategory.warAndEpic),
  _FilterTab('WIT & WISDOM', QuoteCategory.witAndWisdom),
  _FilterTab('FAITH', QuoteCategory.spiritualityAndFaith),
];

// ─────────────────────────────────────────────────────────────────────────────
// SavedScreen
// ─────────────────────────────────────────────────────────────────────────────
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  int _activeTabIndex = 0;

  List<Quote> _filtered(List<Quote> all) {
    final category = _tabs[_activeTabIndex].category;
    if (category == null) return all;
    return all.where((q) => q.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final savedAsync = ref.watch(savedQuotesProvider);

    return Scaffold(
      backgroundColor: QColors.obsidian,
      body: SafeArea(
        child: savedAsync.when(
          loading: () => const SizedBox.shrink(), // local-first, never shows
          error: (e, _) => Center(
            child: Text('$e',
                style: const TextStyle(color: QColors.textGhost)),
          ),
          data: (quotes) {
            final filtered = _filtered(quotes);
            return CustomScrollView(
              slivers: [
                // ── HEADER ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _Header(
                    onSearch: () {
                      // TODO: search
                    },
                  ),
                ),

                // ── FILTER TABS ────────────────────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    activeIndex: _activeTabIndex,
                    onTap: (i) => setState(() => _activeTabIndex = i),
                  ),
                ),

                // ── QUOTE LIST or EMPTY STATE ──────────────────────────────
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      isFiltered: _tabs[_activeTabIndex].category != null,
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _SavedQuoteCard(
                        key: ValueKey(filtered[i].id),
                        quote: filtered[i],
                        index: i,
                      ),
                    ),
                  ),

                  // ── END OF ARCHIVE ───────────────────────────────────────
                  const SliverToBoxAdapter(child: _ArchiveFooter()),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Header
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onSearch;
  const _Header({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            children: [
              // Hamburger — future: drawer
              Icon(Icons.menu_rounded,
                  color: QColors.textSubtle, size: 22),
              const Spacer(),
              GestureDetector(
                onTap: onSearch,
                child: Icon(Icons.search_rounded,
                    color: QColors.textSubtle, size: 22),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Tag
          Text(
            'PRIVATE COLLECTION',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: QColors.textGhost,
              letterSpacing: 2.5,
            ),
          ),

          const SizedBox(height: 8),

          // Title
          Text(
            'The Vault',
            style: Theme.of(context).textTheme.displayLarge,
          ),

          const SizedBox(height: 6),

          // Subtitle
          Text(
            'A curated archive of words that shaped your perspective.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: QColors.textSubtle,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TabBarDelegate — pinned SliverPersistentHeader for the filter tabs
// ─────────────────────────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _TabBarDelegate({required this.activeIndex, required this.onTap});

  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 44;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: QColors.obsidian,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final isActive = i == activeIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: 200.ms,
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(right: 24),
                padding: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      // Active tab: amber underline. Inactive: transparent.
                      color: isActive
                          ? QColors.amberGlow
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[i].label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 1.8,
                    color: isActive ? Colors.white : QColors.textSubtle,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.activeIndex != activeIndex;
}

// ─────────────────────────────────────────────────────────────────────────────
// _SavedQuoteCard
// ─────────────────────────────────────────────────────────────────────────────
class _SavedQuoteCard extends ConsumerWidget {
  final Quote quote;
  final int index;

  const _SavedQuoteCard({super.key, required this.quote, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _openDetail(context, quote),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: QColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: QColors.borderSubtle, width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 48, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quote text
                  Text(
                    '"${quote.text}"',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Thin divider line — matches screenshot
                  Container(
                    width: 32,
                    height: 1,
                    color: QColors.divider,
                  ),

                  const SizedBox(height: 12),

                  // Author
                  Text(
                    quote.author.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      color: QColors.textSubtle,
                    ),
                  ),

                  // Source section
                  if (quote.sourceSection?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      quote.sourceSection!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: QColors.textGhost,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bookmark icon — top right, tapping removes from vault
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () =>
                    ref.read(savedQuotesProvider.notifier).toggle(quote.id),
                behavior: HitTestBehavior.opaque,
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: QColors.amberGlow,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      )
      // Staggered entrance — each card fades up with a small delay
      .animate(delay: (index * 60).ms)
      .fadeIn(duration: 350.ms, curve: Curves.easeOut)
      .slideY(begin: 0.06, end: 0, duration: 350.ms, curve: Curves.easeOut),
    );
  }

  void _openDetail(BuildContext context, Quote quote) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (_, __, ___) => _QuoteDetailScreen(quote: quote),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuoteDetailScreen
// Full-screen quote view — same layout as HomeScreen quote card.
// Tap anywhere or swipe down to dismiss.
// ─────────────────────────────────────────────────────────────────────────────
class _QuoteDetailScreen extends ConsumerWidget {
  final Quote quote;
  const _QuoteDetailScreen({required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Centred quote content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '"${quote.text}"',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium,
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.04, end: 0, duration: 400.ms),

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

            // Top-right: unbookmark + share
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 20,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(savedQuotesProvider.notifier).toggle(quote.id);
                      Navigator.of(context).pop();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: QColors.amberGlow,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      // TODO: share_plus
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(
                      Icons.ios_share_rounded,
                      color: QColors.textSubtle,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // Close hint at the bottom
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 32,
              left: 0,
              right: 0,
              child: const Text(
                'TAP TO CLOSE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  letterSpacing: 2,
                  color: QColors.textGhost,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  const _EmptyState({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_outline_rounded,
            size: 40,
            color: QColors.textGhost,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'Nothing saved in this category yet.'
                : 'Your vault is empty.\nSave a quote to begin.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: QColors.textSubtle,
              height: 1.6,
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ArchiveFooter
// ─────────────────────────────────────────────────────────────────────────────
class _ArchiveFooter extends StatelessWidget {
  const _ArchiveFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 32, height: 1, color: QColors.divider),
          const SizedBox(width: 12),
          const Text(
            'END OF ARCHIVE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              letterSpacing: 2.5,
              color: QColors.textGhost,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 32, height: 1, color: QColors.divider),
        ],
      ),
    );
  }
}