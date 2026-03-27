import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import '../models/quote.dart';
import '../models/streak_model.dart';
import '../providers/database_provider.dart';
import '../theme/quotesy_theme.dart';
import '../widgets/quotesy_nav_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotes = ref
      .watch(filteredFeedProvider)
        .maybeWhen(data: (value) => value, orElse: () => <Quote>[]);
    final nav = NavBarControllerScope.of(context);
    final topPad = MediaQuery.of(context).padding.top;

    final currentQuote = quotes.isNotEmpty && _currentIndex < quotes.length
        ? quotes[_currentIndex]
        : null;

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
            itemBuilder: (context, index) => _QuoteCard(
              key: ValueKey(quotes[index].id),
              quote: quotes[index],
            ),
          ),
        ),

        Positioned(top: topPad + 12, left: 20, child: const _StreakIndicator()),

        if (currentQuote != null)
          Positioned(
            top: topPad + 12,
            right: 20,
            child: _ActionButtons(quote: currentQuote),
          ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote quote;
  const _QuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: QColors.obsidian,
      child:
          Padding(
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
              )
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.04,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOut,
              ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  final Quote quote;

  const _ActionButtons({required this.quote});

  Future<void> _shareQuote(BuildContext context) async {
    final screenshotController = ScreenshotController();

    try {
      final fileName = 'quotesy_ ${quote.author}_${quote.id}';

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
                child: _QuoteCard(quote: quote),
              ),
            ),
          ),
        ),
        delay: const Duration(milliseconds: 40),
        pixelRatio: 2,
      );

      if (!kIsWeb) {
        await ImageGallerySaverPlus.saveImage(
          imageBytes,
          quality: 100,
          name: fileName,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved to gallery')));
        }
      }

      final file = XFile.fromData(
        imageBytes,
        mimeType: 'image/png',
        name: '$fileName.png',
      );

      await SharePlus.instance.share(
        ShareParams(
          text: quote.author,
          files: [file],
          fileNameOverrides: ['$fileName.png'],
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share quote right now.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(
      savedQuotesProvider.select(
        (s) => s
            .whenData((list) => list.any((q) => q.id == quote.id))
            .maybeWhen(data: (value) => value, orElse: () => false),
      ),
    );

    return Row(
      children: [
        _ActionButton(
          icon: isBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_outline_rounded,
          isActive: isBookmarked,
          onTap: () => ref.read(savedQuotesProvider.notifier).toggle(quote.id),
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.ios_share_rounded,
          onTap: () => _shareQuote(context),
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 40, height: 1, color: QColors.divider);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedSwitcher(
        duration: 200.ms,
        child: Icon(
          icon,
          key: ValueKey(isActive),
          // Active bookmark → amber accent. Inactive → subtle white.
          color: isActive ? QColors.amberGlow : QColors.textSubtle,
          size: 22,
        ),
      ),
    );
  }
}
