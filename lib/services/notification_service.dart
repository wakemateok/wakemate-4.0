import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _scheduledIdsKey = 'caffeine_reminder_notification_ids';
  static const _channelId = 'wakemate_caffeine_reminders';
  static const _channelName = 'WakeMate 咖啡因提醒';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _supported = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _supported = true;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Taipei'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
    );
    await _plugin.initialize(settings: settings);

    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  Future<void> showCalculationComplete({
    required int recommendationCount,
    required String languageCode,
  }) async {
    await initialize();
    if (!_supported) return;

    final text = _calculationText(languageCode, recommendationCount);
    await _plugin.show(
      id: 1001,
      title: text.title,
      body: text.body,
      notificationDetails: _notificationDetails,
      payload: 'caffeine_recommendation_ready',
    );
  }

  Future<int> replaceCaffeineReminders({
    required List<dynamic> recommendations,
    required String languageCode,
  }) async {
    await initialize();
    if (!_supported) return 0;

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
      if (!scheduledTime.isAfter(now)) continue;

      final id = _notificationId(scheduledTime, index);
      final text = _reminderText(languageCode, amount);

      await _plugin.zonedSchedule(
        id: id,
        title: text.title,
        body: text.body,
        scheduledDate: scheduledTime,
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'caffeine_reminder:$timestamp',
      );
      scheduledIds.add(id);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _scheduledIdsKey,
      scheduledIds.map((id) => id.toString()).toList(),
    );
    return scheduledIds.length;
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

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '咖啡因推薦完成及建議飲用時間提醒',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    ),
  );
}

class _NotificationText {
  const _NotificationText(this.title, this.body);

  final String title;
  final String body;
}
