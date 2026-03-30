import 'package:flutter/material.dart';

import '../../models/streak_model.dart';
import '../../theme/quotesy_theme.dart';

class StreakHeroBlock extends StatelessWidget {
  const StreakHeroBlock({
    super.key,
    required this.streak,
    required this.isActive,
  });
  final StreakData streak;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          color: isActive ? QColors.amberGlow : QColors.textSubtle,
          size: 42,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${streak.currentStreak}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 46,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: isActive ? QColors.amberGlow : QColors.textSubtle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'day streak',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: QColors.textSubtle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Best: ${streak.bestStreak} days',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: QColors.textSubtle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
