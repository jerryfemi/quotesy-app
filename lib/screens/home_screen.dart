import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotesy/widgets/streak/streak_sheet.dart';

import '../models/quote.dart';
import '../models/streak_model.dart';
import '../providers/database_provider.dart';
import '../services/notifications.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final _pageController = PageController();
  ProviderSubscription<AsyncValue<List<Quote>>>? _feedSubscription;
  static const int _narrowFeedThreshold = 20;
  int _currentIndex = 0;
  bool _feedResetQueued = false;
  bool _showGhostHint = false;
  bool _hintSeenMarked = false;
  Timer? _hintRevealTimer;
  Timer? _hintAutoFadeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _feedSubscription = ref.listenManual<AsyncValue<List<Quote>>>(
      filteredFeedProvider,
      (previous, next) {
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
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGestureHintOnce();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncNotificationsOnResume());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _feedSubscription?.close();
    _hintRevealTimer?.cancel();
    _hintAutoFadeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _syncNotificationsOnResume() async {
    try {
      await ref.read(databaseInitProvider.future);
      if (!mounted) return;

      final db = ref.read(databaseServiceProvider);
      final streak = ref.read(streakProvider);

      await Notifications().resyncIfNeeded(database: db, streak: streak);
    } catch (error, stack) {
      debugPrint(
        'Resume notification sync failed (continuing): $error\n$stack',
      );
    }
  }

  Future<void> _showGestureHintOnce() async {
    await ref.read(databaseInitProvider.future);
    final service = ref.read(databaseServiceProvider);
    if (service.hasSeenHomeGestureHint()) return;
    if (!mounted) return;

    _hintRevealTimer?.cancel();
    _hintRevealTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _showGhostHint = true);
    });

    _hintAutoFadeTimer?.cancel();
    _hintAutoFadeTimer = Timer(const Duration(seconds: 8), () {
      _dismissGhostHint();
    });
  }

  Future<void> _markHintSeenIfNeeded() async {
    if (_hintSeenMarked) return;
    _hintSeenMarked = true;
    await ref.read(databaseServiceProvider).setHomeGestureHintSeen(true);
  }

  Future<void> _dismissGhostHint() async {
    if (!_showGhostHint) {
      await _markHintSeenIfNeeded();
      return;
    }

    _hintRevealTimer?.cancel();
    _hintAutoFadeTimer?.cancel();

    if (mounted) {
      setState(() => _showGhostHint = false);
    }

    await _markHintSeenIfNeeded();
  }

  Future<void> _openFilters() async {
    await showFeedFilterSheet(context, ref);
  }

  Future<void> _openStreak() async {
    await showStreakSheet(context, ref);
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
    final quotes = ref
        .watch(filteredFeedProvider)
        .maybeWhen(data: (value) => value, orElse: () => <Quote>[]);
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

        Positioned(
          top: topPad + 12,
          left: 20,
          child: _StreakIndicator(() => _openStreak()),
        ),

        Positioned(
          top: topPad + 8,
          right: 16,
          child: _FeedFilterButton(
            onTap: _openFilters,
            hasCurrentQuote: currentQuote != null,
          ),
        ),

        _NarrowFeedHint(quoteCount: quotes.length),

        // Slide-up Hint Card
        AnimatedPositioned(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          left: 20,
          right: 20,
          // If showing, sit nicely above the bottom nav. If not, hide it off-screen.
          bottom: _showGhostHint ? 120 : -500,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: QColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: QColors.borderMid, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Small drag handle pill at the top
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: QColors.borderMid,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: QColors.amberGlow.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swipe_up_rounded,
                    color: QColors.amberGlow,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                const Text(
                  'Welcome to Quotesy',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: QColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Instructions
                const Text(
                  'Swipe up to explore.\nDouble-tap to save. Long-press to share.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.5,
                    color: QColors.textSubtle,
                  ),
                ),
                const SizedBox(height: 24),
                // Dismiss Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _dismissGhostHint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QColors.obsidian,
                      foregroundColor: QColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: QColors.borderMid),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedFilterButton extends ConsumerWidget {
  const _FeedFilterButton({required this.onTap, required this.hasCurrentQuote});

  final VoidCallback onTap;
  final bool hasCurrentQuote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveFilters = ref.watch(
      feedPreferencesProvider.select(
        (value) => value.maybeWhen(
          data: (prefs) => prefs.hasActiveFilters,
          orElse: () => false,
        ),
      ),
    );

    return Semantics(
      label: hasActiveFilters ? 'Filters active' : 'Open feed filters',
      button: true,
      child: GestureDetector(
        onTap: onTap,
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
                  color: hasCurrentQuote
                      ? QColors.textSubtle
                      : QColors.textGhost,
                ),
              ),
              if (hasActiveFilters)
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
    );
  }
}

class _NarrowFeedHint extends ConsumerWidget {
  const _NarrowFeedHint({required this.quoteCount});

  final int quoteCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveFilters = ref.watch(
      feedPreferencesProvider.select(
        (value) => value.maybeWhen(
          data: (prefs) => prefs.hasActiveFilters,
          orElse: () => false,
        ),
      ),
    );
    if (!hasActiveFilters ||
        quoteCount >= _HomeScreenState._narrowFeedThreshold) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 20,
      right: 20,
      bottom: 90,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: QColors.borderSubtle,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: QColors.borderMid, width: 1),
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
    );
  }
}

class _StreakIndicator extends ConsumerWidget {
  const _StreakIndicator(this.onTap);
  final VoidCallback onTap;

  static const bool _debugScreenshotMode = true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final displayStreak = (kDebugMode && _debugScreenshotMode)
        ? 24
        : streak.currentStreak;

    return Semantics(
      label: 'Open streak details',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                child:
                    const Icon(
                          Icons.local_fire_department_rounded,
                          color: QColors.amberGlow,
                          size: 18,
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
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
              ),
              const SizedBox(width: 5),
              Text(
                '$displayStreak',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: QColors.amberGlow,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
