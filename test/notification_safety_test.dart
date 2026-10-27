import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/services/recommendation_invalidation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class FailedReminderCache extends InMemorySharedPreferencesStore {
  FailedReminderCache() : super.empty();
  @override
  Future<Map<String, Object>> getAll() async =>
      throw PlatformException(code: 'cache_unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late NotificationService service;
  late Map<int, Map<String, dynamic>> pending;
  late List<MethodCall> calls;
  var allowed = true;
  var failInitialization = false;
  var failExactOnce = false;

  Map<String, dynamic> recommendation(DateTime time, [int amount = 25]) => {
    'recommended_caffeine_intake_timing': time.toUtc().toIso8601String(),
    'recommended_caffeine_amount': amount,
  };
  Future<int> replace(List<dynamic> entries) =>
      service.replaceCaffeineReminders(
        recommendations: entries,
        languageCode: 'en',
        userId: 'test-user',
      );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    SharedPreferences.setMockInitialValues({});
    service = NotificationService.forTesting();
    pending = {};
    calls = [];
    allowed = true;
    failInitialization = false;
    failExactOnce = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              if (failInitialization) {
                failInitialization = false;
                throw PlatformException(code: 'init_failed');
              }
              return true;
            case 'areNotificationsEnabled':
            case 'requestNotificationsPermission':
              return allowed;
            case 'pendingNotificationRequests':
              return pending.values.toList();
            case 'zonedSchedule':
              if (failExactOnce) {
                failExactOnce = false;
                throw PlatformException(code: 'exact_alarms_not_permitted');
              }
              final args = Map<String, dynamic>.from(call.arguments as Map);
              pending[args['id'] as int] = {
                'id': args['id'],
                'title': args['title'],
                'body': args['body'],
                'payload': args['payload'],
              };
              return null;
            case 'cancel':
              pending.remove((call.arguments as Map)['id']);
              return null;
            default:
              return null;
          }
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'repeated calculation and duplicate input keep one reminder and one log',
    () async {
      final entry = recommendation(
        DateTime.now().add(const Duration(hours: 2)),
      );
      for (var i = 0; i < 3; i++) {
        expect(await replace([entry, entry]), 1);
      }
      expect(pending.length, 1);
      final history = await service.loadNotificationHistory();
      expect(history.length, 1);
      expect(history.single.status, 'scheduled');
    },
  );

  test(
    'notification IDs stay stable when the recommendation order changes',
    () async {
      final first = recommendation(
        DateTime.now().add(const Duration(hours: 2)),
      );
      final second = recommendation(
        DateTime.now().add(const Duration(hours: 3)),
      );
      await replace([first, second]);
      final ids = pending.keys.toSet();
      await replace([second, first]);
      expect(pending.keys.toSet(), ids);
      expect((await service.loadNotificationHistory()).length, 2);
    },
  );

  test(
    'one hundred unchanged refreshes re-arm one stable alarm without cancellation gaps',
    () async {
      final entry = recommendation(
        DateTime.now().add(const Duration(hours: 2)),
      );
      await replace([entry]);
      final id = pending.keys.single;
      calls.clear();
      for (var i = 0; i < 100; i++) {
        expect(await replace([entry]), 1);
      }
      expect(pending.keys.single, id);
      expect(calls.where((call) => call.method == 'cancel'), isEmpty);
      expect(
        calls.where((call) => call.method == 'zonedSchedule'),
        hasLength(100),
      );
      expect((await service.loadNotificationHistory()), hasLength(1));
    },
  );

  test('reopening the app re-arms an unchanged future alarm', () async {
    final entry = recommendation(DateTime.now().add(const Duration(hours: 2)));
    await replace([entry]);
    final id = pending.keys.single;
    service = NotificationService.forTesting();
    calls.clear();
    expect(await replace([entry]), 1);
    expect(pending.keys.single, id);
    expect(calls.where((call) => call.method == 'cancel'), isEmpty);
    expect(calls.where((call) => call.method == 'zonedSchedule'), hasLength(1));
  });

  test(
    'dose changes replace the alarm without leaving the old dose queued',
    () async {
      final at = DateTime.now().add(const Duration(hours: 2));
      await replace([recommendation(at, 25)]);
      final id = pending.keys.single;
      calls.clear();
      expect(await replace([recommendation(at, 75)]), 1);
      expect(pending.keys.single, id);
      expect(pending.values.single['body'], contains('75 mg'));
      expect(calls.where((call) => call.method == 'cancel'), hasLength(1));
      expect(
        calls.where((call) => call.method == 'zonedSchedule'),
        hasLength(1),
      );
    },
  );

  test('changing language updates the native reminder text', () async {
    final entry = recommendation(DateTime.now().add(const Duration(hours: 2)));
    await replace([entry]);
    final id = pending.keys.single;
    calls.clear();
    expect(
      await service.replaceCaffeineReminders(
        recommendations: [entry],
        languageCode: 'zh',
        userId: 'test-user',
      ),
      1,
    );
    expect(pending.keys.single, id);
    expect(pending.values.single['title'], 'WakeMate 咖啡因提醒');
    expect(calls.where((call) => call.method == 'cancel'), hasLength(1));
  });

  test('account changes cannot retain the previous account reminder', () async {
    final entry = recommendation(DateTime.now().add(const Duration(hours: 2)));
    await replace([entry]);
    final oldId = pending.keys.single;
    calls.clear();
    expect(
      await service.replaceCaffeineReminders(
        recommendations: [entry],
        languageCode: 'en',
        userId: 'another-user',
      ),
      1,
    );
    expect(pending, hasLength(1));
    expect(pending.keys.single, isNot(oldId));
    expect(calls.where((call) => call.method == 'cancel'), hasLength(1));
  });

  test('clearing local history does not cancel a valid native alarm', () async {
    final entry = recommendation(DateTime.now().add(const Duration(hours: 2)));
    await replace([entry]);
    await service.clearNotificationHistory();
    calls.clear();
    expect(await replace([entry]), 1);
    expect(calls.where((call) => call.method == 'cancel'), isEmpty);
    expect(
      (await service.loadNotificationHistory()).single.status,
      'scheduled',
    );
  });

  test(
    'equivalent UTC and Taipei timestamp formats retain the same alarm',
    () async {
      final at = DateTime.now().add(const Duration(hours: 2)).toUtc();
      final localTime = at
          .add(const Duration(hours: 8))
          .toIso8601String()
          .replaceFirst('Z', '+08:00');
      await replace([recommendation(at)]);
      calls.clear();
      expect(
        await replace([
          {
            'recommended_caffeine_intake_timing': localTime,
            'recommended_caffeine_amount': 25,
          },
        ]),
        1,
      );
      expect(pending, hasLength(1));
      expect(calls.where((call) => call.method == 'cancel'), isEmpty);
      expect(
        calls.where((call) => call.method == 'zonedSchedule'),
        hasLength(1),
      );
    },
  );

  test(
    'concurrent recalculations do not leave an orphaned OS schedule',
    () async {
      final first = recommendation(
        DateTime.now().add(const Duration(hours: 2)),
      );
      final second = recommendation(
        DateTime.now().add(const Duration(hours: 3)),
      );
      await Future.wait([
        replace([first]),
        replace([second]),
      ]);
      expect(pending.length, 1);
      final history = await service.loadNotificationHistory();
      expect(history.where((item) => item.status == 'scheduled').length, 1);
      expect(history.where((item) => item.status == 'cancelled').length, 1);
    },
  );

  test(
    'empty replacement cancels previous schedule and updates its log',
    () async {
      await replace([
        recommendation(DateTime.now().add(const Duration(hours: 2))),
      ]);
      await replace([]);
      expect(pending, isEmpty);
      expect(
        (await service.loadNotificationHistory()).single.status,
        'cancelled',
      );
    },
  );

  test('same recent-past reminder is not immediately shown twice', () async {
    final entry = recommendation(
      DateTime.now().subtract(const Duration(minutes: 1)),
    );
    await replace([entry]);
    await replace([entry]);
    expect(calls.where((call) => call.method == 'show').length, 1);
    expect((await service.loadNotificationHistory()).length, 1);
  });

  test(
    'refresh must not cancel an unchanged reminder still waiting for Android delivery',
    () async {
      final at = DateTime.now().subtract(const Duration(minutes: 1));
      final key = 'test-user|${at.toUtc().toIso8601String()}';
      await replace([recommendation(at)]);
      final id =
          calls.lastWhere((call) => call.method == 'show').arguments as Map;
      // Model a native alarm that Android has not delivered yet, using the
      // actual stable reminder ID and the original scheduled history entry.
      SharedPreferences.setMockInitialValues({
        'wakemate_notification_history': jsonEncode([
          {
            'type': 'caffeine_reminder',
            'status': 'scheduled',
            'title': 'WakeMate caffeine reminder',
            'body': 'It is time for the recommended 25 mg of caffeine.',
            'createdAt':
                at.subtract(const Duration(hours: 1)).toUtc().toIso8601String(),
            'scheduledAt': at.toUtc().toIso8601String(),
            'reminderKey': key,
          },
        ]),
      });
      pending.clear();
      pending[id['id'] as int] = {
        'id': id['id'],
        'title': 'WakeMate caffeine reminder',
        'body': 'It is time for the recommended 25 mg of caffeine.',
        'payload': 'caffeine_reminder:${at.toUtc().toIso8601String()}',
      };
      calls.clear();
      expect(await replace([recommendation(at)]), 1);
      expect(pending, hasLength(1));
      expect(calls.where((call) => call.method == 'cancel'), isEmpty);
      expect(calls.where((call) => call.method == 'show'), isEmpty);
    },
  );

  test(
    'denied permission is explicit and works after enabling in settings',
    () async {
      allowed = false;
      await expectLater(
        service.showTestNotification(languageCode: 'en'),
        throwsA(isA<NotificationPermissionException>()),
      );
      expect(calls.where((call) => call.method == 'show'), isEmpty);
      allowed = true;
      expect(await service.showTestNotification(languageCode: 'en'), isTrue);
    },
  );

  test(
    'failed initialization can retry rather than remaining half initialized',
    () async {
      failInitialization = true;
      await expectLater(
        service.initialize(),
        throwsA(isA<PlatformException>()),
      );
      await service.initialize();
      expect(calls.where((call) => call.method == 'initialize').length, 2);
    },
  );

  test('exact alarm denial falls back to inexact mode', () async {
    failExactOnce = true;
    expect(
      await replace([
        recommendation(DateTime.now().add(const Duration(hours: 2))),
      ]),
      1,
    );
    expect(calls.where((call) => call.method == 'zonedSchedule').length, 2);
    expect(pending.length, 1);
  });

  test(
    'cancelling old reminders does not need notification permission',
    () async {
      await replace([
        recommendation(DateTime.now().add(const Duration(hours: 2))),
      ]);
      allowed = false;
      await service.cancelCaffeineReminders();
      expect(pending, isEmpty);
      expect(
        (await service.loadNotificationHistory()).single.status,
        'cancelled',
      );
    },
  );

  test(
    'changed input removes future cache and schedules but preserves history',
    () async {
      final future = recommendation(
        DateTime.now().add(const Duration(hours: 2)),
      );
      final past = recommendation(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      await replace([future]);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'caffeine_recommendations',
        jsonEncode([past, future]),
      );
      await invalidateFutureRecommendations(notifications: service);
      expect(pending, isEmpty);
      expect(jsonDecode(prefs.getString('caffeine_recommendations')!), [past]);
      expect(
        (await service.loadNotificationHistory()).single.status,
        'cancelled',
      );
    },
  );

  test('legacy duplicate history is collapsed on read', () async {
    final now = DateTime.now().toUtc();
    final time = now.add(const Duration(hours: 1));
    SharedPreferences.setMockInitialValues({
      'wakemate_notification_history': jsonEncode([
        for (var i = 0; i < 40; i++)
          {
            'type': 'caffeine_reminder',
            'status': 'scheduled',
            'title': 'old',
            'body': '25 mg',
            'createdAt': now.add(Duration(seconds: i)).toIso8601String(),
            'scheduledAt': time.toIso8601String(),
          },
      ]),
    });
    expect((await service.loadNotificationHistory()).length, 1);
  });

  test(
    'storage read failure cannot leave cancelled OS reminders active',
    () async {
      await replace([
        recommendation(DateTime.now().add(const Duration(hours: 2))),
      ]);
      expect(pending, isNotEmpty);
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = FailedReminderCache();
      await service.cancelCaffeineReminders();
      expect(pending, isEmpty);
    },
  );

  test(
    'repeated calculation-complete logs keep only the latest status',
    () async {
      await service.showCalculationComplete(
        recommendationCount: 1,
        languageCode: 'en',
      );
      await service.showCalculationComplete(
        recommendationCount: 2,
        languageCode: 'en',
      );
      expect((await service.loadNotificationHistory()).length, 1);
    },
  );
}
