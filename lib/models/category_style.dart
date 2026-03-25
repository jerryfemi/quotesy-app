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

      
      case QuoteCategory.psychologyAndSelf:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'The Shadow',
          tagLine: 'PSYCHOLOGY & SELF',
          subtitle:
              'Journey through the hidden recesses of the psyche and the beauty of the unknown.',
          primaryColor: const Color(0xFFCCCCCC),
          lightLayers: [
            // Primary: wide soft glow from top-center — the "skylight"
            GradientLayer.radial(
              center: const Alignment(0.0, -1.6),
              radius: 1.8,
              colors: const [
                Color(0x55AAAAAA), // soft cool grey — not pure white
                Color(0x22888888),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            // Secondary: very faint base ambient so card isn't pure black
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

     
      case QuoteCategory.existential:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'Existential',
          tagLine: 'PHILOSOPHY',
          subtitle:
              'Reflections on purpose, being, and the silent weight of existence.',
          primaryColor: const Color(0xFFB8730A),
          lightLayers: [
            // Layer 1: warm amber bloom from bottom-left — the main warmth
            GradientLayer.radial(
              center: const Alignment(-0.8, 1.4),
              radius: 1.6,
              colors: const [
                Color(0xAAB8730A), // warm amber, 67% opacity
                Color(0x556B4A00), // deep burnt orange, 33%
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
            // Layer 2: cool grey-green in the upper half — the contrast tone
            GradientLayer.radial(
              center: const Alignment(0.3, -1.2),
              radius: 1.4,
              colors: const [
                Color(0x33667766), // muted grey-green, 20%
                Colors.transparent,
              ],
            ),
          ],
        );

  
      case QuoteCategory.loveAndYearning:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'Love & Yearning',
          tagLine: 'POETRY',
          subtitle:
              'The ache of distance and the intimacy of the written word.',
          primaryColor: const Color(0xFF9C6A3C),
          lightLayers: [
            // Bloom 1: top-right — brightest, the dominant light source
            GradientLayer.radial(
              center: const Alignment(1.2, -1.0),
              radius: 1.5,
              colors: const [
                Color(0xCC9C6A3C), // warm copper, 80%
                Color(0x667A4A20), // mid amber, 40%
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
            // Bloom 2: bottom-left — secondary warm source
            GradientLayer.radial(
              center: const Alignment(-1.1, 1.2),
              radius: 1.4,
              colors: const [
                Color(0x996B4226), // deep copper, 60%
                Color(0x44412010), // very dark brown, 27%
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            // Bloom 3: top-left — tertiary fill, keeps edges warm
            GradientLayer.radial(
              center: const Alignment(-1.1, -0.8),
              radius: 1.1,
              colors: const [
                Color(0x668A5A30), // muted amber, 40%
                Colors.transparent,
              ],
            ),
            // Bloom 4: bottom-right — subtle fill so no corner goes cold
            GradientLayer.radial(
              center: const Alignment(1.1, 1.1),
              radius: 1.0,
              colors: const [
                Color(0x44654020), // very faint copper, 27%
                Colors.transparent,
              ],
            ),
          ],
        );

     
      case QuoteCategory.warAndEpic:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'War & Epic',
          tagLine: 'HISTORY & MYTH',
          subtitle:
              'Grand narratives of struggle, honor, and the sweeping passage of time.',
          primaryColor: const Color(0xFF8B6040),
          lightLayers: [
            // Primary: warm brownish-orange from bottom-left
            GradientLayer.radial(
              center: const Alignment(-1.0, 1.3),
              radius: 1.6,
              colors: const [
                Color(0x998B6040), // warm brown-orange, 60%
                Color(0x55503020), // dark umber, 33%
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
            // Secondary: cool neutral upper — creates the contrast
            GradientLayer.radial(
              center: const Alignment(0.5, -1.0),
              radius: 1.3,
              colors: const [
                Color(0x22556677), // cool blue-grey, 13%
                Colors.transparent,
              ],
            ),
          ],
        );

      // ── WIT & WISDOM ──────────────────────────────────────────────────────
      // Electric indigo spark from top-right — a flash of insight.
      // Keeping the concept but calibrating opacity to not blow out.
      case QuoteCategory.witAndWisdom:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'Wit & Wisdom',
          tagLine: 'WIT & WISDOM',
          subtitle:
              'Sharp minds, sharper words. The flash of a perfectly formed idea.',
          primaryColor: const Color(0xFF7B52D4),
          lightLayers: [
            // Primary spark: top-right indigo
            GradientLayer.radial(
              center: const Alignment(1.1, -1.1),
              radius: 1.5,
              colors: const [
                Color(0x886A35D4), // indigo, 53%
                Color(0x443D1A8F), // deep purple, 27%
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
            // Faint complementary warm bottom-left so it doesn't go flat
            GradientLayer.radial(
              center: const Alignment(-0.9, 1.1),
              radius: 1.1,
              colors: const [
                Color(0x22221144),
                Colors.transparent,
              ],
            ),
          ],
        );

      // ── SPIRITUALITY & FAITH ──────────────────────────────────────────────
      // Divine gold rays from top-center — cathedral light filtering down.
      case QuoteCategory.spiritualityAndFaith:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'Spirituality & Faith',
          tagLine: 'FAITH',
          subtitle:
              'Light through a cathedral window and the quiet whisper of the divine.',
          primaryColor: const Color(0xFFD4A017),
          lightLayers: [
            // Primary: golden bloom from top-center
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
            // Warm base ambient — keeps the lower card from going cold
            GradientLayer.radial(
              center: const Alignment(0.0, 1.0),
              radius: 1.2,
              colors: const [
                Color(0x22886600),
                Colors.transparent,
              ],
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