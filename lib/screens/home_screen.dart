import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../providers/database_provider.dart';
import '../routes/app_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(randomFeedProvider);
    final navBarController = NavBarControllerScope.of(context);

    return feedAsync.when(
      loading: () => const _QuoteLoadingSkeleton(),
      error: (e, _) => _QuoteError(error: e),
      data: (quotes) => Listener(
        onPointerMove: (event) {
          navBarController.onDrag(event.delta.dy);
        },
        onPointerUp: (_) => navBarController.onDragEnd(),
        onPointerCancel: (_) => navBarController.onDragEnd(),
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            return _QuoteCard(quote: quotes[index]);
          },
        ),
      ),
    );
  }
}

class _QuoteCard extends ConsumerWidget {
  final Quote quote;

  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isBookmarkedAsync = ref.watch(
      savedQuotesProvider.select(
        (state) =>
            state.whenData((quotes) => quotes.any((q) => q.id == quote.id)),
      ),
    );
    final isBookmarked = isBookmarkedAsync.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '"${quote.text}"',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayMedium,
                ),
                const SizedBox(height: 28),
                Container(
                  width: 40,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 20),
                Text(
                  quote.author.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge,
                ),
                if (quote.sourceSection != null &&
                    quote.sourceSection!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    quote.sourceSection!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
                  onTap: () {
                    ref.read(savedQuotesProvider.notifier).toggle(quote.id);
                  },
                ),
                const SizedBox(width: 8),
                _ActionButton(icon: Icons.ios_share_rounded, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
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
        duration: const Duration(milliseconds: 200),
        child: Icon(
          icon,
          key: ValueKey(isActive),
          color: isActive ? Colors.white : Colors.white54,
          size: 22,
        ),
      ),
    );
  }
}

class _QuoteLoadingSkeleton extends StatelessWidget {
  const _QuoteLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: Colors.white24,
        ),
      ),
    );
  }
}

class _QuoteError extends StatelessWidget {
  final Object error;

  const _QuoteError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$error',
        style: const TextStyle(color: Colors.white24, fontSize: 13),
      ),
    );
  }
}
