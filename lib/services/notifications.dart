import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/streak_model.dart';
import 'database_service.dart';
import 'notification_service.dart';

/// Thin coordinator that exposes one clean API for app-level notification sync.
class Notifications {
  Notifications._();
  static final Notifications _instance = Notifications._();
  factory Notifications() => _instance;

  Future<bool>? _initFuture;
  DateTime? _lastSyncAt;

  Future<bool> initialize() {
    return _initFuture ??= _initializeInternal();
  }

  Future<bool> initializeAndSync({
    required DatabaseService database,
    required StreakData streak,
  }) async {
    try {
      final notificationsEnabled = await initialize();
      if (!notificationsEnabled) {
        debugPrint(
          '[Notifications] Sync skipped: notifications permission not granted.',
        );
        return false;
      }

      await _sync(
        database: database,
        streak: streak,
      );
      return true;
    } catch (error, stack) {
      debugPrint('[Notifications] initializeAndSync failed: $error\n$stack');
      return false;
    }
  }

  Future<void> resyncIfNeeded({
    required DatabaseService database,
    required StreakData streak,
    Duration minGap = const Duration(minutes: 15),
  }) async {
    final now = DateTime.now();
    if (_lastSyncAt != null && now.difference(_lastSyncAt!) < minGap) {
      return;
    }

    final notificationsEnabled = await initialize();
    if (!notificationsEnabled) return;

    await _sync(database: database, streak: streak);
  }

  Future<bool> _initializeInternal() async {
    try {
      final service = NotificationService();
      await service.init();
      return service.requestPermissions();
    } catch (error, stack) {
      debugPrint('[Notifications] Initialization failed: $error\n$stack');
      return false;
    }
  }

  Future<void> _sync({
    required DatabaseService database,
    required StreakData streak,
  }) async {
    var quotes = database.getFilteredFeed(
      selectedCategories: database.getSelectedCategories(),
      selectedAuthors: database.getSelectedAuthors(),
    );

    if (quotes.isEmpty) {
      debugPrint(
        '[Notifications] Filtered feed empty; using full quote library for scheduling.',
      );
      quotes = database.getAllQuotes();
    }

    final service = NotificationService();
    await service.syncScheduledNotifications(
      quotes: quotes,
      streak: streak,
    );

    final diagnostics = await service.getDiagnostics();
    debugPrint('[Notifications] Diagnostics start');
    debugPrint('[Notifications] enabled=${diagnostics.notificationsEnabled}');
    debugPrint('[Notifications] canExact=${diagnostics.canScheduleExact}');
    debugPrint('[Notifications] mode=${diagnostics.scheduleMode}');
    debugPrint('[Notifications] pendingTotal=${diagnostics.pendingCount}');
    debugPrint(
      '[Notifications] dailyQuotePending=${diagnostics.dailyQuotePendingCount}',
    );
    for (final item in diagnostics.pendingSummary) {
      debugPrint('[Notifications] $item');
    }
    debugPrint('[Notifications] Diagnostics end');

    _lastSyncAt = DateTime.now();
  }
}
