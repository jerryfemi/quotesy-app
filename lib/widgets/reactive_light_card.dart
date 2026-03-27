import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category_style.dart';
import '../theme/quotesy_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReactiveLightCard
//
// The lighting system works in 3 layers, bottom to top:
//
//   1. BASE CARD     — pure #080604, the darkroom floor
//   2. LIGHT LAYERS  — the category gradients (the actual lighting)
//   3. CONTENT       — tag, title, subtitle
//   4. PIN TOGGLE    — top-right corner, overlaid above everything
//
// Nothing sits between the base and the light layers.
// No dark overlays, no backdrop blur — those were killing the gradients.
//
// Unfocused cards: light layers at glowBaseline so the card
// breathes with colour even when not centred.
//
// Focused cards: light layers at 100%, rim border brightens.
//
// Pin toggle: always visible but subtle when unpinned. Amber + filled when
// pinned. Tapping gives a light haptic. The toggle sits in the top-right
// corner, 32×32 touch target so it never feels fiddly.
// ─────────────────────────────────────────────────────────────────────────────

const _kAmber = Color(0xFFB8860B);
const _kAmberGlow = Color(0xFFD4A017);

class ReactiveLightCard extends StatelessWidget {
  final CategoryStyle style;
  final double focusAmount; // 0.0 = off-screen, 1.0 = dead center
  final double glowBaseline; // minimum light opacity on unfocused cards
  final bool isPinned; // whether this category is pinned to Home
  final VoidCallback? onPinToggle;
  final EdgeInsetsGeometry margin;

  const ReactiveLightCard({
    super.key,
    required this.style,
    required this.focusAmount,
    this.glowBaseline = 0.25,
    this.isPinned = false,
    this.onPinToggle,
    this.margin = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Apply easeOutCubic so the glow accelerates into focus — feels alive.
    final glowFocus = Curves.easeOutCubic.transform(
      focusAmount.clamp(0.0, 1.0),
    );

    // Light opacity: starts at glowBaseline, reaches 1.0 at full focus.
    final lightOpacity = (glowBaseline + ((1.0 - glowBaseline) * glowFocus))
        .clamp(0.0, 1.0);

    // Rim border: subtle when unfocused, brightens as card enters focus.
    final rimAlpha = (0.06 + (0.24 * glowFocus)).clamp(0.0, 1.0);

    // Subtitle: smoothly appears once focus crosses the reveal threshold.
    final subtitleVisibility = ((focusAmount - 0.35) / 0.25).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: QColors.cardBase,
          border: Border.all(
            color: Colors.white.withValues(alpha: rimAlpha),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── LIGHT LAYERS ─────────────────────────────────────────────
              Stack(
                fit: StackFit.expand,
                children: style.lightLayers
                    .map(
                      (layer) => DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _gradientWithOpacity(
                            layer.gradient,
                            lightOpacity,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              // ── CONTENT ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag — small tracked caps, brightens with focus
                    Text(
                      style.tagLine,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'Playfair Display',
                        letterSpacing: 1.6,
                        color: Colors.white.withValues(
                          alpha: 0.30 + (0.35 * glowFocus),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Title — Playfair, brightens with focus
                    Text(
                      style.displayTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white.withValues(
                          alpha: 0.55 + (0.45 * glowFocus),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    AnimatedSlide(
                      offset: Offset(0, (1.0 - subtitleVisibility) * 0.2),
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOut,
                      child: AnimatedOpacity(
                        opacity: subtitleVisibility,
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOut,
                        child: Text(
                          style.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: QColors.textMuted,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── PIN TOGGLE ───────────────────────────────────────────────
              // Top-right corner. Small, unobtrusive, always visible.
              // Outlined = not pinned. Filled amber = pinned to Home.
              if (onPinToggle != null)
                Positioned(
                  top: 14,
                  right: 14,
                  child: _PinToggle(isPinned: isPinned, onTap: onPinToggle!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Gradient _gradientWithOpacity(Gradient gradient, double opacity) {
    final adjustedColors = gradient.colors
        .map((color) => color.withValues(alpha: color.a * opacity))
        .toList(growable: false);

    if (gradient is RadialGradient) {
      return RadialGradient(
        center: gradient.center,
        radius: gradient.radius,
        colors: adjustedColors,
        stops: gradient.stops,
        focal: gradient.focal,
        focalRadius: gradient.focalRadius,
        tileMode: gradient.tileMode,
        transform: gradient.transform,
      );
    }

    if (gradient is LinearGradient) {
      return LinearGradient(
        begin: gradient.begin,
        end: gradient.end,
        colors: adjustedColors,
        stops: gradient.stops,
        tileMode: gradient.tileMode,
        transform: gradient.transform,
      );
    }

    if (gradient is SweepGradient) {
      return SweepGradient(
        center: gradient.center,
        startAngle: gradient.startAngle,
        endAngle: gradient.endAngle,
        colors: adjustedColors,
        stops: gradient.stops,
        tileMode: gradient.tileMode,
        transform: gradient.transform,
      );
    }

    return gradient;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PinToggle
//
// A tiny 32×32 tap target in the top-right corner of the card.
// Uses AnimatedSwitcher for a clean icon swap on state change.
// Haptic feedback on every tap — makes it feel physical.
//
// Visual states:
//   Unpinned  — push_pin_outlined, white at 35% opacity (quiet, present)
//   Pinned    — push_pin,          amber glow (clear, confirmed)
// ─────────────────────────────────────────────────────────────────────────────
class _PinToggle extends StatelessWidget {
  final bool isPinned;
  final VoidCallback onTap;

  const _PinToggle({required this.isPinned, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              key: ValueKey(isPinned),
              size: 17,
              color: isPinned
                  ? _kAmberGlow
                  : Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}
