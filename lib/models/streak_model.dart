import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../providers/database_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StreakData — the data model stored in Hive
// ─────────────────────────────────────────────────────────────────────────────
class StreakData {
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastOpenedDate;

  /// The streak count right before the last break (0 = no break recorded).
  final int previousStreak;

  /// The last active date before the streak broke.
  final DateTime? brokenFromDate;

  const StreakData({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastOpenedDate,
    this.previousStreak = 0,
    this.brokenFromDate,
  });

  /// Whether the streak was recently broken and can be restored.
  /// The grace period lasts as long as [currentStreak] remains exactly 1.
  /// Once the user opens the app on the next consecutive day, the new streak
  /// increments to 2 and the restore window closes permanently.
  bool get canRestore =>
      previousStreak > 0 && brokenFromDate != null && currentStreak == 1;

  /// Strips time component — only the date matters for streak logic.
  /// Shared utility so every call-site uses the same implementation.
  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  StreakData copyWith({
    int? currentStreak,
    int? bestStreak,
    DateTime? lastOpenedDate,
    int? previousStreak,
    DateTime? brokenFromDate,
  }) => StreakData(
    currentStreak: currentStreak ?? this.currentStreak,
    bestStreak: bestStreak ?? this.bestStreak,
    lastOpenedDate: lastOpenedDate ?? this.lastOpenedDate,
    previousStreak: previousStreak ?? this.previousStreak,
    brokenFromDate: brokenFromDate ?? this.brokenFromDate,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// StreakNotifier
//
// Streak logic:
//   - On every app open, we compare today's date to lastOpenedDate.
//   - If same day: do nothing (already counted today).
//   - If yesterday: increment streak — user came back consecutively.
//   - If 2+ days ago: streak resets to 1 — streak broken.
//   - If never opened before: start at 1.
//
// Restore:
//   - When exactly 1 day is missed (diff == 2), the old streak is saved.
//   - Restoring fills in the missed day, making the streak continuous.
//   - If the user opens the app the next day without restoring, the broken
//     state is cleared and they continue from streak 2.
//
// Storage: Hive settings_box with five keys.
// No HiveObject needed — just primitive values.
// ─────────────────────────────────────────────────────────────────────────────
class StreakNotifier extends Notifier<StreakData> {
  static const _boxName = 'settings_box';
  static const _currentKey = 'streak_current';
  static const _bestKey = 'streak_best';
  static const _lastOpenedKey = 'streak_last_opened';
  static const _previousStreakKey = 'streak_previous';
  static const _brokenFromKey = 'streak_broken_from';

  Box get _box => Hive.box(_boxName);

  @override
  StreakData build() {
    final initState = ref.watch(databaseInitProvider);
    if (initState.isLoading || initState.hasError) {
      return const StreakData();
    }

    final current = _box.get(_currentKey, defaultValue: 0) as int;
    final best = _box.get(_bestKey, defaultValue: 0) as int;
    final lastRaw = _box.get(_lastOpenedKey) as String?;
    final lastOpened = lastRaw != null ? DateTime.tryParse(lastRaw) : null;
    final previous = _box.get(_previousStreakKey, defaultValue: 0) as int;
    final brokenRaw = _box.get(_brokenFromKey) as String?;
    final brokenFrom = brokenRaw != null ? DateTime.tryParse(brokenRaw) : null;

    return _calculateStreak(
      current: current,
      best: best,
      lastOpened: lastOpened,
      previous: previous,
      brokenFrom: brokenFrom,
    );
  }

  StreakData _calculateStreak({
    required int current,
    required int best,
    required DateTime? lastOpened,
    required int previous,
    required DateTime? brokenFrom,
  }) {
    final today = StreakData.dateOnly(DateTime.now());

    if (lastOpened == null) {
      // First ever open
      return _save(
        StreakData(currentStreak: 1, bestStreak: 1, lastOpenedDate: today),
      );
    }

    final last = StreakData.dateOnly(lastOpened);
    final diff = today.difference(last).inDays;

    if (diff == 0) {
      // Already opened today — no change, preserve broken state
      return StreakData(
        currentStreak: current,
        bestStreak: best,
        lastOpenedDate: last,
        previousStreak: previous,
        brokenFromDate: brokenFrom,
      );
    }

    if (diff == 1) {
      // Consecutive day — increment, clear any broken state
      final newCurrent = current + 1;
      final newBest = newCurrent > best ? newCurrent : best;
      return _save(
        StreakData(
          currentStreak: newCurrent,
          bestStreak: newBest,
          lastOpenedDate: today,
        ),
      );
    }

    // Streak broken (1+ days missed) — save broken state for potential restore.
    // The restore window stays open until the user builds a new streak (day 2).
    return _save(
      StreakData(
        currentStreak: 1,
        bestStreak: best,
        lastOpenedDate: today,
        previousStreak: current,
        brokenFromDate: last,
      ),
    );
  }

  /// Restores the streak as if the missed day never happened.
  /// Only works when [StreakData.canRestore] is true.
  void restoreStreak() {
    final data = state;
    if (!data.canRestore) return;

    final today = StreakData.dateOnly(DateTime.now());
    final brokenFrom = StreakData.dateOnly(data.brokenFromDate!);
    // Gap covers all missed days + today
    final daysSinceBreak = today.difference(brokenFrom).inDays;
    final restoredStreak = data.previousStreak + daysSinceBreak;
    final newBest = restoredStreak > data.bestStreak
        ? restoredStreak
        : data.bestStreak;

    state = _save(
      StreakData(
        currentStreak: restoredStreak,
        bestStreak: newBest,
        lastOpenedDate: today,
      ),
    );
  }

  /// Permanently dismisses the restore option.
  /// The user has chosen to start fresh from day 1.
  void dismissRestore() {
    final data = state;
    if (!data.canRestore) return;

    state = _save(
      StreakData(
        currentStreak: data.currentStreak,
        bestStreak: data.bestStreak,
        lastOpenedDate: data.lastOpenedDate,
        // Clear broken state — no more restore
      ),
    );
  }

  /// DEBUG ONLY: writes a fake broken streak into the real DB so the
  /// full restore → payment → restoreStreak() flow can be tested e2e.
  void debugBreakStreak() {
    state = _save(
      StreakData(
        currentStreak: 1,
        bestStreak: state.bestStreak > 20 ? state.bestStreak : 20,
        lastOpenedDate: StreakData.dateOnly(DateTime.now()),
        previousStreak: 20,
        brokenFromDate: StreakData.dateOnly(
          DateTime.now().subtract(const Duration(days: 4)),
        ),
      ),
    );
  }

  StreakData _save(StreakData data) {
    _box.putAll({
      _currentKey: data.currentStreak,
      _bestKey: data.bestStreak,
      _lastOpenedKey: data.lastOpenedDate?.toIso8601String(),
      _previousStreakKey: data.previousStreak,
      _brokenFromKey: data.brokenFromDate?.toIso8601String(),
    });
    return data;
  }
}

final streakProvider = NotifierProvider<StreakNotifier, StreakData>(
  StreakNotifier.new,
);
