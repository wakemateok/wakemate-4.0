import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  @visibleForTesting
  NotificationService.forTesting();

  static final NotificationService instance = NotificationService._();

  static const _scheduledIdsKey = 'caffeine_reminder_notification_ids';
  static const _historyKey = 'wakemate_notification_history';
  static const _channelIdBase = 'wakemate_caffeine_reminders_v2';
  static const _notificationIcon = 'ic_notification';
  static const _maxHistoryItems = 80;
  static const _recentPastReminderGrace = Duration(minutes: 10);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _supported = false;
  bool _notificationPermissionRequested = false;
  Future<void>? _initializing;
  Future<void> _operationTail = Future<void>.value();

  Future<T> _runExclusive<T>(Future<T> Function() operation) {
    final result = _operationTail.then((_) => operation());
    _operationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= _initialize().whenComplete(
      () => _initializing = null,
    );
  }

  Future<void> _initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _initialized = true;
      return;
    }

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Taipei'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings(_notificationIcon),
    );
    final initialized = await _plugin.initialize(settings: settings);
    if (initialized != true) {
      throw PlatformException(code: 'notification_initialization_failed');
    }
    try {
      await _retireScheduledTests();
    } catch (error) {
      debugPrint('Retired diagnostic cleanup could not finish: $error');
    }
    _supported = true;
    _initialized = true;
  }

  Future<void> showCalculationComplete({
    required int recommendationCount,
    required String languageCode,
    int? scheduledCount,
  }) => _runExclusive(() async {
    await initialize();
    if (!_supported) return;
    await _requestNotificationPermission();

    final text = _calculationText(
      languageCode,
      recommendationCount,
      scheduledCount ?? recommendationCount,
    );
    await _plugin.show(
      id: 1001,
      title: text.title,
      body: text.body,
      notificationDetails: _notificationDetails(languageCode),
      payload: 'caffeine_recommendation_ready',
    );
    await _appendHistory(
      type: 'calculation_complete',
      status: 'sent',
      title: text.title,
      body: text.body,
    );
  });

  Future<bool> showTestNotification({required String languageCode}) =>
      _runExclusive(() async {
        await initialize();
        if (!_supported) return false;
        await _requestNotificationPermission();

        final text = _testText(languageCode);
        await _plugin.show(
          id: DateTime.now().millisecondsSinceEpoch % 2147483647,
          title: text.title,
          body: text.body,
          notificationDetails: _notificationDetails(languageCode),
          payload: 'notification_test',
        );
        await _appendHistory(
          type: 'test',
          status: 'sent',
          title: text.title,
          body: text.body,
        );
        return true;
      });

  Future<NotificationReadiness> notificationReadiness({
    String languageCode = 'zh',
  }) async {
    await initialize();
    if (!_supported) return const NotificationReadiness();
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    final channels = await android?.getNotificationChannels();
    final caffeineChannel = channels?.where(
      (channel) => channel.id == _channelId(languageCode),
    );
    return NotificationReadiness(
      notificationsEnabled: await android?.areNotificationsEnabled(),
      exactAlarmsAllowed: await android?.canScheduleExactNotifications(),
      caffeineChannelEnabled:
          caffeineChannel == null || caffeineChannel.isEmpty
              ? null
              : caffeineChannel.first.importance != Importance.none,
    );
  }

  Future<bool> requestExactReminderPermission({
    required String languageCode,
  }) => _runExclusive(() async {
    await initialize();
    if (!_supported) return false;
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (await android?.canScheduleExactNotifications() != true &&
        await android?.requestExactAlarmsPermission() != true) {
      return false;
    }
    // Permission changes do not upgrade existing inexact alarms automatically.
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payload = request.payload ?? '';
      const prefix = 'caffeine_reminder:';
      if (!payload.startsWith(prefix)) continue;
      final parsed = DateTime.tryParse(payload.substring(prefix.length));
      if (parsed == null || !parsed.isAfter(DateTime.now())) continue;
      final precision = await _scheduleCaffeineReminder(
        id: request.id,
        title: request.title ?? '',
        body: request.body ?? '',
        languageCode: languageCode,
        scheduledTime: tz.TZDateTime.from(parsed.toUtc(), tz.local),
        payload: payload,
      );
      final prefs = await SharedPreferences.getInstance();
      final history = await loadNotificationHistory();
      await prefs.setString(
        _historyKey,
        jsonEncode(
          history.map((entry) {
            final json = entry.toJson();
            final id =
                entry.reminderKey == null
                    ? null
                    : _notificationId(entry.reminderKey!);
            if (id == request.id && entry.scheduledAt == parsed.toUtc()) {
              json['status'] = _scheduleStatus(precision);
            }
            return json;
          }).toList(),
        ),
      );
    }
    return true;
  });

  Future<void> reconcileVisibleNotifications() => _runExclusive(() async {
    await initialize();
    if (!_supported) return;
    final active = await _plugin.getActiveNotifications();
    if (active.isEmpty) return;
    final history = await loadNotificationHistory();
    var changed = false;
    // Android's plugin result has no payload. Reminder IDs include account/time.
    final updated =
        history.map((entry) {
          final json = entry.toJson();
          final id =
              entry.type == 'caffeine_reminder' && entry.reminderKey != null
                  ? _notificationId(entry.reminderKey!)
                  : null;
          if (id != null &&
              entry.scheduledAt != null &&
              active.any(
                (notification) =>
                    notification.id == id &&
                    notification.title == entry.title &&
                    notification.body == entry.body,
              )) {
            json['status'] = 'posted';
            changed = changed || entry.status != 'posted';
          }
          return json;
        }).toList();
    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, jsonEncode(updated));
    }
  });

  String _scheduleStatus(ReminderSchedulePrecision? precision) =>
      switch (precision) {
        ReminderSchedulePrecision.exact => 'scheduled',
        ReminderSchedulePrecision.inexact => 'scheduled_inexact',
        null => 'schedule_failed',
      };

  Future<int> replaceCaffeineReminders({
    required List<dynamic> recommendations,
    required String languageCode,
    String userId = '',
  }) => _runExclusive(() async {
    await initialize();
    if (!_supported) return 0;
    await _requestNotificationPermission();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledIds = <int>[];
    final seen = <String>{};
    final plans =
        <
          ({
            int id,
            String key,
            String timestamp,
            tz.TZDateTime time,
            _NotificationText text,
          })
        >[];

    for (final item in recommendations) {
      if (item is! Map) continue;

      final timestamp = item['recommended_caffeine_intake_timing']?.toString();
      final amount = _parseAmount(item['recommended_caffeine_amount']);
      if (timestamp == null || amount == null || amount <= 0 || amount > 500) {
        continue;
      }

      final parsed = DateTime.tryParse(timestamp);
      if (parsed == null) continue;

      final scheduledTime = tz.TZDateTime.from(parsed.toUtc(), tz.local);
      final reminderKey = '$userId|${scheduledTime.toUtc().toIso8601String()}';
      if (!seen.add(reminderKey)) continue;
      final id = _notificationId(reminderKey);
      final text = _reminderText(languageCode, amount);
      plans.add((
        id: id,
        key: reminderKey,
        timestamp: timestamp,
        time: scheduledTime,
        text: text,
      ));
    }

    final pending = await _plugin.pendingNotificationRequests();
    final retainedIds = <int>{};
    for (final plan in plans) {
      if (now.difference(plan.time) > _recentPastReminderGrace) continue;
      if (pending.any(
        (request) =>
            request.id == plan.id &&
            request.title == plan.text.title &&
            request.body == plan.text.body &&
            request.payload?.startsWith('caffeine_reminder:') == true &&
            DateTime.tryParse(
                  request.payload!.substring('caffeine_reminder:'.length),
                )?.toUtc() ==
                plan.time.toUtc(),
      )) {
        retainedIds.add(plan.id);
      }
    }

    // An unchanged, overdue alarm may still be waiting for Android's inexact
    // delivery. Cancelling it here would lose it without a replacement.
    await _cancelPreviousReminders(retainIds: retainedIds);
    final previousHistory = await loadNotificationHistory();
    for (final plan in plans) {
      final id = plan.id;
      final reminderKey = plan.key;
      final timestamp = plan.timestamp;
      final scheduledTime = plan.time;
      final text = plan.text;
      final wasPosted = previousHistory.any(
        (entry) =>
            entry.type == 'caffeine_reminder' &&
            entry.reminderKey == reminderKey &&
            entry.title == text.title &&
            entry.body == text.body &&
            entry.status == 'posted',
      );
      if (retainedIds.contains(id) && !scheduledTime.isAfter(now)) {
        scheduledIds.add(id);
        await _appendHistory(
          type: 'caffeine_reminder',
          status: wasPosted ? 'posted' : 'due_unconfirmed',
          title: text.title,
          body: text.body,
          scheduledAt: scheduledTime,
          reminderKey: reminderKey,
        );
        continue;
      }

      if (!scheduledTime.isAfter(now)) {
        final minutesLate = now.difference(scheduledTime);
        if (minutesLate <= _recentPastReminderGrace) {
          final alreadyQueued = previousHistory.any(
            (entry) =>
                entry.type == 'caffeine_reminder' &&
                (entry.reminderKey == reminderKey ||
                    (entry.reminderKey == null &&
                        entry.scheduledAt == scheduledTime.toUtc())) &&
                [
                  'scheduled',
                  'scheduled_inexact',
                  'sent',
                  'posted',
                  'due_unconfirmed',
                ].contains(entry.status),
          );
          if (alreadyQueued) {
            await _appendHistory(
              type: 'caffeine_reminder',
              status: wasPosted ? 'posted' : 'due_unconfirmed',
              title: text.title,
              body: text.body,
              scheduledAt: scheduledTime,
              reminderKey: reminderKey,
            );
            continue;
          }
          await _plugin.show(
            id: id,
            title: text.title,
            body: text.body,
            notificationDetails: _notificationDetails(languageCode),
            payload: 'caffeine_reminder:$timestamp',
          );
          await _appendHistory(
            type: 'caffeine_reminder',
            status: 'sent',
            title: text.title,
            body: text.body,
            scheduledAt: scheduledTime,
            reminderKey: reminderKey,
          );
        } else {
          await _appendHistory(
            type: 'caffeine_reminder',
            status: wasPosted ? 'posted' : 'skipped_past',
            title: text.title,
            body: text.body,
            scheduledAt: scheduledTime,
            reminderKey: reminderKey,
          );
        }
        continue;
      }

      // Pending requests are plugin metadata, not proof that AlarmManager
      // still holds the alarm. Re-arm future entries with the same ID.
      final scheduled = await _scheduleCaffeineReminder(
        id: id,
        title: text.title,
        body: text.body,
        languageCode: languageCode,
        scheduledTime: scheduledTime,
        payload: 'caffeine_reminder:$timestamp',
      );

      if (scheduled != null) {
        scheduledIds.add(id);
        await _appendHistory(
          type: 'caffeine_reminder',
          status: _scheduleStatus(scheduled),
          title: text.title,
          body: text.body,
          scheduledAt: scheduledTime,
          reminderKey: reminderKey,
        );
      } else {
        await _appendHistory(
          type: 'caffeine_reminder',
          status: 'schedule_failed',
          title: text.title,
          body: text.body,
          scheduledAt: scheduledTime,
          reminderKey: reminderKey,
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _scheduledIdsKey,
      scheduledIds.map((id) => id.toString()).toList(),
    );
    return scheduledIds.length;
  });

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

  Future<void> cancelCaffeineReminders() => _runExclusive(() async {
    await initialize();
    if (!_supported) return;
    await _cancelPreviousReminders();
    await _plugin.cancel(id: 1001);
    await _cancelScheduledTests();
  });

  Future<void> _retireScheduledTests() async {
    await _cancelScheduledTests();
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await loadNotificationHistory();
      if (history.any((entry) => entry.type == 'scheduled_test')) {
        await prefs.setString(
          _historyKey,
          jsonEncode(
            history
                .where((entry) => entry.type != 'scheduled_test')
                .map((entry) => entry.toJson())
                .toList(),
          ),
        );
      }
    } catch (error) {
      debugPrint('Test alarm cancelled; history cache update failed: $error');
    }
  }

  Future<void> _cancelScheduledTests() async {
    final pending = await _plugin.pendingNotificationRequests();
    final ids =
        pending
            .where(
              (request) =>
                  request.payload?.startsWith('notification_schedule_test:') ==
                  true,
            )
            .map((request) => request.id)
            .toSet();
    try {
      final history = await loadNotificationHistory();
      ids.addAll(
        history
            .where(
              (entry) =>
                  entry.type == 'scheduled_test' &&
                  entry.reminderKey?.startsWith(
                        'notification_schedule_test|',
                      ) ==
                      true,
            )
            .map((entry) => _notificationId(entry.reminderKey!)),
      );
    } catch (error) {
      debugPrint(
        'Test history unavailable; cancelling native tests directly: $error',
      );
    }
    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
  }

  Future<ReminderSchedulePrecision?> _scheduleCaffeineReminder({
    required int id,
    required String title,
    required String body,
    required String languageCode,
    required tz.TZDateTime scheduledTime,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: _notificationDetails(languageCode),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      return ReminderSchedulePrecision.exact;
    } catch (exactError) {
      debugPrint('Exact caffeine reminder scheduling failed: $exactError');
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: _notificationDetails(languageCode),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      return ReminderSchedulePrecision.inexact;
    } catch (fallbackError) {
      debugPrint(
        'Fallback caffeine reminder scheduling failed: $fallbackError',
      );
      return null;
    }
  }

  Future<void> _requestNotificationPermission() async {
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (await android?.areNotificationsEnabled() == true) return;
    if (!_notificationPermissionRequested) {
      _notificationPermissionRequested = true;
      if (await android?.requestNotificationsPermission() == true) return;
    }
    throw const NotificationPermissionException();
  }

  Future<void> _cancelPreviousReminders({Set<int> retainIds = const {}}) async {
    final pending = await _plugin.pendingNotificationRequests();
    SharedPreferences? prefs;
    List<String> savedIds = const [];
    try {
      prefs = await SharedPreferences.getInstance();
      savedIds = prefs.getStringList(_scheduledIdsKey) ?? const [];
    } catch (error) {
      debugPrint(
        'Reminder cache unavailable; cancelling OS schedules directly: $error',
      );
    }
    final ids = {
      ...savedIds.map(int.tryParse).whereType<int>(),
      ...pending
          .where(
            (entry) => entry.payload?.startsWith('caffeine_reminder:') ?? false,
          )
          .map((entry) => entry.id),
    };

    for (final id in ids) {
      if (retainIds.contains(id)) continue;
      await _plugin.cancel(id: id);
    }

    if (prefs == null) return;
    try {
      await prefs.remove(_scheduledIdsKey);
      final history = await loadNotificationHistory();
      final now = DateTime.now().toUtc();
      await prefs.setString(
        _historyKey,
        jsonEncode(
          history.map((entry) {
            final json = entry.toJson();
            if (entry.type == 'caffeine_reminder' &&
                ['scheduled', 'scheduled_inexact'].contains(entry.status) &&
                !(entry.reminderKey != null &&
                    retainIds.contains(_notificationId(entry.reminderKey!)))) {
              json['status'] =
                  entry.scheduledAt?.isAfter(now) == true
                      ? 'cancelled'
                      : 'due_unconfirmed';
            }
            return json;
          }).toList(),
        ),
      );
    } catch (error) {
      debugPrint(
        'OS schedules cancelled; optional history cache update failed: $error',
      );
    }
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
      final seen = <String>{};
      return entries
          .where((entry) => seen.add(_historyIdentity(entry)))
          .take(_maxHistoryItems)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearNotificationHistory() => _runExclusive(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  });

  Future<void> _appendHistory({
    required String type,
    required String status,
    required String title,
    required String body,
    tz.TZDateTime? scheduledAt,
    String? reminderKey,
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
      reminderKey: reminderKey,
    );

    final identity = _historyIdentity(entry);
    final updated =
        [
          entry,
          ...current.where(
            (item) =>
                _historyIdentity(item) != identity &&
                !(entry.type == 'caffeine_reminder' &&
                    item.type == entry.type &&
                    item.reminderKey == null &&
                    item.scheduledAt == entry.scheduledAt),
          ),
        ].take(_maxHistoryItems).toList();
    await prefs.setString(
      _historyKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }

  String _historyIdentity(WakeMateNotificationLogEntry entry) {
    if (entry.type == 'caffeine_reminder' && entry.scheduledAt != null) {
      return '${entry.type}|${entry.reminderKey ?? entry.scheduledAt!.toUtc().toIso8601String()}';
    }
    if (entry.type == 'calculation_complete') return entry.type;
    return '${entry.type}|${entry.createdAt.toUtc().toIso8601String()}';
  }

  int _notificationId(String reminderKey) {
    var hash = 2166136261;
    for (final code in reminderKey.codeUnits) {
      hash = ((hash ^ code) * 16777619) & 0x7fffffff;
    }
    return 2000 + hash % (2147483647 - 2000);
  }

  int? _parseAmount(dynamic value) {
    if (value is num) return value.round();
    return num.tryParse(value?.toString() ?? '')?.round();
  }

  _NotificationText _calculationText(
    String languageCode,
    int count,
    int scheduled,
  ) {
    switch (languageCode) {
      case 'id':
        return _NotificationText(
          'Rekomendasi WakeMate siap',
          count == 0
              ? 'Tidak ada rekomendasi untuk ditampilkan saat ini.'
              : '$count rekomendasi tersedia; $scheduled pengingat dijadwalkan. Periksa status pengingat di aplikasi.',
        );
      case 'en':
        return _NotificationText(
          'WakeMate recommendation ready',
          count == 0
              ? 'There are no recommendation entries to display right now.'
              : '$count recommendations are ready; $scheduled reminders are scheduled. Check reminder status in the app.',
        );
      default:
        return _NotificationText(
          'WakeMate 推薦計算完成',
          count == 0
              ? '目前沒有可顯示的推薦項目。'
              : '已產生 $count 筆推薦，已安排 $scheduled 筆提醒。請在 App 確認提醒狀態。',
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

  _NotificationText _channelText(String languageCode) {
    switch (languageCode) {
      case 'id':
        return const _NotificationText(
          'Pengingat WakeMate',
          'Notifikasi rekomendasi dan pengingat kafein WakeMate',
        );
      case 'en':
        return const _NotificationText(
          'WakeMate reminders',
          'WakeMate caffeine recommendation and reminder notifications',
        );
      default:
        return const _NotificationText('WakeMate 咖啡因提醒', '咖啡因推薦完成及建議飲用時間提醒');
    }
  }

  NotificationDetails _notificationDetails(String languageCode) {
    final channelText = _channelText(languageCode);

    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId(languageCode),
        channelText.title,
        channelDescription: channelText.body,
        icon: _notificationIcon,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        ticker: channelText.title,
      ),
    );
  }

  String _channelId(String languageCode) =>
      '${_channelIdBase}_${switch (languageCode) {
        'id' => 'id',
        'en' => 'en',
        _ => 'zh',
      }}';
}

class _NotificationText {
  const _NotificationText(this.title, this.body);

  final String title;
  final String body;
}

class NotificationPermissionException implements Exception {
  const NotificationPermissionException();
}

enum ReminderSchedulePrecision { exact, inexact }

class NotificationReadiness {
  const NotificationReadiness({
    this.notificationsEnabled,
    this.exactAlarmsAllowed,
    this.caffeineChannelEnabled,
  });
  final bool? notificationsEnabled;
  final bool? exactAlarmsAllowed;
  final bool? caffeineChannelEnabled;
}

class WakeMateNotificationLogEntry {
  const WakeMateNotificationLogEntry({
    required this.type,
    required this.status,
    required this.title,
    required this.body,
    required this.createdAt,
    this.scheduledAt,
    this.reminderKey,
  });

  final String type;
  final String status;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final String? reminderKey;

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
      reminderKey: json['reminderKey']?.toString(),
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
      'reminderKey': reminderKey,
    };
  }
}
