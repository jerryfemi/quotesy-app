import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StreakData — the data model stored in Hive
// ─────────────────────────────────────────────────────────────────────────────
class StreakData {
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastOpenedDate;

  const StreakData({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastOpenedDate,
  });

  StreakData copyWith({
    int? currentStreak,
    int? bestStreak,
    DateTime? lastOpenedDate,
  }) =>
      StreakData(
        currentStreak: currentStreak ?? this.currentStreak,
        bestStreak: bestStreak ?? this.bestStreak,
        lastOpenedDate: lastOpenedDate ?? this.lastOpenedDate,
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
// Storage: Hive settings_box with three keys.
// No HiveObject needed — just primitive values.
// ─────────────────────────────────────────────────────────────────────────────
class StreakNotifier extends Notifier<StreakData> {
  static const _boxName        = 'settings_box';
  static const _currentKey     = 'streak_current';
  static const _bestKey        = 'streak_best';
  static const _lastOpenedKey  = 'streak_last_opened';

  Box get _box => Hive.box(_boxName);

  @override
  StreakData build() {
    final current    = _box.get(_currentKey,    defaultValue: 0) as int;
    final best       = _box.get(_bestKey,       defaultValue: 0) as int;
    final lastRaw    = _box.get(_lastOpenedKey) as String?;
    final lastOpened = lastRaw != null ? DateTime.tryParse(lastRaw) : null;

    // Run the streak update on first build (i.e. on app open)
    return _calculateStreak(
      current: current,
      best: best,
      lastOpened: lastOpened,
    );
  }

  StreakData _calculateStreak({
    required int current,
    required int best,
    required DateTime? lastOpened,
  }) {
    final today = _dateOnly(DateTime.now());

    if (lastOpened == null) {
      // First ever open
      return _save(StreakData(
        currentStreak: 1,
        bestStreak: 1,
        lastOpenedDate: today,
      ));
    }

    final last = _dateOnly(lastOpened);
    final diff = today.difference(last).inDays;

    if (diff == 0) {
      // Already opened today — no change
      return StreakData(
        currentStreak: current,
        bestStreak: best,
        lastOpenedDate: last,
      );
    }

    if (diff == 1) {
      // Consecutive day — increment
      final newCurrent = current + 1;
      final newBest    = newCurrent > best ? newCurrent : best;
      return _save(StreakData(
        currentStreak: newCurrent,
        bestStreak: newBest,
        lastOpenedDate: today,
      ));
    }

    // Streak broken — reset to 1
    return _save(StreakData(
      currentStreak: 1,
      bestStreak: best, // best streak is never reduced
      lastOpenedDate: today,
    ));
  }

  StreakData _save(StreakData data) {
    _box.put(_currentKey,    data.currentStreak);
    _box.put(_bestKey,       data.bestStreak);
    _box.put(_lastOpenedKey, data.lastOpenedDate?.toIso8601String());
    return data;
  }

  /// Strips time component — only the date matters for streak logic.
  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

final streakProvider = NotifierProvider<StreakNotifier, StreakData>(
  StreakNotifier.new,
);