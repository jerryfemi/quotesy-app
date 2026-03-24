import 'package:flutter/material.dart';
import '../services/database_service.dart';

class GradientLayer {
  final Gradient gradient;
  const GradientLayer(this.gradient);


  /// A soft radial bloom — for corner glows and spotlights.
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

  /// A sharp linear beam — for directional light like The Shadow.
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

// CategoryStyle

class CategoryStyle {
  final String categoryName;
  final String displayTitle;  // Human-readable card title
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
          subtitle: 'Journey through the hidden recesses of the psyche and the beauty of the unknown.',
          primaryColor: Colors.white,
          lightLayers: [
            GradientLayer.linear(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [Color(0x26FFFFFF), Colors.transparent, Color(0x0DFFFFFF)],
              stops: const [0.0, 0.45, 1.0],
            ),
          ],
        );

      case QuoteCategory.existential:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'Existential',
          tagLine: 'PHILOSOPHY',
          subtitle: 'Reflections on purpose, being, and the silent weight of existence.',
          primaryColor: const Color(0xFFB8730A),
          lightLayers:  [
            GradientLayer.radial(
              center: Alignment(0.0, 1.4),
              radius: 1.6,
              colors: [Color(0x8CB8730A), Color(0x406B4A00), Colors.transparent],
              stops: [0.0, 0.4, 1.0],
            ),
          ],
        );

      case QuoteCategory.loveAndYearning:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'Love & Yearning',
          tagLine: 'POETRY',
          subtitle: 'The ache of distance and the intimacy of the written word.',
          primaryColor: const Color(0xFF9C6A3C),
          lightLayers:  [
            GradientLayer.radial(
              center: Alignment(1.1, -1.1),
              radius: 1.6,
              colors: [Color(0xBF9C6A3C), Colors.transparent],
            ),
            GradientLayer.radial(
              center: Alignment(-1.0, 1.2),
              radius: 1.3,
              colors: [Color(0x8C6B4226), Colors.transparent],
            ),
            GradientLayer.radial(
              center: Alignment(-1.2, -0.9),
              radius: 0.9,
              colors: [Color(0x408A5A30), Colors.transparent],
            ),
          ],
        );

      case QuoteCategory.warAndEpic:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'War & Epic',
          tagLine: 'WAR & EPIC',
          subtitle: 'Courage forged in fire. Words that survived the battlefield.',
          primaryColor: const Color(0xFFB0C4DE),
          lightLayers:  [
            GradientLayer.linear(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.transparent, Color(0x4D7A8FA6), Colors.transparent],
              stops: [0.0, 0.5, 1.0],
            ),
          ],
        );

      case QuoteCategory.witAndWisdom:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'Wit & Wisdom',
          tagLine: 'WIT & WISDOM',
          subtitle: 'Sharp minds, sharper words. The flash of a perfectly formed idea.',
          primaryColor: const Color(0xFF7B52D4),
          lightLayers:  [
            GradientLayer.radial(
              center: Alignment(1.1, -1.1),
              radius: 1.4,
              colors: [Color(0x806A35D4), Color(0x333D1A8F), Colors.transparent],
              stops: [0.0, 0.35, 1.0],
            ),
          ],
        );

      case QuoteCategory.spiritualityAndFaith:
        return CategoryStyle(
          categoryName: category,
          displayTitle: 'Spirituality & Faith',
          tagLine: 'FAITH',
          subtitle: 'Light through a cathedral window and the quiet whisper of the divine.',
          primaryColor: const Color(0xFFD4A017),
          lightLayers:  [
            GradientLayer.radial(
              center: Alignment(0.0, -1.3),
              radius: 1.8,
              colors: [Color(0x73D4A017), Color(0x338B6914), Colors.transparent],
              stops: [0.0, 0.4, 1.0],
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
              colors: [Color(0x1AFFFFFF), Colors.transparent],
            ),
          ],
        );
    }
  }
}