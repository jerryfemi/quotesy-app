import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/streak_model.dart';
import '../../theme/quotesy_theme.dart';
import '../quotesy_nav_bar.dart';
import 'streak_hero_block.dart';
import 'streak_restore_section.dart';
import 'streak_reusables.dart';
import 'streak_week_section.dart';

Future<void> showStreakSheet(BuildContext context, WidgetRef ref) async {
  final nav = NavBarControllerScope.of(context);
  nav.hide();

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 190),
        reverseDuration: Duration(milliseconds: 170),
      ),
      builder: (_) => const StreakSheet(),
    );
  } finally {
    nav.show();
  }
}

class StreakSheet extends ConsumerWidget {
  const StreakSheet({super.key});

  static const double _initialSnap = 0.62;
  static const double _maxSnap = 0.82;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);

    final isLostVisually = _isLostVisually(streak);
    final bottomPadding = MediaQuery.maybeOf(context)?.padding.bottom ?? 0;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _initialSnap,
      minChildSize: _initialSnap,
      maxChildSize: _maxSnap,
      snap: true,
      snapSizes: const [_initialSnap, _maxSnap],
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: QColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: QColors.textPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Streak',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    StreakStatusChip(isActive: !isLostVisually),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 28),
                  children: [
                    StreakHeroBlock(streak: streak, isActive: !isLostVisually),
                    const SizedBox(height: 24),
                    const StreakSheetDivider(),
                    const SizedBox(height: 24),
                    StreakWeekSection(
                      streak: streak,
                      isBroken: streak.canRestore,
                    ),
                    const SizedBox(height: 24),
                    const StreakSheetDivider(),
                    const SizedBox(height: 24),
                    /* if (streak.canRestore) ...[
                      StreakRestoreSection(streak: streak),
                      const SizedBox(height: 24),
                      const StreakSheetDivider(),
                      const SizedBox(height: 24),
                    ], */
                    StreakRulesSection(isActive: !isLostVisually),
                    if (kDebugMode && !streak.canRestore) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            ref
                                .read(streakProvider.notifier)
                                .debugBreakStreak();
                          },
                          icon: const Icon(Icons.bug_report_outlined, size: 16),
                          label: const Text('Debug: Force Break'),
                          style: TextButton.styleFrom(
                            foregroundColor: QColors.danger,
                            textStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
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
        );
      },
    );
  }

  /// Visual "streak lost" state for the status chip.
  /// Separate from [StreakData.canRestore] which controls the restore section.
  bool _isLostVisually(StreakData streak) {
    return streak.currentStreak == 1 && streak.bestStreak > 1;
  }
}
