import 'package:flutter/material.dart';
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
//
// Nothing sits between the base and the light layers.
// No dark overlays, no backdrop blur — those were killing the gradients.
//
// Unfocused cards: light layers at glowBaseline so the card
// breathes with colour even when not centred. The user can see
// "there's something there" without it competing with the focused card.
//
// Focused cards: light layers at 100%, rim border brightens.
// No outside glow/shadow is rendered beyond the card bounds.
// ─────────────────────────────────────────────────────────────────────────────
class ReactiveLightCard extends StatelessWidget {
  final CategoryStyle style;
  final double focusAmount;     // 0.0 = off-screen, 1.0 = dead center
  final double glowBaseline;    // minimum light opacity on unfocused cards

  const ReactiveLightCard({
    super.key,
    required this.style,
    required this.focusAmount,
    this.glowBaseline = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Apply easeOutCubic so the glow accelerates into focus — feels alive.
    final glowFocus = Curves.easeOutCubic.transform(
      focusAmount.clamp(0.0, 1.0),
    );

    // Light opacity: starts at glowBaseline, reaches 1.0 at full focus.
    final lightOpacity =
        (glowBaseline + ((1.0 - glowBaseline) * glowFocus)).clamp(0.0, 1.0);

    // Rim border: subtle when unfocused, brightens as card enters focus.
    final rimAlpha = (0.06 + (0.24 * glowFocus)).clamp(0.0, 1.0);

    // Subtitle: smoothly appears once focus crosses the reveal threshold.
    final subtitleVisibility = ((focusAmount - 0.35) / 0.25).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

              // ── CONTENT ─────────────────────────────────────────────────────
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