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
              pending.remove((call.arguments as Map)['id']);
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
    'one minute test uses the same native alarm path, not immediate show or a caffeine instruction',
    () async {
      exactAllowed = true;
      final before = DateTime.now().toUtc();
      expect(
        await service.scheduleOneMinuteTest(languageCode: 'en'),
        ReminderSchedulePrecision.exact,
      );
      final entry = (await service.loadNotificationHistory()).single;
      expect(entry.type, 'scheduled_test');
      expect(
        entry.scheduledAt!.difference(before).inSeconds,
        inInclusiveRange(59, 62),
      );
      expect(entry.body, contains('not a caffeine recommendation'));
      expect(calls.where((c) => c.method == 'zonedSchedule'), hasLength(1));
      expect(calls.where((c) => c.method == 'show'), isEmpty);
      expect(await service.pendingCaffeineReminderCount(), 0);
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

  test('one minute test exposes inexact and total schedule failure', () async {
    expect(
      await service.scheduleOneMinuteTest(languageCode: 'en'),
      ReminderSchedulePrecision.inexact,
    );
    expect(
      (await service.loadNotificationHistory()).first.status,
      'scheduled_inexact',
    );
    failAllSchedules = true;
    expect(await service.scheduleOneMinuteTest(languageCode: 'en'), isNull);
    expect(
      (await service.loadNotificationHistory()).first.status,
      'schedule_failed',
    );
    expect((await service.loadNotificationHistory()), hasLength(1));
    expect(pending, isEmpty);
  });

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
    'a stale visible diagnostic notification cannot confirm a new test',
    () async {
      exactAllowed = true;
      await service.scheduleOneMinuteTest(languageCode: 'en');
      final oldId = pending.keys.single;
      active.add(
        Map<String, dynamic>.from(pending.values.single)..remove('payload'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await service.scheduleOneMinuteTest(languageCode: 'en');
      expect(pending.keys.single, isNot(oldId));
      await service.reconcileVisibleNotifications();
      expect(
        (await service.loadNotificationHistory()).single.status,
        'scheduled',
      );
    },
  );

  test('logout cancels diagnostic test as well as caffeine alarms', () async {
    exactAllowed = true;
    await replace();
    await service.scheduleOneMinuteTest(languageCode: 'en');
    expect(pending.length, 2);
    await service.cancelCaffeineReminders();
    expect(pending, isEmpty);
  });

  for (final language in ['zh', 'en', 'id']) {
    testWidgets(
      '$language permission and timed-test controls fit a small phone',
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
        final timedTest = find.byKey(
          const ValueKey('schedule-one-minute-test'),
        );
        await tester.ensureVisible(timedTest);
        await tester.pumpAndSettle();
        await tester.tap(timedTest);
        await tester.pumpAndSettle();
        expect(pending, hasLength(1));
        expect(tester.takeException(), isNull);
        final prefs = await SharedPreferences.getInstance();
        final history = jsonDecode(
          prefs.getString('wakemate_notification_history')!,
        );
        expect(history.first['type'], 'scheduled_test');
        await qa.screenshot(
          tester,
          'notification-one-minute-test-$language-20261027',
        );
      },
    );
  }
}
