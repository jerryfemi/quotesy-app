import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote.dart';
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   
    final quotes = ref.watch(randomFeedProvider).maybeWhen(
      data: (value) => value,
      orElse: () => <Quote>[],
    );
    final nav = NavBarControllerScope.of(context);

    return Listener(
      onPointerMove:  (e) => nav.onDrag(e.delta.dy),
      onPointerUp:    (_) => nav.onDragEnd(),
      onPointerCancel:(_) => nav.onDragEnd(),
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: quotes.length,
        itemBuilder: (context, index) => _QuoteCard(
          key: ValueKey(quotes[index].id),
          quote: quotes[index],
        ),
      ),
    );
  }
}


class _QuoteCard extends ConsumerWidget {
  final Quote quote;
  const _QuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final isBookmarked = ref.watch(
      savedQuotesProvider.select((s) =>
          s.whenData((list) => list.any((q) => q.id == quote.id))
              .maybeWhen(data: (value) => value, orElse: () => false)),
    );

    return ColoredBox(
      color: QColors.obsidian,
      child: Stack(
        children: [
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
          .slideY(begin: 0.04, end: 0, duration: 400.ms, curve: Curves.easeOut),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: Row(
              children: [
                _ActionButton(
                  icon: isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  isActive: isBookmarked,
                  onTap: () =>
                      ref.read(savedQuotesProvider.notifier).toggle(quote.id),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () {
                    // TODO: share_plus
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 1,
      color: QColors.divider,
    );
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