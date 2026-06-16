import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
  static const _testQuoteId = 900;

  // Channels
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
    final dynamic info = await FlutterTimezone.getLocalTimezone();
    final String identifier = info is String
        ? info
        : (info as dynamic).identifier as String;

    tz.setLocalLocation(tz.getLocation(identifier));
    debugPrint('[NotificationService] Timezone set to: $identifier');
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

  /// Request notification permissions (Android 13+ and iOS/macOS).
  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      final granted =
          await android.requestNotificationsPermission() ?? true;

      try {
        final canExact = await (android as dynamic)
            .canScheduleExactNotifications();
        if (canExact == false) {
          await (android as dynamic).requestExactAlarmsPermission();
        }
      } catch (_) {}

      debugPrint('[NotificationService] Android permissions granted=$granted');
      return granted;
    }

    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;

      debugPrint('[NotificationService] iOS permissions granted=$granted');
      return granted;
    }

    return true;
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
        return AndroidScheduleMode.inexactAllowWhileIdle;
      }
    } catch (_) {}

    return AndroidScheduleMode.exactAllowWhileIdle;
  }

  // Reschedule-on-Open

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

    await scheduleStreakReminders(streak);
  }

  // Quote of the Day

  /// Schedules up to 7 days of quote notifications at 9 AM, using the user's
  /// filtered quote list. Cancels any previously scheduled batch first.
  Future<void> scheduleDailyQuotes(List<Quote> quotes) async {
    for (var i = 0; i < 7; i++) {
      await _plugin.cancel(id: _dailyQuoteIdBase + i);
    }

    if (quotes.isEmpty) {
      debugPrint(
        '[NotificationService] Cancelled queue: No quotes match filters.',
      );
      return;
    }

    final pool = List<Quote>.from(quotes)..shuffle(Random());
    final count = pool.length < 7 ? pool.length : 7;
    final scheduleMode = await _resolveScheduleMode();

    final now = tz.TZDateTime.now(tz.local);

    var firstSlot = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (firstSlot.isBefore(now)) {
      firstSlot = firstSlot.add(const Duration(days: 1));
    }

    for (var i = 0; i < count; i++) {
      final quote = pool[i];
      final scheduleDate = firstSlot.add(Duration(days: i));

      await _plugin.zonedSchedule(
        id: _dailyQuoteIdBase + i,
        title: 'Quote of the Day',
        body: '"${quote.text}" — ${quote.author}',
        scheduledDate: scheduleDate,
        notificationDetails: _quoteDetails(
          bigText: '"${quote.text}"\n\n— ${quote.author}',
        ),
        androidScheduleMode: scheduleMode,
      );

      debugPrint(
        '[NotificationService] Scheduled Day $i for ${scheduleDate.toString()}',
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
  /// Safe to call repeatedly; always cancels old ones first.
  Future<void> scheduleStreakReminders(StreakData streak) async {
    await _plugin.cancel(id: _streakReminderId);
    await _plugin.cancel(id: _streakBreakId);

    if (streak.lastOpenedDate == null) return;

    final now = tz.TZDateTime.now(tz.local);
    final lastOpen = StreakData.dateOnly(streak.lastOpenedDate!);
    final streakCount = streak.currentStreak;
    final scheduleMode = await _resolveScheduleMode();

    final reminderTime = tz.TZDateTime(
      tz.local,
      lastOpen.year,
      lastOpen.month,
      lastOpen.day + 1,
      20,
    );

    if (reminderTime.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: _streakReminderId,
        title: _getReminderTitle(streakCount),
        body: _getReminderBody(streakCount),
        scheduledDate: reminderTime,
        notificationDetails: _alertDetails(),
        androidScheduleMode: scheduleMode,
      );
    }

    final breakTime = tz.TZDateTime(
      tz.local,
      lastOpen.year,
      lastOpen.month,
      lastOpen.day + 2,
      9,
    );

    if (breakTime.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: _streakBreakId,
        title: 'The light has flickered out',
        body:
            'Your streak was lost to time yesterday. '
            'Relight the flame now to restore your progress.',
        scheduledDate: breakTime,
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

  // ── Test Scheduling ──────────────────────────────────────────────────────

  /// Schedule a test quote notification [minutes] from now.
  Future<void> scheduleTestQuote(Quote quote, int minutes) async {
    await _plugin.cancel(id: _testQuoteId);

    final scheduledDate = tz.TZDateTime.now(tz.local).add(
      Duration(minutes: minutes),
    );
    final scheduleMode = await _resolveScheduleMode();

    await _plugin.zonedSchedule(
      id: _testQuoteId,
      title: 'Quote of the Day',
      body: '"${quote.text}" — ${quote.author}',
      scheduledDate: scheduledDate,
      notificationDetails: _quoteDetails(
        bigText: '"${quote.text}"\n\n— ${quote.author}',
      ),
      androidScheduleMode: scheduleMode,
    );

    debugPrint(
      '[NotificationService] Test notification scheduled for $scheduledDate',
    );
  }

  // ── Notification Details ─────────────────────────────────────────────────

  /// Loud notification for daily quotes — heads-up, sound, and vibration.
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
