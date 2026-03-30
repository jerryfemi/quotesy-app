import 'package:flutter/material.dart';

import '../../models/streak_model.dart';
import '../../theme/quotesy_theme.dart';
import 'streak_reusables.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Week section — page-less week navigator with AnimatedSwitcher
// ─────────────────────────────────────────────────────────────────────────────
class StreakWeekSection extends StatefulWidget {
  const StreakWeekSection({
    super.key,
    required this.streak,
    required this.isBroken,
  });
  final StreakData streak;
  final bool isBroken;

  @override
  State<StreakWeekSection> createState() => _StreakWeekSectionState();
}

class _StreakWeekSectionState extends State<StreakWeekSection> {
  late List<DateTime> _weekStarts;
  late int _weekIndex;

  @override
  void initState() {
    super.initState();
    _weekStarts = _buildWeekStarts();
    _weekIndex = _weekStarts.length - 1;
  }

  @override
  void didUpdateWidget(covariant StreakWeekSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _weekStarts = _buildWeekStarts();
    _weekIndex = _weekIndex.clamp(0, _weekStarts.length - 1);
  }

  DateTime _mondayOf(DateTime dt) {
    final day = StreakData.dateOnly(dt);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  List<DateTime> _buildWeekStarts() {
    final today = StreakData.dateOnly(DateTime.now());
    final currentWeekMonday = _mondayOf(today);

    final lastOpened = widget.streak.lastOpenedDate != null
        ? StreakData.dateOnly(widget.streak.lastOpenedDate!)
        : today;

    final streakLength = widget.streak.currentStreak < 1
        ? 1
        : widget.streak.currentStreak;
    final streakStart = lastOpened.subtract(Duration(days: streakLength - 1));

    DateTime earliestTrackedDay = streakStart;
    if (widget.isBroken) {
      final missedDay = today.subtract(const Duration(days: 1));
      if (missedDay.isBefore(earliestTrackedDay)) {
        earliestTrackedDay = missedDay;
      }
    }

    final earliestWeekMonday = _mondayOf(earliestTrackedDay);
    final weeks =
        (currentWeekMonday.difference(earliestWeekMonday).inDays ~/ 7) + 1;

    return List.generate(
      weeks,
      (i) => earliestWeekMonday.add(Duration(days: i * 7)),
    );
  }

  String _weekLabel(DateTime weekStart) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startMonth = months[weekStart.month - 1];
    final endMonth = months[weekEnd.month - 1];
    return '$startMonth ${weekStart.day} – $endMonth ${weekEnd.day}';
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _weekStarts[_weekIndex];
    final hasMultipleWeeks = _weekStarts.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StreakSectionLabel(label: 'Weekly streak'),
        const SizedBox(height: 8),
        Row(
          children: [
            if (hasMultipleWeeks)
              _ChevronButton(
                icon: Icons.chevron_left_rounded,
                enabled: _weekIndex > 0,
                onTap: () => setState(() => _weekIndex--),
              ),
            Expanded(
              child: Text(
                _weekLabel(weekStart),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: QColors.textSubtle,
                ),
                textAlign:
                    hasMultipleWeeks ? TextAlign.center : TextAlign.start,
              ),
            ),
            if (hasMultipleWeeks)
              _ChevronButton(
                icon: Icons.chevron_right_rounded,
                enabled: _weekIndex < _weekStarts.length - 1,
                onTap: () => setState(() => _weekIndex++),
              ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _WeekStrip(
            key: ValueKey(weekStart),
            weekStart: weekStart,
            streak: widget.streak,
            isBroken: widget.isBroken,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chevron button
// ─────────────────────────────────────────────────────────────────────────────
class _ChevronButton extends StatelessWidget {
  const _ChevronButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? QColors.textSubtle
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Week strip — Mon–Sun row with pre-computed streak bounds
// ─────────────────────────────────────────────────────────────────────────────
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    super.key,
    required this.weekStart,
    required this.streak,
    required this.isBroken,
  });
  final DateTime weekStart;
  final StreakData streak;
  final bool isBroken;

  @override
  Widget build(BuildContext context) {
    final today = StreakData.dateOnly(DateTime.now());

    // Pre-compute streak bounds once — not per cell
    final last = streak.lastOpenedDate != null
        ? StreakData.dateOnly(streak.lastOpenedDate!)
        : null;
    final streakLength = streak.currentStreak < 1 ? 1 : streak.currentStreak;
    final streakStart = last?.subtract(Duration(days: streakLength - 1));
    final missedDay = isBroken ? today.subtract(const Duration(days: 1)) : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        return _DayCell(
          day: day,
          today: today,
          streakStart: streakStart,
          streakEnd: last,
          missedDay: missedDay,
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day cell — receives pre-computed bounds instead of raw StreakData
// ─────────────────────────────────────────────────────────────────────────────
enum _DayCellState { todayActive, todayBroken, done, missed, empty, future }

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.streakStart,
    required this.streakEnd,
    required this.missedDay,
  });
  final DateTime day;
  final DateTime today;
  final DateTime? streakStart;
  final DateTime? streakEnd;
  final DateTime? missedDay;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final label = labels[day.weekday - 1];
    final isToday = day == today;
    final isFuture = day.isAfter(today);

    final isDone = !isFuture &&
        streakStart != null &&
        streakEnd != null &&
        !day.isBefore(streakStart!) &&
        !day.isAfter(streakEnd!);
    final isMissed = missedDay != null && day == missedDay;

    _DayCellState cellState;
    if (isToday) {
      cellState =
          isDone ? _DayCellState.todayActive : _DayCellState.todayBroken;
    } else if (isMissed) {
      cellState = _DayCellState.missed;
    } else if (isFuture) {
      cellState = _DayCellState.future;
    } else if (isDone) {
      cellState = _DayCellState.done;
    } else {
      cellState = _DayCellState.empty;
    }

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isToday ? QColors.amberGlow : QColors.textSubtle,
          ),
        ),
        const SizedBox(height: 7),
        _DotWidget(state: cellState),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot widget
// ─────────────────────────────────────────────────────────────────────────────
class _DotWidget extends StatelessWidget {
  const _DotWidget({required this.state});
  final _DayCellState state;

  @override
  Widget build(BuildContext context) {
    const size = 32.0;

    switch (state) {
      case _DayCellState.todayActive:
        return const SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(Icons.check_rounded, size: 20, color: QColors.amberGlow),
          ),
        );

      case _DayCellState.todayBroken:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
        );

      case _DayCellState.done:
        return const SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(Icons.check_rounded, size: 18, color: QColors.amberGlow),
          ),
        );

      case _DayCellState.missed:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: QColors.dangerMid, width: 1.25),
          ),
          child: const Center(
            child: SizedBox(
              width: 7,
              height: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: QColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );

      case _DayCellState.empty:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
              width: 1,
            ),
          ),
        );

      case _DayCellState.future:
        return const SizedBox(width: size, height: size);
    }
  }
}
