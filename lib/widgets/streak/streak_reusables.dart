import 'package:flutter/material.dart';

import '../../theme/quotesy_theme.dart';

class StreakStatusChip extends StatelessWidget {
  const StreakStatusChip({super.key, required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? QColors.amberSubtle : QColors.dangerSubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? QColors.amber.withValues(alpha: 0.35)
              : QColors.dangerBorder,
          width: 0.5,
        ),
      ),
      child: Text(
        isActive ? 'Active' : 'Streak lost',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? QColors.amberGlow : QColors.danger,
        ),
      ),
    );
  }
}

class StreakPreviewPill extends StatelessWidget {
  const StreakPreviewPill({
    super.key,
    required this.label,
    required this.isAfter,
  });
  final String label;
  final bool isAfter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAfter
            ? QColors.amberSubtle
            : QColors.textPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isAfter ? QColors.amberGlow : QColors.textSubtle,
        ),
      ),
    );
  }
}

class StreakSectionLabel extends StatelessWidget {
  const StreakSectionLabel({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
        color: QColors.textSubtle,
      ),
    );
  }
}

class StreakSheetDivider extends StatelessWidget {
  const StreakSheetDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: QColors.textPrimary.withValues(alpha: 0.06),
    );
  }
}

class StreakRuleLine extends StatelessWidget {
  const StreakRuleLine({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: SizedBox(
            width: 4,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: QColors.textSubtle,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: QColors.textSubtle,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class StreakRulesSection extends StatelessWidget {
  const StreakRulesSection({super.key, required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StreakSectionLabel(label: 'How it works'),
        const SizedBox(height: 10),
        const StreakRuleLine(
          text: 'Open the app once a day to keep your streak going.',
        ),
        const SizedBox(height: 7),
        StreakRuleLine(
          text: isActive
              ? 'Missing a full day resets your streak, but your best stays.'
              : 'Restoring returns your previous streak count from before the break.',
        ),
      ],
    );
  }
}
