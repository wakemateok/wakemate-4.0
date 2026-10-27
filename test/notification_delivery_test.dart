import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/screens/notification_center_page.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hospital_review_widget_test.dart' as qa;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late NotificationService service;
  late Map<int, Map<String, dynamic>> pending;
  late List<Map<String, dynamic>> active;
  late List<MethodCall> calls;
  var exactAllowed = false;
  var failAllSchedules = false;
  var grantExact = true;
  var channelBlocked = false;
  final at = DateTime.now().add(const Duration(hours: 1));
  setUpAll(() async {
    if (const bool.fromEnvironment('WAKEMATE_CAPTURE_QA')) {
      for (final entry
          in {
            'ReviewQA': 'C:/Windows/Fonts/msjh.ttc',
            'MaterialIcons':
                'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          }.entries) {
        final loader = FontLoader(entry.key);
        loader.addFont(
          File(entry.value).readAsBytes().then(ByteData.sublistView),
        );
        await loader.load();
      }
    }
  });

  Future<int> replace() => service.replaceCaffeineReminders(
    userId: 'delivery-test-owner',
    languageCode: 'en',
    recommendations: [
      {
        'recommended_caffeine_intake_timing': at.toUtc().toIso8601String(),
        'recommended_caffeine_amount': 100,
      },
    ],
  );

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    SharedPreferences.setMockInitialValues({});
    service = NotificationService.forTesting();
    pending = {};
    active = [];
    calls = [];
    exactAllowed = false;
    failAllSchedules = false;
    grantExact = true;
    channelBlocked = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
            case 'areNotificationsEnabled':
            case 'requestNotificationsPermission':
              return true;
            case 'canScheduleExactNotifications':
              return exactAllowed;
            case 'requestExactAlarmsPermission':
              exactAllowed = grantExact;
              return grantExact;
            case 'pendingNotificationRequests':
              return pending.values.toList();
            case 'getActiveNotifications':
              return active;
            case 'getNotificationChannels':
              return channelBlocked
                  ? [
                    {
                      'id': 'wakemate_caffeine_reminders_v2_zh',
                      'name': 'WakeMate',
                      'importance': 0,
                      'showBadge': true,
                      'bypassDnd': false,
                      'playSound': false,
                      'enableLights': false,
                      'enableVibration': false,
                      'ledColor': 0,
                      'audioAttributesUsage': 5,
                    },
                  ]
                  : [];
            case 'zonedSchedule':
              final args = Map<String, dynamic>.from(call.arguments as Map);
              if (failAllSchedules ||
                  (!exactAllowed &&
                      (args['platformSpecifics'] as Map)['scheduleMode'] ==
                          'exactAllowWhileIdle')) {
                throw PlatformException(code: 'exact_alarms_not_permitted');
              }
              pending[args['id'] as int] = {
                'id': args['id'],
                'title': args['title'],
                'body': args['body'],
                'payload': args['payload'],
              };
              return null;
            case 'cancel':
              final id = (call.arguments as Map)['id'];
              pending.remove(id);
              active.removeWhere((notification) => notification['id'] == id);
              return null;
            default:
              return null;
          }
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'notification and exact scheduling permissions are independent',
    () async {
      final readiness = await service.notificationReadiness();
      expect(readiness.notificationsEnabled, isTrue);
      expect(readiness.exactAlarmsAllowed, isFalse);
    },
  );

  test(
    'inexact fallback is recorded explicitly without requesting special access',
    () async {
      expect(await replace(), 1);
      expect(
        (await service.loadNotificationHistory()).single.status,
        'scheduled_inexact',
      );
      expect(
        calls.where((c) => c.method == 'requestExactAlarmsPermission'),
        isEmpty,
      );
    },
  );

  test(
    'a blocked reminder channel is detected even when global permission is enabled',
    () async {
      channelBlocked = true;
      final readiness = await service.notificationReadiness();
      expect(readiness.notificationsEnabled, isTrue);
      expect(readiness.caffeineChannelEnabled, isFalse);
    },
  );

  test(
    'granting exact permission upgrades future alarms without cancelling first',
    () async {
      await replace();
      final id = pending.keys.single;
      calls.clear();
      expect(
        await service.requestExactReminderPermission(languageCode: 'en'),
        isTrue,
      );
      expect(pending.keys.single, id);
      expect(calls.where((c) => c.method == 'cancel'), isEmpty);
      expect(calls.where((c) => c.method == 'zonedSchedule'), hasLength(1));
      expect(
        (await service.loadNotificationHistory()).single.status,
        'scheduled',
      );
    },
  );

  test(
    'denied exact access does not claim an upgrade or change pending alarms',
    () async {
      await replace();
      grantExact = false;
      calls.clear();
      expect(
        await service.requestExactReminderPermission(languageCode: 'en'),
        isFalse,
      );
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
      expect(
        (await service.loadNotificationHistory()).single.status,
        'scheduled_inexact',
      );
    },
  );

  test('granting exact access never re-arms an overdue alarm', () async {
    await replace();
    final id = pending.keys.single;
    pending[id]!['payload'] = 'caffeine_reminder:2020-01-01T00:00:00Z';
    calls.clear();
    expect(
      await service.requestExactReminderPermission(languageCode: 'en'),
      isTrue,
    );
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
  });

  test(
    'total caffeine scheduling failure is explicit and has no queued alarm',
    () async {
      failAllSchedules = true;
      expect(await replace(), 0);
      expect(
        (await service.loadNotificationHistory()).first.status,
        'schedule_failed',
      );
      expect((await service.loadNotificationHistory()), hasLength(1));
      expect(pending, isEmpty);
    },
  );

  test('removal from pending metadata alone never proves delivery', () async {
    exactAllowed = true;
    await replace();
    pending.clear();
    await service.reconcileVisibleNotifications();
    expect(
      (await service.loadNotificationHistory()).single.status,
      'scheduled',
    );
  });

  test(
    'a confirmed posted reminder is not downgraded when an old result is refreshed',
    () async {
      final past = DateTime.now().toUtc().subtract(const Duration(minutes: 20));
      SharedPreferences.setMockInitialValues({
        'wakemate_notification_history': jsonEncode([
          {
            'type': 'caffeine_reminder',
            'status': 'posted',
            'title': 'WakeMate caffeine reminder',
            'body': 'It is time for the recommended 100 mg of caffeine.',
            'scheduledAt': past.toIso8601String(),
            'createdAt': past.toIso8601String(),
            'reminderKey': 'delivery-test-owner|${past.toIso8601String()}',
          },
        ]),
      });
      expect(
        await service.replaceCaffeineReminders(
          userId: 'delivery-test-owner',
          languageCode: 'en',
          recommendations: [
            {
              'recommended_caffeine_intake_timing': past.toIso8601String(),
              'recommended_caffeine_amount': 100,
            },
          ],
        ),
        0,
      );
      expect((await service.loadNotificationHistory()).single.status, 'posted');
      expect(
        calls.where((c) => c.method == 'show' || c.method == 'zonedSchedule'),
        isEmpty,
      );
    },
  );

  test(
    'matching active native notification provides positive tray confirmation',
    () async {
      exactAllowed = true;
      await replace();
      active.add(
        Map<String, dynamic>.from(pending.values.single)..remove('payload'),
      );
      await service.reconcileVisibleNotifications();
      expect((await service.loadNotificationHistory()).single.status, 'posted');
    },
  );

  test(
    'upgrade removes retired test alarms and history without changing real reminders',
    () async {
      final timestamp = at.toUtc().toIso8601String();
      SharedPreferences.setMockInitialValues({
        'user_name': 'Keep this name',
        'wakemate_notification_history': jsonEncode([
          {
            'type': 'scheduled_test',
            'status': 'scheduled',
            'title': 'old test',
            'body': 'old test body',
            'createdAt': timestamp,
            'scheduledAt': timestamp,
            'reminderKey': 'notification_schedule_test|$timestamp',
          },
          {
            'type': 'caffeine_reminder',
            'status': 'scheduled',
            'title': 'real reminder',
            'body': '100 mg',
            'createdAt': timestamp,
            'scheduledAt': timestamp,
            'reminderKey': 'owner|$timestamp',
          },
          {
            'type': 'test',
            'status': 'sent',
            'title': 'instant test',
            'body': 'instant test body',
            'createdAt': timestamp,
          },
        ]),
      });
      pending[701] = {
        'id': 701,
        'payload': 'notification_schedule_test:$timestamp',
      };
      pending[702] = {'id': 702, 'payload': 'caffeine_reminder:$timestamp'};
      pending[703] = {'id': 703, 'payload': 'unrelated'};
      await service.initialize();
      expect(pending.keys.toSet(), {702, 703});
      final history = await service.loadNotificationHistory();
      expect(history.map((entry) => entry.type).toSet(), {
        'caffeine_reminder',
        'test',
      });
      expect(
        history.firstWhere((entry) => entry.type == 'caffeine_reminder').status,
        'scheduled',
      );
      expect(
        (await SharedPreferences.getInstance()).getString('user_name'),
        'Keep this name',
      );
      final cancelCount = calls.where((call) => call.method == 'cancel').length;
      await service.initialize();
      expect(
        calls.where((call) => call.method == 'cancel'),
        hasLength(cancelCount),
      );
      expect(calls.where((call) => call.method == 'cancelAll'), isEmpty);
    },
  );

  test(
    'instant notification test and real reminder cancellation remain available',
    () async {
      exactAllowed = true;
      await replace();
      expect(await service.showTestNotification(languageCode: 'en'), isTrue);
      expect(pending.length, 1);
      await service.cancelCaffeineReminders();
      expect(pending, isEmpty);
    },
  );

  for (final language in ['zh', 'en', 'id']) {
    testWidgets(
      '$language permission controls fit and retired timed test is absent',
      (tester) async {
        service = NotificationService.forTesting();
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          qa.app(
            NotificationCenterPage(notifications: service),
            Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        final enable = find.byKey(const ValueKey('enable-exact-reminders'));
        await tester.ensureVisible(enable);
        await tester.pumpAndSettle();
        await qa.screenshot(
          tester,
          'notification-exact-permission-$language-20261027',
        );
        await tester.tap(enable);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('enable-exact-reminders')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('schedule-one-minute-test')),
          findsNothing,
        );
        expect(find.byIcon(Icons.timer_outlined), findsNothing);
        expect(pending, isEmpty);
        expect(tester.takeException(), isNull);
        await qa.screenshot(tester, 'notification-cleanup-$language-20261027');
      },
    );
  }
}
