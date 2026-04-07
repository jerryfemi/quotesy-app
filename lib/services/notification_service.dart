import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/quote.dart';
import '../models/streak_model.dart';
import '../theme/quotesy_theme.dart';

class NotificationDiagnostics {
  const NotificationDiagnostics({
    required this.notificationsEnabled,
    required this.canScheduleExact,
    required this.scheduleMode,
    required this.pendingCount,
    required this.dailyQuotePendingCount,
    required this.pendingSummary,
  });

  final bool? notificationsEnabled;
  final bool? canScheduleExact;
  final AndroidScheduleMode scheduleMode;
  final int pendingCount;
  final int dailyQuotePendingCount;
  final List<String> pendingSummary;
}

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
    await _setLocalTimezone();

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

    await _createAndroidChannels();
  }

  Future<void> _setLocalTimezone() async {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
    debugPrint('[NotificationService] Timezone set to: ${info.identifier}');
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _quoteChannelId,
        _quoteChannelName,
        description: _quoteChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _alertChannelId,
        _alertChannelName,
        description: _alertChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  /// Request POST_NOTIFICATIONS permission (Android 13+).
  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // On older Android versions this may return null because runtime
    // notification permission is not required.
    final notificationsGranted =
        await android?.requestNotificationsPermission() ?? true;

    // Exact alarms are needed because quote/streak schedules use
    // AndroidScheduleMode.exactAllowWhileIdle when available.
    var exactAlarmGranted = true;
    if (android != null) {
      try {
        final canExact = await (android as dynamic)
            .canScheduleExactNotifications();
        if (canExact == false) {
          exactAlarmGranted =
              await (android as dynamic).requestExactAlarmsPermission() == true;
        }
      } catch (e) {
        // Some plugin/platform combinations may not expose exact-alarm APIs.
        debugPrint(
          '[NotificationService] Exact alarm permission APIs unavailable: $e',
        );
      }
    }

    debugPrint(
      '[NotificationService] Permission status '
      '(notifications=$notificationsGranted, exactAlarms=$exactAlarmGranted)',
    );
    // Scheduling can still work with inexact mode when exact alarms are denied,
    // so this return value reflects notification visibility permission only.
    return notificationsGranted;
  }

  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;

    try {
      final canExact = await (android as dynamic)
          .canScheduleExactNotifications();
      if (canExact == false) {
        debugPrint(
          '[NotificationService] Exact alarms not permitted, using inexact scheduling.',
        );
        return AndroidScheduleMode.inexactAllowWhileIdle;
      }
    } catch (_) {
      // If platform does not expose exact-alarm checks, keep existing behavior.
    }

    return AndroidScheduleMode.exactAllowWhileIdle;
  }

  Future<NotificationDiagnostics> getDiagnostics() async {
    final pending = await _plugin.pendingNotificationRequests();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    bool? notificationsEnabled;
    bool? canScheduleExact;

    if (android != null) {
      try {
        notificationsEnabled = await (android as dynamic)
            .areNotificationsEnabled();
      } catch (_) {
        notificationsEnabled = null;
      }

      try {
        canScheduleExact = await (android as dynamic)
            .canScheduleExactNotifications();
      } catch (_) {
        canScheduleExact = null;
      }
    }

    final dailyQuotePendingCount = pending
        .where((n) => n.id >= _dailyQuoteIdBase && n.id < _dailyQuoteIdBase + 7)
        .length;
    final scheduleMode = await _resolveScheduleMode();

    final pendingSummary = pending
        .map((n) {
          final title = n.title ?? '(no title)';
          return '#${n.id}: $title';
        })
        .toList(growable: false);

    return NotificationDiagnostics(
      notificationsEnabled: notificationsEnabled,
      canScheduleExact: canScheduleExact,
      scheduleMode: scheduleMode,
      pendingCount: pending.length,
      dailyQuotePendingCount: dailyQuotePendingCount,
      pendingSummary: pendingSummary,
    );
  }

  // Reschedule-on-Open

  /// Checks whether the quote-of-the-day queue is empty (e.g. after a reboot)
  /// and rebuilds it from the provided [quotes] and [streak] data.
  /// Ensures the 7-day quote queue is full and streak reminders are current.
  /// Called on app start in the splash screen.
  Future<void> syncScheduledNotifications({
    required List<Quote> quotes,
    required StreakData streak,
    bool forceRefreshQuotes = false,
  }) async {
    final pending = await _plugin.pendingNotificationRequests();
    final dailyQuotesCount = pending
        .where((n) => n.id >= _dailyQuoteIdBase && n.id < _dailyQuoteIdBase + 7)
        .length;

    // If we have fewer than 7 days of quotes queued, top it up.

    if (forceRefreshQuotes || dailyQuotesCount < 7) {
      debugPrint(
        '[NotificationService] Sync: Refreshing 7-day quote queue '
        '(force=$forceRefreshQuotes, pending=$dailyQuotesCount)',
      );
      await scheduleDailyQuotes(quotes);
    } else {
      debugPrint(
        '[NotificationService] Sync: Quote queue is full ($dailyQuotesCount pending)',
      );
    }

    // Always refresh streak reminders on cold-start so they track the latest
    // lastOpenedDate (which just got updated by StreakNotifier.recordOpen).
    await scheduleStreakReminders(streak);
  }

  // Quote of the Day

  /// Schedules up to 7 days of quote notifications at 7 PM, using the user's
  /// filtered quote list. Cancels any previously scheduled batch first.
  Future<void> scheduleDailyQuotes(List<Quote> quotes) async {
    // 1. Cancel the old batch to avoid duplicates
    for (var i = 0; i < 7; i++) {
      await _plugin.cancel(id: _dailyQuoteIdBase + i);
    }

    if (quotes.isEmpty) {
      debugPrint(
        '[NotificationService] Cancelled queue: No quotes match filters.',
      );
      return;
    }

    // 2. Shuffle and pick up to 7
    final pool = List<Quote>.from(quotes)..shuffle(Random());
    final count = pool.length < 7 ? pool.length : 7;
    final scheduleMode = await _resolveScheduleMode();

    final now = DateTime.now();

    // 3. Find the first available 6:30 PM slot using Native DateTime
    int startDayOffset = 0;
    final today630pm = DateTime(now.year, now.month, now.day, 20, 20);
    if (today630pm.isBefore(now)) {
      startDayOffset = 1;
    }

    // 4. Schedule the rolling window
    for (var i = 0; i < count; i++) {
      final quote = pool[i];
      final intendedTime = DateTime(
        now.year,
        now.month,
        now.day + startDayOffset + i,
        20,
        20,
      );

      await _plugin.zonedSchedule(
        id: _dailyQuoteIdBase + i,
        title: 'Quote of the Day',
        body: '"${quote.text}" — ${quote.author}',
        scheduledDate: tz.TZDateTime.from(intendedTime, tz.local),
        notificationDetails: _quoteDetails(
          bigText: '"${quote.text}"\n\n— ${quote.author}',
        ),
        androidScheduleMode: scheduleMode,
      );

      debugPrint(
        '[NotificationService] Scheduled Day $i for ${intendedTime.toString()}',
      );
    }
    debugPrint(
      '[NotificationService] Success: $count moments of wisdom queued.',
    );
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

    final now = DateTime.now();
    final lastOpen = StreakData.dateOnly(streak.lastOpenedDate!);
    final streakCount = streak.currentStreak;
    final scheduleMode = await _resolveScheduleMode();

    // 1. Safety reminder at 8 PM the next day using Native DateTime
    //    e.g. opened Monday → reminder Tuesday 8 PM (4h before deadline)
    final reminderTime = DateTime(
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
        scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
        notificationDetails: _alertDetails(),
        androidScheduleMode: scheduleMode,
      );
    }

    // 2. Streak-broken alert at 9 AM the day after the deadline (Emergency)
    final breakTime = DateTime(
      lastOpen.year,
      lastOpen.month,
      lastOpen.day + 2, // two days later
      9, // 9:00 AM
    );

    if (breakTime.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: _streakBreakId,
        title: 'The light has flickered out',
        body:
            'Your streak was lost to time yesterday. '
            'Relight the flame now to restore your progress.',
        scheduledDate: tz.TZDateTime.from(breakTime, tz.local),
        notificationDetails: _alertDetails(),
        androidScheduleMode: scheduleMode,
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

  // ── Notification Details ─────────────────────────────────────────────────

  NotificationDetails _quoteDetails({String? bigText}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _quoteChannelId,
        _quoteChannelName,
        channelDescription: _quoteChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        color: QColors.amberGlow,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
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
        presentSound: true,
      ),
    );
  }

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
