import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _scheduledIdsKey = 'caffeine_reminder_notification_ids';
  static const _historyKey = 'wakemate_notification_history';
  static const _channelId = 'wakemate_caffeine_reminders_v2';
  static const _channelName = 'WakeMate 咖啡因提醒';
  static const _notificationIcon = 'ic_notification';
  static const _maxHistoryItems = 80;
  static const _recentPastReminderGrace = Duration(minutes: 10);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _supported = false;
  bool _notificationPermissionRequested = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _supported = true;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Taipei'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings(_notificationIcon),
    );
    await _plugin.initialize(settings: settings);
  }

  Future<void> showCalculationComplete({
    required int recommendationCount,
    required String languageCode,
  }) async {
    await initialize();
    if (!_supported) return;
    await _requestNotificationPermission();

    final text = _calculationText(languageCode, recommendationCount);
    await _plugin.show(
      id: 1001,
      title: text.title,
      body: text.body,
      notificationDetails: _notificationDetails,
      payload: 'caffeine_recommendation_ready',
    );
    await _appendHistory(
      type: 'calculation_complete',
      status: 'sent',
      title: text.title,
      body: text.body,
    );
  }

  Future<bool> showTestNotification({required String languageCode}) async {
    await initialize();
    if (!_supported) return false;
    await _requestNotificationPermission();

    final text = _testText(languageCode);
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch % 2147483647,
      title: text.title,
      body: text.body,
      notificationDetails: _notificationDetails,
      payload: 'notification_test',
    );
    await _appendHistory(
      type: 'test',
      status: 'sent',
      title: text.title,
      body: text.body,
    );
    return true;
  }

  Future<int> replaceCaffeineReminders({
    required List<dynamic> recommendations,
    required String languageCode,
  }) async {
    await initialize();
    if (!_supported) return 0;
    await _requestNotificationPermission();

    await _cancelPreviousReminders();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledIds = <int>[];

    for (var index = 0; index < recommendations.length; index++) {
      final item = recommendations[index];
      if (item is! Map) continue;

      final timestamp = item['recommended_caffeine_intake_timing']?.toString();
      final amount = _parseAmount(item['recommended_caffeine_amount']);
      if (timestamp == null || amount == null) continue;

      final parsed = DateTime.tryParse(timestamp);
      if (parsed == null) continue;

      final scheduledTime = tz.TZDateTime.from(parsed.toUtc(), tz.local);
      final id = _notificationId(scheduledTime, index);
      final text = _reminderText(languageCode, amount);

      if (!scheduledTime.isAfter(now)) {
        final minutesLate = now.difference(scheduledTime);
        if (minutesLate <= _recentPastReminderGrace) {
          await _plugin.show(
            id: id,
            title: text.title,
            body: text.body,
            notificationDetails: _notificationDetails,
            payload: 'caffeine_reminder:$timestamp',
          );
          await _appendHistory(
            type: 'caffeine_reminder',
            status: 'sent',
            title: text.title,
            body: text.body,
            scheduledAt: scheduledTime,
          );
        } else {
          await _appendHistory(
            type: 'caffeine_reminder',
            status: 'skipped_past',
            title: text.title,
            body: text.body,
            scheduledAt: scheduledTime,
          );
        }
        continue;
      }

      final scheduled = await _scheduleCaffeineReminder(
        id: id,
        title: text.title,
        body: text.body,
        scheduledTime: scheduledTime,
        payload: 'caffeine_reminder:$timestamp',
      );

      if (scheduled) {
        scheduledIds.add(id);
        await _appendHistory(
          type: 'caffeine_reminder',
          status: 'scheduled',
          title: text.title,
          body: text.body,
          scheduledAt: scheduledTime,
        );
      } else {
        await _appendHistory(
          type: 'caffeine_reminder',
          status: 'schedule_failed',
          title: text.title,
          body: text.body,
          scheduledAt: scheduledTime,
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _scheduledIdsKey,
      scheduledIds.map((id) => id.toString()).toList(),
    );
    return scheduledIds.length;
  }

  Future<int> pendingCaffeineReminderCount() async {
    await initialize();
    if (!_supported) return 0;

    final pending = await _plugin.pendingNotificationRequests();
    return pending
        .where(
          (request) =>
              request.payload?.startsWith('caffeine_reminder:') ?? false,
        )
        .length;
  }

  Future<bool> _scheduleCaffeineReminder({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      return true;
    } catch (exactError) {
      debugPrint('Exact caffeine reminder scheduling failed: $exactError');
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      return true;
    } catch (fallbackError) {
      debugPrint(
        'Fallback caffeine reminder scheduling failed: $fallbackError',
      );
      return false;
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (_notificationPermissionRequested) return;
    _notificationPermissionRequested = true;

    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await android?.requestNotificationsPermission();
  }

  Future<void> _cancelPreviousReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_scheduledIdsKey) ?? const [];

    for (final savedId in savedIds) {
      final id = int.tryParse(savedId);
      if (id != null) await _plugin.cancel(id: id);
    }

    await prefs.remove(_scheduledIdsKey);
  }

  Future<List<WakeMateNotificationLogEntry>> loadNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_historyKey) ?? '[]';

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return [];

      final entries =
          decoded
              .whereType<Map>()
              .map((item) => WakeMateNotificationLogEntry.fromJson(item))
              .whereType<WakeMateNotificationLogEntry>()
              .toList();

      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<void> clearNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> _appendHistory({
    required String type,
    required String status,
    required String title,
    required String body,
    tz.TZDateTime? scheduledAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadNotificationHistory();
    final entry = WakeMateNotificationLogEntry(
      type: type,
      status: status,
      title: title,
      body: body,
      createdAt: DateTime.now().toUtc(),
      scheduledAt: scheduledAt?.toUtc(),
    );

    final updated = [entry, ...current].take(_maxHistoryItems).toList();
    await prefs.setString(
      _historyKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }

  int _notificationId(tz.TZDateTime time, int index) {
    const maxAndroidId = 2147483647;
    return (time.millisecondsSinceEpoch ~/ 60000 + index) % maxAndroidId;
  }

  int? _parseAmount(dynamic value) {
    if (value is num) return value.round();
    return num.tryParse(value?.toString() ?? '')?.round();
  }

  _NotificationText _calculationText(String languageCode, int count) {
    switch (languageCode) {
      case 'id':
        return _NotificationText(
          'Rekomendasi WakeMate siap',
          count == 0
              ? 'Saat ini Anda tidak memerlukan kafein tambahan.'
              : '$count pengingat minum kafein telah dijadwalkan.',
        );
      case 'en':
        return _NotificationText(
          'WakeMate recommendation ready',
          count == 0
              ? 'No additional caffeine is recommended right now.'
              : '$count caffeine reminders have been scheduled.',
        );
      default:
        return _NotificationText(
          'WakeMate 推薦計算完成',
          count == 0 ? '目前沒有需要補充咖啡因。' : '已安排 $count 筆咖啡因飲用提醒。',
        );
    }
  }

  _NotificationText _reminderText(String languageCode, int amount) {
    switch (languageCode) {
      case 'id':
        return _NotificationText(
          'Pengingat kafein WakeMate',
          'Sekarang disarankan mengonsumsi $amount mg kafein.',
        );
      case 'en':
        return _NotificationText(
          'WakeMate caffeine reminder',
          'It is time for the recommended $amount mg of caffeine.',
        );
      default:
        return _NotificationText('WakeMate 咖啡因提醒', '現在建議攝取 $amount mg 咖啡因。');
    }
  }

  _NotificationText _testText(String languageCode) {
    switch (languageCode) {
      case 'id':
        return const _NotificationText(
          'Tes notifikasi WakeMate',
          'Jika pesan ini muncul, notifikasi ponsel berfungsi.',
        );
      case 'en':
        return const _NotificationText(
          'WakeMate notification test',
          'If this appears, phone notifications are working.',
        );
      default:
        return const _NotificationText(
          'WakeMate 通知測試',
          '如果看到這則通知，代表手機通知可以正常顯示。',
        );
    }
  }

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '咖啡因推薦完成及建議飲用時間提醒',
      icon: _notificationIcon,
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      ticker: 'WakeMate 咖啡因提醒',
    ),
  );
}

class _NotificationText {
  const _NotificationText(this.title, this.body);

  final String title;
  final String body;
}

class WakeMateNotificationLogEntry {
  const WakeMateNotificationLogEntry({
    required this.type,
    required this.status,
    required this.title,
    required this.body,
    required this.createdAt,
    this.scheduledAt,
  });

  final String type;
  final String status;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? scheduledAt;

  static WakeMateNotificationLogEntry? fromJson(Map<dynamic, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    if (createdAt == null) return null;

    return WakeMateNotificationLogEntry(
      type: json['type']?.toString() ?? 'unknown',
      status: json['status']?.toString() ?? 'unknown',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: createdAt,
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'status': status,
      'title': title,
      'body': body,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'scheduledAt': scheduledAt?.toUtc().toIso8601String(),
    };
  }
}
