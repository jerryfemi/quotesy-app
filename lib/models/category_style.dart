import 'package:flutter/material.dart';
import '../services/database_service.dart';

class GradientLayer {
  final Gradient gradient;
  const GradientLayer(this.gradient);

  GradientLayer.radial({
    required Alignment center,
    required double radius,
    required List<Color> colors,
    List<double>? stops,
  }) : this(RadialGradient(
          center: center,
          radius: radius,
          colors: colors,
          stops: stops,
        ));

  GradientLayer.linear({
    required AlignmentGeometry begin,
    required AlignmentGeometry end,
    required List<Color> colors,
    List<double>? stops,
  }) : this(LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
          stops: stops,
        ));
}

class CategoryStyle {
  final String categoryName;
  final String displayTitle;
  final String tagLine;
  final String subtitle;
  final Color primaryColor;
  final List<GradientLayer> lightLayers;

  const CategoryStyle({
    required this.categoryName,
    required this.displayTitle,
    required this.tagLine,
    required this.subtitle,
    required this.primaryColor,
    required this.lightLayers,
  });

  static CategoryStyle forCategory(String category) {
    switch (category) {

      // ── THE SHADOW (Psychology & Self) ─────────────────────────────────────
      // Wide soft radial from top-center — a distant skylight.
      // Cool grey-white, very subtle. Card mostly dark.
      case QuoteCategory.psychologyAndSelf:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'The Shadow',
          tagLine: 'PSYCHOLOGY & JUNG',
          subtitle:
              'Journey through the hidden recesses of the psyche and the beauty of the unknown.',
          primaryColor: const Color(0xFFCCCCCC),
          lightLayers: [
            GradientLayer.radial(
              center: const Alignment(0.0, -1.6),
              radius: 1.8,
              colors: const [
                Color(0x55AAAAAA),
                Color(0x22888888),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            GradientLayer.radial(
              center: const Alignment(0.0, 0.0),
              radius: 1.2,
              colors: const [
                Color(0x0FFFFFFF),
                Colors.transparent,
              ],
            ),
          ],
        );

      // ── EXISTENTIAL (Philosophy) ──────────────────────────────────────────
      // What the image shows:
      //   Top ~70%: deep blue-teal atmosphere — cool, brooding
      //   Low on card: thin horizontal copper/amber band — the "horizon line"
      //   Below the band: small sliver of dark card base
      //
      // How we build this:
      //   Layer 1: a tall radial from bottom-center pushes the copper band
      //            upward but keeps it concentrated low — this is the horizon
      //   Layer 2: a large radial from top-center fills the upper 70% with
      //            the deep teal-blue atmosphere
      //   The two meet and the copper horizon reads clearly against the teal
      case QuoteCategory.existential:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'Existential',
          tagLine: 'PHILOSOPHY',
          subtitle:
              'Reflections on purpose, being, and the silent weight of existence.',
          primaryColor: const Color(0xFF1A6B6B),
          lightLayers: [
            // Deep teal-blue fills the top 70% — the brooding atmosphere
            GradientLayer.radial(
              center: const Alignment(0.0, -1.8),
              radius: 2.2,
              colors: const [
                Color(0xCC1A4A5C), // deep blue-teal, 80%
                Color(0x881A3A4A), // darker teal, 53%
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            // Copper horizon band — sits low, horizontal, thin concentration
            GradientLayer.radial(
              center: const Alignment(0.0, 1.6),
              radius: 1.0,
              colors: const [
                Color(0xCC9C6A3C), // warm copper — same as Love & Yearning
                Color(0x667A4A20), // mid amber
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
          ],
        );

      // ── LOVE & YEARNING (Poetry) ──────────────────────────────────────────
      // Colour swap with Existential:
      //   Large copper/amber bloom from top-right (dominant, like Existential's teal)
      //   Deep blue-teal blooms on the other 3 corners
      //   Center stays darkest — light comes from the edges
      case QuoteCategory.loveAndYearning:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'Love & Yearning',
          tagLine: 'POETRY',
          subtitle:
              'The ache of distance and the intimacy of the written word.',
          primaryColor: const Color(0xFF9C6A3C),
          lightLayers: [
            // Dominant: large copper bloom from top-right
            GradientLayer.radial(
              center: const Alignment(1.2, -1.0),
              radius: 1.8,
              colors: const [
                Color(0xCC9C6A3C), // warm copper, 80%
                Color(0x667A4A20), // mid amber, 40%
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
            // Bottom-left: deep blue-teal — the Existential colour
            GradientLayer.radial(
              center: const Alignment(-1.1, 1.2),
              radius: 1.4,
              colors: const [
                Color(0x991A4A5C), // deep blue-teal, 60%
                Color(0x44152E38), // darker, 27%
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            // Top-left: teal tertiary fill
            GradientLayer.radial(
              center: const Alignment(-1.1, -0.8),
              radius: 1.1,
              colors: const [
                Color(0x661A3A4A), // muted teal, 40%
                Colors.transparent,
              ],
            ),
            // Bottom-right: faint teal so no corner goes cold
            GradientLayer.radial(
              center: const Alignment(1.1, 1.1),
              radius: 1.0,
              colors: const [
                Color(0x44152E38), // very faint teal, 27%
                Colors.transparent,
              ],
            ),
          ],
        );

      // ── WAR & EPIC ────────────────────────────────────────────────────────
      // Three horizontal bands described precisely:
      //
      //   TOP 35%:    Navy blue at top → fades to teal at bottom of band
      //   MIDDLE 30%: Copper/amber tone — the warm transition zone
      //   BOTTOM 35%: Teal at top → fades back to navy at bottom
      //
      // How we build this with Flutter gradients:
      //   One single vertical LinearGradient with 6 colour stops maps all
      //   three zones in sequence. stops are: 0.0, 0.35, 0.35, 0.65, 0.65, 1.0
      //   The hard-stop repeat at 0.35 and 0.65 creates the band boundaries.
      //   Each band then has its own internal fade via the colours either side.
      case QuoteCategory.warAndEpic:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'War & Epic',
          tagLine: 'HISTORY & MYTH',
          subtitle:
              'Grand narratives of struggle, honor, and the sweeping passage of time.',
          primaryColor: const Color(0xFF1A3A5C),
          lightLayers: [
            // The three-band system as a single LinearGradient:
            //   Stop 0.00: navy blue — top of card
            //   Stop 0.35: teal     — bottom of top band / top of middle
            //   Stop 0.50: copper   — center of middle band (peak warmth)
            //   Stop 0.65: teal     — bottom of middle band / top of bottom
            //   Stop 1.00: navy     — bottom of card
            GradientLayer.linear(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Color(0xCC1A2A4A), // navy blue, 80%     — top
                Color(0xAA1A4A5C), // teal, 67%          — end of top band
                Color(0x998B6040), // copper, 60%        — middle peak
                Color(0xAA1A4A5C), // teal, 67%          — start of bottom band
                Color(0xCC1A2A4A), // navy blue, 80%     — bottom
              ],
              stops: const [0.0, 0.35, 0.50, 0.65, 1.0],
            ),
          ],
        );

      // ── WIT & WISDOM ──────────────────────────────────────────────────────
      // Replacing purple — going with a cold electric teal-green.
      // Feels sharp, cerebral, like a circuit firing.
      // Top-right spark, faint warm complement bottom-left.
      case QuoteCategory.witAndWisdom:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'Wit & Wisdom',
          tagLine: 'WIT & WISDOM',
          subtitle:
              'Sharp minds, sharper words. The flash of a perfectly formed idea.',
          primaryColor: const Color(0xFF00897B),
          lightLayers: [
            // Primary: cold teal-green spark from top-right
            GradientLayer.radial(
              center: const Alignment(1.1, -1.1),
              radius: 1.5,
              colors: const [
                Color(0x8800897B), // teal-green, 53%
                Color(0x44004D40), // deep teal, 27%
                Colors.transparent,
              ],
              stops: const [0.0, 0.40, 1.0],
            ),
            // Secondary: warmer olive-teal bottom-left — contrast
            GradientLayer.radial(
              center: const Alignment(-0.9, 1.1),
              radius: 1.2,
              colors: const [
                Color(0x44006450), // deep forest teal, 27%
                Colors.transparent,
              ],
            ),
          ],
        );

      // ── SPIRITUALITY & FAITH ──────────────────────────────────────────────
      // Top: divine gold from top-center — cathedral light
      // Bottom: strong gold from bottom-right, fading weak to the left
      case QuoteCategory.spiritualityAndFaith:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'Spirituality & Faith',
          tagLine: 'FAITH',
          subtitle:
              'Light through a cathedral window and the quiet whisper of the divine.',
          primaryColor: const Color(0xFFD4A017),
          lightLayers: [
            // Top: golden bloom from top-center — original cathedral rays
            GradientLayer.radial(
              center: const Alignment(0.0, -1.4),
              radius: 1.9,
              colors: const [
                Color(0x99D4A017), // gold, 60%
                Color(0x558B6914), // amber-brown, 33%
                Colors.transparent,
              ],
              stops: const [0.0, 0.38, 1.0],
            ),
            // Bottom: strong gold from bottom-RIGHT, fades weak toward left
            // Using a LinearGradient — directional fade matches the brief
            GradientLayer.linear(
              begin: Alignment.bottomRight,
              end: Alignment.bottomLeft,
              colors: const [
                Color(0xAAD4A017), // strong gold, 67% — bottom right
                Color(0x33B8860B), // mid amber, 20%   — middle
                Colors.transparent,               //  — bottom left
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ],
        );

      default:
        return CategoryStyle(
          categoryName: category,
          displayTitle: category,
          tagLine: 'WISDOM',
          subtitle: 'Curated human wisdom across the ages.',
          primaryColor: Colors.white38,
          lightLayers: [
            GradientLayer.radial(
              center: Alignment.center,
              radius: 1.2,
              colors: const [Color(0x1AFFFFFF), Colors.transparent],
            ),
          ],
        );
    }
  }
}