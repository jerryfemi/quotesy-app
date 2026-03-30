import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/streak_model.dart';
import '../../theme/quotesy_theme.dart';
import 'streak_reusables.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Restore section — shown only when canRestore is true (1 missed day)
// ─────────────────────────────────────────────────────────────────────────────
class StreakRestoreSection extends ConsumerWidget {
  const StreakRestoreSection({super.key, required this.streak});
  final StreakData streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // previousStreak + missed day + today
    final restoredCount = streak.previousStreak + 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StreakSectionLabel(label: 'Restore streak'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Before → after preview row
              Row(
                children: [
                  const StreakPreviewPill(label: '1 day', isAfter: false),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: QColors.textSubtle,
                    ),
                  ),
                  StreakPreviewPill(
                    label: '$restoredCount days',
                    isAfter: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Restores your previous streak count and continues from today.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: QColors.textSubtle,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // ── TODO: wire payment flow before calling restoreStreak ──
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    ref.read(streakProvider.notifier).restoreStreak();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: QColors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Restore streak',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: QColors.obsidian,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Or continue from day 1',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: QColors.textSubtle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
