import 'dart:ui';

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
    final glowFocus = Curves.easeOutCubic.transform(
      focusAmount.clamp(0.0, 1.0),
    );
    final glowOpacity = (0.28 + (0.72 * glowFocus)).clamp(0.0, 1.0);
    final rimAlpha = (0.10 + (0.22 * glowFocus)).clamp(0.0, 1.0);
    final focusGlowAlpha = (0.08 + (0.24 * glowFocus)).clamp(0.0, 1.0);

    final subtitleOpacity = ((focusAmount - 0.35) / 0.65).clamp(0.0, 1.0);
    final subtitleSlide =
        Curves.easeOut.transform(1.0 - subtitleOpacity) * 12.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF080604),
        border: Border.all(
          color: Colors.white.withValues(alpha: rimAlpha),
          width: 1.0,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x99000000),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: style.primaryColor.withValues(alpha: focusGlowAlpha),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: Colors.white.withValues(
                  alpha: 0.015 + (0.02 * focusAmount),
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A1A).withValues(alpha: 0.26),
                    const Color(0xFF0A0A0A).withValues(alpha: 0.62),
                  ],
                ),
              ),
            ),

            // lighting
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
                    style: theme.textTheme.labelSmall?.copyWith(
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
                      color: Colors.white.withValues(
                        alpha: 0.7 + (0.3 * focusAmount),
                      ),
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
