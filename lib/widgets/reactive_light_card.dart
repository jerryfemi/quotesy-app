import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
// Unfocused cards: light layers at glowBaseline (25%) so the card
// breathes with colour even when not centred. The user can see
// "there's something there" without it competing with the focused card.
//
// Focused cards: light layers at 100%, outer boxShadow glows with
// primaryColor, rim border brightens — full awakening.
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

    // Outer glow (boxShadow): 0 when unfocused, pulses with primaryColor at focus.
    final outerGlowAlpha = (0.0 + (0.45 * glowFocus)).clamp(0.0, 1.0);

    // Rim border: subtle when unfocused, brightens as card enters focus.
    final rimAlpha = (0.06 + (0.24 * glowFocus)).clamp(0.0, 1.0);

    // Subtitle: fades in once focus > 0.35.
    final subtitleVisible = focusAmount > 0.35;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // The darkroom floor — deliberately near-black, not pure black,
        // so the gradient colours read against it with warmth.
        color: QColors.cardBase,
        border: Border.all(
          color: Colors.white.withValues(alpha: rimAlpha),
          width: 1.0,
        ),
        boxShadow: [
          // Depth shadow — always present
          const BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          // Coloured outer glow — appears as card focuses.
          // Spreads the card's primaryColor outward, making the card look
          // like it's emitting light. This is the "Stitch" effect.
          if (outerGlowAlpha > 0.0)
            BoxShadow(
              color: style.primaryColor.withValues(alpha: outerGlowAlpha),
              blurRadius: 60,
              spreadRadius: -8,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [

            // ── LIGHT LAYERS ────────────────────────────────────────────────
            // Single Opacity wraps all gradient layers.
            // One compositing layer total — cheaper than N individual Opacitys.
            // NO dark overlay above this. NO backdrop blur. Nothing between
            // this and the base card colour except the card itself.
            Opacity(
              opacity: lightOpacity,
              child: Stack(
                fit: StackFit.expand,
                children: style.lightLayers
                    .map((layer) => DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: layer.gradient,
                          ),
                        ))
                    .toList(),
              ),
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

                  // Subtitle — flutter_animate fadeIn + slideY
                  // Removed from tree entirely when not visible.
                  if (subtitleVisible) ...[
                    const SizedBox(height: 14),
                    Text(
                      style.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: QColors.textMuted,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}