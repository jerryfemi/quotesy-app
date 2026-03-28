import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_style.dart';
import '../models/quote.dart';
import '../providers/database_provider.dart';
import '../services/quote_share_service.dart';
import '../theme/quotesy_theme.dart';
import '../widgets/home_quote_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CategoryFeedScreen
//
// Full-screen vertical PageView for a single category.
// Pushed via GoRouter — has an AppBar with a back chevron.
//
// Reuses HomeQuoteCard directly:
//   - double-tap  → bookmark toggle (amber pulse)
//   - long-press  → share sheet
//
// The AppBar is transparent and floats over the obsidian background.
// A thin category-accent strip runs under the title as a visual anchor.
// ─────────────────────────────────────────────────────────────────────────────
class CategoryFeedScreen extends ConsumerStatefulWidget {
  final String category;

  const CategoryFeedScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryFeedScreen> createState() => _CategoryFeedScreenState();
}

class _CategoryFeedScreenState extends ConsumerState<CategoryFeedScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;

  // Derive the CategoryStyle once — used for the accent color in the AppBar.
  late final CategoryStyle _style;

  @override
  void initState() {
    super.initState();
    _style = CategoryStyle.forCategory(widget.category);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareQuote(Quote quote) async {
    await shareQuoteImage(context, quote);
  }

  @override
  Widget build(BuildContext context) {
    final quotesAsync = ref.watch(quotesByCategoryProvider(widget.category));

    return Scaffold(
      backgroundColor: QColors.obsidian,
      extendBodyBehindAppBar: true,
      appBar: _CategoryAppBar(style: _style, category: widget.category),
      body: quotesAsync.when(
        loading: () => const _LoadingState(),
        error: (e, _) => _ErrorState(error: e),
        data: (quotes) {
          if (quotes.isEmpty) {
            return _EmptyState(category: widget.category);
          }

          if (_currentIndex >= quotes.length) {
            _currentIndex = 0;
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: quotes.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => HomeQuoteCard(
              key: ValueKey(quotes[index].id),
              quote: quotes[index],
              onShare: _shareQuote,
            ),
          );
        },
      ),
    );
  }
}


class _CategoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final CategoryStyle style;
  final String category;

  const _CategoryAppBar({required this.style, required this.category});

  Color get _accentColor {
    final layers = style.lightLayers;
    if (layers.isEmpty) return QColors.amberGlow;
    final colors = layers.first.gradient.colors;
    for (final c in colors) {
      if (c.a > 0.3) return c;
    }
    return QColors.amberGlow;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
        behavior: HitTestBehavior.opaque,
        child: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Icon(
            Icons.chevron_left_rounded,
            color: Colors.white70,
            size: 28,
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            style.displayTitle,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 28,
            height: 1.5,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                _accentColor.withValues(alpha: 0.18),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LoadingState — shown while quotesByCategoryProvider is loading.
// Minimal — local Hive reads are fast, this almost never shows.
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: QColors.textSubtle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorState
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final Object error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'Something went wrong.\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: QColors.textSubtle,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState — shouldn't happen with real data, but guard it anyway.
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String category;
  const _EmptyState({required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 36,
              color: QColors.textGhost,
            ),
            const SizedBox(height: 16),
            Text(
              'No quotes found\nfor $category.',
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
      ),
    );
  }
}