import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote.dart';
import '../models/streak_model.dart';
import '../providers/database_provider.dart';
import '../services/quote_share_service.dart';
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
  bool _feedResetQueued = false;
  bool _showGhostHint = false;
  double _ghostHintOpacity = 0.0;
  bool _hintSeenMarked = false;
  Timer? _hintRevealTimer;
  Timer? _hintAutoFadeTimer;
  Timer? _hintRemoveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGestureHintOnce();
    });
  }

  @override
  void dispose() {
    _hintRevealTimer?.cancel();
    _hintAutoFadeTimer?.cancel();
    _hintRemoveTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showGestureHintOnce() async {
    await ref.read(databaseInitProvider.future);
    final service = ref.read(databaseServiceProvider);
    if (service.hasSeenHomeGestureHint()) return;
    if (!mounted) return;

    setState(() {
      _showGhostHint = true;
      _ghostHintOpacity = 0.0;
    });

    _hintRevealTimer?.cancel();
    _hintRevealTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || !_showGhostHint) return;
      setState(() => _ghostHintOpacity = 0.5);
    });

    _hintAutoFadeTimer?.cancel();
    _hintAutoFadeTimer = Timer(const Duration(seconds: 4), () {
      _dismissGhostHint();
    });
  }

  Future<void> _markHintSeenIfNeeded() async {
    if (_hintSeenMarked) return;
    _hintSeenMarked = true;
    await ref.read(databaseServiceProvider).setHomeGestureHintSeen(true);
  }

  Future<void> _dismissGhostHint() async {
    if (!_showGhostHint && _ghostHintOpacity == 0) {
      await _markHintSeenIfNeeded();
      return;
    }

    _hintRevealTimer?.cancel();
    _hintAutoFadeTimer?.cancel();

    if (mounted && _ghostHintOpacity != 0) {
      setState(() => _ghostHintOpacity = 0.0);
    }

    _hintRemoveTimer?.cancel();
    _hintRemoveTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _showGhostHint = false);
    });

    await _markHintSeenIfNeeded();
  }

  Future<void> _openFilters() async {
    await showFeedFilterSheet(context, ref);
  }

  Future<void> _shareQuote(Quote quote) async {
    await shareQuoteImage(context, quote);
  }

  bool _didFeedChange(List<Quote> previous, List<Quote> next) {
    if (previous.length != next.length) return true;
    for (var i = 0; i < previous.length; i++) {
      if (previous[i].id != next[i].id) {
        return true;
      }
    }
    return false;
  }

  void _queueResetToFirstQuote() {
    if (_feedResetQueued) return;
    _feedResetQueued = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _feedResetQueued = false;
      if (!mounted) return;

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }

      if (_currentIndex != 0) {
        setState(() => _currentIndex = 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Quote>>>(filteredFeedProvider, (previous, next) {
      final previousQuotes = previous?.maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );
      final nextQuotes = next.maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );

      if (previousQuotes == null || nextQuotes == null) return;
      if (_didFeedChange(previousQuotes, nextQuotes)) {
        _queueResetToFirstQuote();
      }
    });

    final quotes = ref
        .watch(filteredFeedProvider)
        .maybeWhen(data: (value) => value, orElse: () => <Quote>[]);
    final feedPrefs = ref
        .watch(feedPreferencesProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => FeedPreferencesState.empty,
        );

    final nav = NavBarControllerScope.of(context);
    final topPad = MediaQuery.of(context).padding.top;

    if (quotes.isNotEmpty && _currentIndex >= quotes.length) {
      _queueResetToFirstQuote();
    }

    final safeIndex = quotes.isEmpty
        ? 0
        : _currentIndex.clamp(0, quotes.length - 1);
    final currentQuote = quotes.isNotEmpty ? quotes[safeIndex] : null;

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
            onPageChanged: (index) {
              if (_showGhostHint) {
                _dismissGhostHint();
              }
              setState(() => _currentIndex = index);
            },
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

        if (_showGhostHint)
          Positioned(
            left: 20,
            right: 20,
            bottom: 36,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _ghostHintOpacity,
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                child: const Text(
                  'Double-tap to save  •  Long-press to share',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
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
