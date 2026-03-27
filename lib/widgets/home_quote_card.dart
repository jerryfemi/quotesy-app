import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote.dart';
import '../providers/database_provider.dart';
import '../theme/quotesy_theme.dart';

class HomeQuoteCard extends ConsumerStatefulWidget {
  final Quote quote;
  final Future<void> Function(Quote quote) onShare;

  const HomeQuoteCard({
    super.key,
    required this.quote,
    required this.onShare,
  });

  @override
  ConsumerState<HomeQuoteCard> createState() => _HomeQuoteCardState();
}

class _HomeQuoteCardState extends ConsumerState<HomeQuoteCard> {
  static const double _longPressMoveTolerance = 8.0;

  Offset? _pointerDownPosition;
  bool _movedBeyondTolerance = false;
  bool _showBookmarkPulse = false;

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.position;
    _movedBeyondTolerance = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    final origin = _pointerDownPosition;
    if (origin == null || _movedBeyondTolerance) return;

    final dx = event.position.dx - origin.dx;
    final dy = event.position.dy - origin.dy;
    final distance = math.sqrt((dx * dx) + (dy * dy));
    if (distance > _longPressMoveTolerance) {
      _movedBeyondTolerance = true;
    }
  }

  void _onPointerEnd(PointerEvent _) {
    _pointerDownPosition = null;
    _movedBeyondTolerance = false;
  }

  Future<void> _onDoubleTap() async {
    await ref.read(savedQuotesProvider.notifier).toggle(widget.quote.id);
    if (!mounted) return;

    setState(() => _showBookmarkPulse = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _showBookmarkPulse = false);
  }

  Future<void> _onLongPress() async {
    if (_movedBeyondTolerance) return;
    HapticFeedback.mediumImpact();
    await widget.onShare(widget.quote);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _onDoubleTap,
        onLongPress: _onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: QColors.obsidian,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '"${widget.quote.text}"',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: 28),
                    Container(width: 40, height: 1, color: QColors.divider),
                    const SizedBox(height: 20),
                    Text(
                      widget.quote.author.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge,
                    ),
                    if (widget.quote.sourceSection?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.quote.sourceSection!,
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
            ),

            IgnorePointer(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _showBookmarkPulse
                      ? const Icon(
                          Icons.bookmark_rounded,
                          key: ValueKey('bookmark-flash'),
                          color: QColors.amberGlow,
                          size: 56,
                        )
                      : const SizedBox.shrink(key: ValueKey('bookmark-hidden')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
