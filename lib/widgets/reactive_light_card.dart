import 'package:flutter/material.dart';
import '../models/category_style.dart';

class ReactiveLightCard extends StatelessWidget {
  final CategoryStyle style;

  /// 0.0 = off-screen. 1.0 = dead center.
  final double focusAmount;

  const ReactiveLightCard({
    super.key,
    required this.style,
    required this.focusAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glowOpacity = (0.18 + (0.82 * focusAmount)).clamp(0.0, 1.0);

    final subtitleOpacity = ((focusAmount - 0.6) / 0.4).clamp(0.0, 1.0);
    final subtitleSlide = (1.0 - subtitleOpacity) * 16.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF080604),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05 + (0.12 * focusAmount)),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 24, spreadRadius: 4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            //lighting
            Opacity(
              opacity: glowOpacity,
              child: Stack(
                fit: StackFit.expand,
                children: style.lightLayers
                    .map(
                      (layer) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: layer.gradient,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            // CONTENT
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //tag
                  Text(
                    style.tagLine,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(
                        alpha: 0.35 + (0.25 * focusAmount),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Title
                  Text(
                    style.displayTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 34,
                      color: Colors.white.withValues(
                        alpha: 0.7 + (0.3 * focusAmount),
                      ),
                      height: 1.15,
                    ),
                  ),

                  // Subtitle
                  if (subtitleOpacity > 0.0) ...[
                    const SizedBox(height: 14),
                    Transform.translate(
                      offset: Offset(0, subtitleSlide),
                      child: Opacity(
                        opacity: subtitleOpacity,
                        child: Text(
                          style.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
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
