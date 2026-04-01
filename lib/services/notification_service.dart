import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/quote.dart';
import '../models/streak_model.dart';
import '../theme/quotesy_theme.dart';

/// Central notification engine for Quotesy.
///
/// Singleton — call `NotificationService()` anywhere to get the same instance.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Notification ID ranges
  static const _dailyQuoteIdBase = 100; // 100-106
  static const _streakReminderId = 200;
  static const _streakBreakId = 201;
  static const _instantAlertId = 300;

  // Channels — Dark Academia/Obsidian Naming
  static const _quoteChannelId = 'quotesy_daily_quote';
  static const _quoteChannelName = 'Daily Quote';
  static const _quoteChannelDesc = 'Your daily dose of inspiration.';

  static const _alertChannelId = 'quotesy_streak_alerts';
  static const _alertChannelName = 'Streak Alerts';
  static const _alertChannelDesc = 'Protect your dedication and habit.';

  // Initialization

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: (_) {
        // v2: deep-link to specific quote
      },
    );
  }

  /// Request POST_NOTIFICATIONS permission (Android 13+).
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  // Reschedule-on-Open

  /// Checks whether the quote-of-the-day queue is empty (e.g. after a reboot)
  /// and rebuilds it from the provided [quotes] and [streak] data.
  Future<void> syncScheduledNotifications({
    required List<Quote> quotes,
    required StreakData streak,
  }) async {
    final pending = await _plugin.pendingNotificationRequests();
    final hasDailyQuotes = pending.any(
      (n) => n.id >= _dailyQuoteIdBase && n.id < _dailyQuoteIdBase + 7,
    );

    if (!hasDailyQuotes) {
      debugPrint('[NotificationService] Sync: rescheduling daily quotes');
      await scheduleDailyQuotes(quotes);
    }

    // Always refresh streak reminders on cold-start so they track the latest
    // lastOpenedDate (which just got updated by StreakNotifier.recordOpen).
    await scheduleStreakReminders(streak);
  }

  // Quote of the Day

  /// Schedules up to 7 days of quote notifications at 9 AM, using the user's
  /// filtered quote list. Cancels any previously scheduled batch first.
  Future<void> scheduleDailyQuotes(List<Quote> quotes) async {
    // Cancel the old batch
    for (var i = 0; i < 7; i++) {
      await _plugin.cancel(id: _dailyQuoteIdBase + i);
    }
    if (quotes.isEmpty) return;

    // Shuffle and pick up to 7
    final pool = List<Quote>.from(quotes)..shuffle(Random());
    final count = pool.length < 7 ? pool.length : 7;

    final now = tz.TZDateTime.now(tz.local);

    for (var i = 0; i < count; i++) {
      final quote = pool[i];
      var scheduleDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + i,
        9, // 9:00 AM
      );

      // If it's already past 9 AM today, push the first slot to tomorrow
      if (i == 0 && scheduleDate.isBefore(now)) {
        scheduleDate = scheduleDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: _dailyQuoteIdBase + i,
        title: 'Quote of the Day',
        body: '"${quote.text}" — ${quote.author}',
        scheduledDate: scheduleDate,
        notificationDetails: _quoteDetails(
          bigText: '"${quote.text}"\n\n— ${quote.author}',
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    debugPrint('[NotificationService] Scheduled $count moments of wisdom');
  }

  // Streak Reminders

  /// Schedules two streak notifications anchored to calendar-day boundaries:
  ///   • **8 PM next day** — "Protect your flame" (escalating tone)
  ///   • **9 AM day after** — "Streak broken" alert
  ///
  /// Uses fixed clock times (not raw offsets) because the streak model
  /// stores `lastOpenedDate` as date-only (midnight).
  ///
  /// Safe to call repeatedly; always cancels old ones first.
  Future<void> scheduleStreakReminders(StreakData streak) async {
    await _plugin.cancel(id: _streakReminderId);
    await _plugin.cancel(id: _streakBreakId);

    if (streak.lastOpenedDate == null) return;

    final now = tz.TZDateTime.now(tz.local);
    final lastOpen = StreakData.dateOnly(streak.lastOpenedDate!);
    final streakCount = streak.currentStreak;

    // 1. Safety reminder at 8 PM the next day
    //    e.g. opened Monday → reminder Tuesday 8 PM (4h before deadline)
    final reminderTime = tz.TZDateTime(
      tz.local,
      lastOpen.year,
      lastOpen.month,
      lastOpen.day + 1, // next day
      20, // 8:00 PM
    );

    if (reminderTime.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: _streakReminderId,
        title: _getReminderTitle(streakCount),
        body: _getReminderBody(streakCount),
        scheduledDate: reminderTime,
        notificationDetails: _alertDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    // 2. Streak-broken alert at 9 AM the day after the deadline (Emergency)
    final breakTime = tz.TZDateTime(
      tz.local,
      lastOpen.year,
      lastOpen.month,
      lastOpen.day + 2, // two days later
      9, // 9:00 AM
    );

    if (breakTime.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: _streakBreakId,
        title: 'The light has flickered out',
        body: 'Your streak was lost to time yesterday. '
            'Relight the flame now to restore your progress.',
        scheduledDate: breakTime,
        notificationDetails: _alertDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    debugPrint(
      '[NotificationService] Streak reminders set '
      '(count=$streakCount, reminder=$reminderTime, break=$breakTime)',
    );
  }

  // Instant Alerts

  /// Fire-and-forget notification (e.g. "Streak Restored!").
  Future<void> showInstantAlert(String title, String body) async {
    await _plugin.show(
      id: _instantAlertId,
      title: title,
      body: body,
      notificationDetails: _alertDetails(),
    );
  }

  // Escalating Messaging

  String _getReminderTitle(int count) {
    if (count <= 1) return 'Start your journey 🕯️';
    if (count < 7) return 'Keep the flame alive 🔥';
    return 'Protect your flame 🔥';
  }

  String _getReminderBody(int count) {
    if (count <= 1) {
      return 'The first step is the hardest. '
          'Open Quotesy to keep your day-1 habit alive.';
    }
    if (count < 7) {
      return "You're building something great. "
          "Don't let your $count-day streak flicker out!";
    }
    return 'Impressive dedication. '
        "Don't let $count days of wisdom slip away tonight!";
  }

  // Notification Details — Quiet (Quotes) vs. Loud (Alerts)

  // ── Debug Testing ────────────────────────────────────────────────────────

  /// Immediate fire of a "daily quote" style notification.
  Future<void> testDailyQuote() async {
    const testText = 'The only way to do great work is to love what you do.';
    const testAuthor = 'Steve Jobs';
    await _plugin.show(
      id: 999,
      title: 'Quote of the Day',
      body: '"$testText" — $testAuthor',
      notificationDetails: _quoteDetails(
        bigText: '"$testText"\n\n— $testAuthor',
      ),
    );
  }

  /// Immediate fire of an 8 PM-style streak reminder.
  Future<void> testStreakReminder() async {
    await _plugin.show(
      id: 998,
      title: 'Keep the flame alive 🔥',
      body: "Don't let your 7-day streak flicker out!",
      notificationDetails: _alertDetails(),
    );
  }

  /// Immediate fire of a 9 AM-style streak break alarm.
  Future<void> testStreakBreak() async {
    await _plugin.show(
      id: 997,
      title: 'The flame has gone out',
      body: 'Your streak was lost to time yesterday. '
          'Relight the flame now to restore your progress.',
      notificationDetails: _alertDetails(),
    );
  }

  /// Immediate fire of a success alert.
  Future<void> testStreakRestored() async {
    await showInstantAlert(
      'Streak Restored!',
      'You are back to a 7-day streak.',
    );
  }

  // ── Notification Details ─────────────────────────────────────────────────

  /// Quiet notification for daily quotes — no heads-up, no vibration.
  NotificationDetails _quoteDetails({String? bigText}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _quoteChannelId,
        _quoteChannelName,
        channelDescription: _quoteChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: QColors.amberGlow,
        styleInformation: bigText != null
            ? BigTextStyleInformation(
                bigText,
                contentTitle: 'Quote of the Day',
                summaryText: 'Daily Inspiration',
              )
            : null,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      ),
    );
  }

  /// Loud notification for streak alerts — heads-up, vibration, full priority.
  NotificationDetails _alertDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _alertChannelId,
        _alertChannelName,
        channelDescription: _alertChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        color: QColors.amberGlow,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
