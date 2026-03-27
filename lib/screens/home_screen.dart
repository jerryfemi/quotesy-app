import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/quote.dart';
import '../models/streak_model.dart';
import '../providers/database_provider.dart';
import '../theme/quotesy_theme.dart';
import '../widgets/feed_filter_sheet.dart';
import '../widgets/home_quote_card.dart';
import '../widgets/quotesy_nav_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();
  static const int _narrowFeedThreshold = 20;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGestureHintOnce();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showGestureHintOnce() async {
    await ref.read(databaseInitProvider.future);
    final service = ref.read(databaseServiceProvider);
    if (service.hasSeenHomeGestureHint()) return;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Double tap to save • Hold to share')),
    );
    await service.setHomeGestureHintSeen(true);
  }

  Future<void> _openFilters() async {
    await showFeedFilterSheet(context, ref);
  }

  Future<void> _shareQuote(Quote quote) async {
    final screenshotController = ScreenshotController();

    try {
      final fileName = 'quotesy_${quote.id}';
      final imageBytes = await screenshotController.captureFromWidget(
        InheritedTheme.captureAll(
          context,
          MediaQuery(
            data: MediaQuery.of(context),
            child: Directionality(
              textDirection: Directionality.of(context),
              child: SizedBox(
                width: 1080,
                height: 1920,
                child: _ShareQuoteCard(quote: quote),
              ),
            ),
          ),
        ),
        delay: const Duration(milliseconds: 40),
        pixelRatio: 2,
      );

      final file = XFile.fromData(
        imageBytes,
        mimeType: 'image/png',
        name: '$fileName.png',
      );

      await SharePlus.instance.share(
        ShareParams(
          text: '"${quote.text}" — ${quote.author}',
          files: [file],
          fileNameOverrides: ['$fileName.png'],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share quote right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quotes = ref
        .watch(filteredFeedProvider)
        .maybeWhen(data: (value) => value, orElse: () => <Quote>[]);
    final feedPrefs = ref.watch(feedPreferencesProvider).maybeWhen(
          data: (value) => value,
          orElse: () => FeedPreferencesState.empty,
        );

    final nav = NavBarControllerScope.of(context);
    final topPad = MediaQuery.of(context).padding.top;

    if (_currentIndex >= quotes.length && quotes.isNotEmpty) {
      _currentIndex = 0;
    }

    final currentQuote = quotes.isNotEmpty ? quotes[_currentIndex] : null;

    return Stack(
      children: [
        Listener(
          onPointerMove: (e) => nav.onDrag(e.delta.dy),
          onPointerUp: (_) => nav.onDragEnd(),
          onPointerCancel: (_) => nav.onDragEnd(),
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: quotes.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => HomeQuoteCard(
              key: ValueKey(quotes[index].id),
              quote: quotes[index],
              onShare: _shareQuote,
            ),
          ),
        ),

        Positioned(top: topPad + 12, left: 20, child: const _StreakIndicator()),

        Positioned(
          top: topPad + 8,
          right: 16,
          child: Semantics(
            label: feedPrefs.hasActiveFilters
                ? 'Filters active'
                : 'Open feed filters',
            button: true,
            child: GestureDetector(
              onTap: _openFilters,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 38,
                height: 38,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Icon(
                        Icons.tune_rounded,
                        size: 22,
                        color: currentQuote != null
                            ? QColors.textSubtle
                            : QColors.textGhost,
                      ),
                    ),
                    if (feedPrefs.hasActiveFilters)
                      Positioned(
                        right: 5,
                        top: 5,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: QColors.amberGlow,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (feedPrefs.hasActiveFilters && quotes.length < _narrowFeedThreshold)
          Positioned(
            left: 20,
            right: 20,
            bottom: 90,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(14, 10, 14, 11),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_alt_outlined,
                        size: 14,
                        color: QColors.textSubtle,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your feed is short. Add a category or author to broaden it.',
                          style: TextStyle(
                            color: QColors.textSubtle,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShareQuoteCard extends StatelessWidget {
  final Quote quote;
  const _ShareQuoteCard({required this.quote});

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
            const _Divider(),
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

class _StreakIndicator extends ConsumerWidget {
  const _StreakIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
              Icons.local_fire_department_rounded,
              color: QColors.amberGlow,
              size: 18,
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scaleXY(
              begin: 1.0,
              end: 1.18,
              duration: 1500.ms,
              curve: Curves.easeInOut,
            )
            .fade(
              begin: 0.75,
              end: 1.0,
              duration: 1500.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(width: 5),
        Text(
          '${streak.currentStreak}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: QColors.amberGlow,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 40, height: 1, color: QColors.divider);
  }
}
