import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/screens/notification_permission_setup.dart';
import 'package:my_app/screens/questionnaire_prompt_page.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'hospital_review_widget_test.dart' as qa;

class SetupWriteFailure extends InMemorySharedPreferencesStore {
  SetupWriteFailure() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      throw PlatformException(code: 'cache_unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const plugin = MethodChannel('dexterous.com/flutter/local_notifications');
  const settings = MethodChannel('wakemate/notification_settings');
  late NotificationService notifications;
  late List<MethodCall> pluginCalls;
  late List<MethodCall> settingsCalls;
  var sdk = 36;
  var allowed = false;
  var exact = false;
  var blockedChannel = false;
  var grantNotification = true;
  var grantExact = true;
  var grantChannel = true;
  var settingsFail = false;
  Completer<bool>? notificationReply;
  Completer<int>? sdkReply;

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    notifications = NotificationService.forTesting();
    pluginCalls = [];
    settingsCalls = [];
    sdk = 36;
    allowed = false;
    exact = false;
    blockedChannel = false;
    grantNotification = true;
    grantExact = true;
    grantChannel = true;
    settingsFail = false;
    notificationReply = null;
    sdkReply = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(plugin, (call) async {
          pluginCalls.add(call);
          switch (call.method) {
            case 'initialize':
              return true;
            case 'pendingNotificationRequests':
              return [];
            case 'areNotificationsEnabled':
              return allowed;
            case 'canScheduleExactNotifications':
              return exact;
            case 'requestNotificationsPermission':
              allowed =
                  notificationReply == null
                      ? grantNotification
                      : await notificationReply!.future;
              return allowed;
            case 'requestExactAlarmsPermission':
              exact = grantExact;
              return exact;
            case 'getNotificationChannels':
              return sdk < 26
                  ? []
                  : [
                    for (final language in ['zh', 'en', 'id'])
                      {
                        'id': 'wakemate_caffeine_reminders_v2_$language',
                        'name': 'WakeMate',
                        'importance': blockedChannel ? 0 : 5,
                        'showBadge': true,
                        'bypassDnd': false,
                        'playSound': true,
                        'enableLights': false,
                        'enableVibration': true,
                        'ledColor': 0,
                        'audioAttributesUsage': 5,
                      },
                  ];
            default:
              return null;
          }
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(settings, (call) async {
          settingsCalls.add(call);
          if (settingsFail) {
            throw PlatformException(code: 'notification_settings_unavailable');
          }
          switch (call.method) {
            case 'getAndroidSdk':
              return sdkReply == null ? sdk : await sdkReply!.future;
            case 'openNotificationSettings':
              allowed = grantNotification;
              return null;
            case 'openChannelSettings':
              if (grantChannel) {
                blockedChannel = false;
              }
              return null;
            default:
              throw MissingPluginException();
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(plugin, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(settings, null);
  });

  const child = Scaffold(body: Text('main-app'));
  final configure = find.byKey(
    const ValueKey('setup-notification-permissions'),
  );
  final later = find.byKey(const ValueKey('defer-notification-permissions'));
  int requested(String method) =>
      pluginCalls.where((call) => call.method == method).length;
  Future<void> open(
    WidgetTester tester, {
    String language = 'zh',
    bool questionnaire = false,
  }) async {
    notifications = NotificationService.forTesting();
    final gate = NotificationPermissionGate(
      notifications: notifications,
      child: child,
    );
    await tester.pumpWidget(
      qa.app(
        questionnaire ? QuestionnaireGate(child: gate) : gate,
        Locale(language),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'first launch checks state without prompting and requests only after consent',
    (tester) async {
      await open(tester);
      expect(find.byType(NotificationPermissionSetupPage), findsOneWidget);
      expect(requested('requestNotificationsPermission'), 0);
      expect(requested('requestExactAlarmsPermission'), 0);
      expect(requested('createNotificationChannel'), 3);
      await press(tester, configure);
      expect(find.text('main-app'), findsOneWidget);
      expect(requested('requestNotificationsPermission'), 1);
      expect(requested('requestExactAlarmsPermission'), 1);
      expect(
        settingsCalls.where((call) => call.method.startsWith('open')),
        isEmpty,
      );
      expect(
        (await SharedPreferences.getInstance()).getBool(
          notificationPermissionSetupSeenKey,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'already granted setup is skipped without any permission dialog',
    (tester) async {
      allowed = true;
      exact = true;
      await open(tester);
      expect(find.text('main-app'), findsOneWidget);
      expect(find.byType(NotificationPermissionSetupPage), findsNothing);
      expect(requested('requestNotificationsPermission'), 0);
      expect(requested('requestExactAlarmsPermission'), 0);
    },
  );

  testWidgets(
    'granted notification access is skipped when only exact access is missing',
    (tester) async {
      allowed = true;
      await open(tester);
      await press(tester, configure);
      expect(requested('requestNotificationsPermission'), 0);
      expect(requested('requestExactAlarmsPermission'), 1);
      expect(find.text('main-app'), findsOneWidget);
    },
  );

  testWidgets(
    'a disabled channel opens its settings without requesting granted permissions',
    (tester) async {
      allowed = true;
      exact = true;
      blockedChannel = true;
      await open(tester, language: 'id');
      await press(tester, configure);
      final calls = settingsCalls.where(
        (call) => call.method == 'openChannelSettings',
      );
      expect(calls, hasLength(1));
      expect(
        (calls.single.arguments as Map)['channelId'],
        'wakemate_caffeine_reminders_v2_id',
      );
      expect(requested('requestNotificationsPermission'), 0);
      expect(requested('requestExactAlarmsPermission'), 0);
      expect(find.text('main-app'), findsOneWidget);
    },
  );

  testWidgets(
    'Later persists and a new service does not show setup on the next launch',
    (tester) async {
      await open(tester);
      await press(tester, later);
      expect(find.text('main-app'), findsOneWidget);
      expect(requested('requestNotificationsPermission'), 0);
      expect(requested('requestExactAlarmsPermission'), 0);
      final priorQueries = settingsCalls.length;
      await tester.pumpWidget(const SizedBox.shrink());
      await open(tester);
      expect(find.text('main-app'), findsOneWidget);
      expect(settingsCalls.length, priorQueries);
    },
  );

  testWidgets(
    'denying notifications does not trigger exact access and still allows Later',
    (tester) async {
      grantNotification = false;
      await open(tester);
      await press(tester, configure);
      expect(find.byType(NotificationPermissionSetupPage), findsOneWidget);
      expect(requested('requestExactAlarmsPermission'), 0);
      await press(tester, later);
      expect(find.text('main-app'), findsOneWidget);
    },
  );

  testWidgets(
    'denied exact access leaves Later available without repeated notification prompts',
    (tester) async {
      allowed = true;
      grantExact = false;
      await open(tester);
      await press(tester, configure);
      expect(find.byType(NotificationPermissionSetupPage), findsOneWidget);
      expect(requested('requestNotificationsPermission'), 0);
      await press(tester, later);
      expect(find.text('main-app'), findsOneWidget);
    },
  );

  testWidgets(
    'older Android uses app settings instead of an unsupported runtime prompt',
    (tester) async {
      sdk = 25;
      exact = true;
      await open(tester);
      await press(tester, configure);
      expect(requested('requestNotificationsPermission'), 0);
      expect(
        settingsCalls.where(
          (call) => call.method == 'openNotificationSettings',
        ),
        hasLength(1),
      );
      expect(find.text('main-app'), findsOneWidget);
    },
  );

  testWidgets('Android before channels skips the inapplicable channel step', (
    tester,
  ) async {
    sdk = 25;
    allowed = true;
    exact = true;
    await open(tester);
    expect(find.text('main-app'), findsOneWidget);
    expect(
      settingsCalls.where((call) => call.method.startsWith('open')),
      isEmpty,
    );
  });

  testWidgets('desktop bypasses the Android-only onboarding', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await open(tester);
    expect(find.text('main-app'), findsOneWidget);
    expect(settingsCalls, isEmpty);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('system settings failure is retryable and never blocks Later', (
    tester,
  ) async {
    settingsFail = true;
    await open(tester);
    expect(find.byType(NotificationPermissionSetupPage), findsOneWidget);
    expect(find.textContaining('暫時無法'), findsOneWidget);
    await press(tester, later);
    expect(find.text('main-app'), findsOneWidget);
  });

  testWidgets(
    'returning from channel settings rechecks and completes automatically',
    (tester) async {
      allowed = true;
      exact = true;
      blockedChannel = true;
      grantChannel = false;
      await open(tester);
      await press(tester, configure);
      expect(find.byType(NotificationPermissionSetupPage), findsOneWidget);
      blockedChannel = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('main-app'), findsOneWidget);
    },
  );

  testWidgets(
    'leaving during a permission request cannot launch the next prompt',
    (tester) async {
      notificationReply = Completer<bool>();
      await open(tester);
      await tester.ensureVisible(configure);
      await tester.pumpAndSettle();
      await tester.tap(configure);
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(configure).onPressed, isNull);
      await press(tester, later);
      expect(find.text('main-app'), findsOneWidget);
      notificationReply!.complete(true);
      await tester.pumpAndSettle();
      expect(requested('requestExactAlarmsPermission'), 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('late startup probe is ignored after its page is removed', (
    tester,
  ) async {
    sdkReply = Completer<int>();
    notifications = NotificationService.forTesting();
    await tester.pumpWidget(
      qa.app(
        NotificationPermissionGate(notifications: notifications, child: child),
        const Locale('en'),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    sdkReply!.complete(36);
    await tester.pumpAndSettle();
    expect(requested('requestNotificationsPermission'), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Later remains available during a slow probe and cannot reopen setup later',
    (tester) async {
      sdkReply = Completer<int>();
      notifications = NotificationService.forTesting();
      await tester.pumpWidget(
        qa.app(
          NotificationPermissionGate(
            notifications: notifications,
            child: child,
          ),
          const Locale('zh'),
        ),
      );
      await tester.pump();
      await tester.tap(later);
      await tester.pumpAndSettle();
      expect(find.text('main-app'), findsOneWidget);
      sdkReply!.complete(36);
      await tester.pumpAndSettle();
      expect(find.text('main-app'), findsOneWidget);
      expect(find.byType(NotificationPermissionSetupPage), findsNothing);
      expect(requested('requestNotificationsPermission'), 0);
    },
  );

  testWidgets(
    'welcome and baseline questionnaire remain before permission setup',
    (tester) async {
      await open(tester, questionnaire: true);
      expect(find.byType(QuestionnairePromptPage), findsOneWidget);
      expect(find.byType(NotificationPermissionSetupPage), findsNothing);
      expect(settingsCalls, isEmpty);
    },
  );

  test(
    'preference write failure still remembers Later for this process',
    () async {
      SharedPreferencesStorePlatform.instance = SetupWriteFailure();
      await notifications.markPermissionSetupHandled();
      expect(await notifications.shouldOfferPermissionSetup(), isFalse);
    },
  );

  for (final language in ['zh', 'en', 'id']) {
    for (final width in [320.0, 390.0]) {
      testWidgets(
        '$language ${width.toInt()}px permission guide fits above phone navigation',
        (tester) async {
          tester.view.physicalSize = Size(width, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await open(tester, language: language);
          expect(later.hitTestable(), findsOneWidget);
          await qa.screenshot(
            tester,
            'notification-onboarding-$language-${width.toInt()}-20261027',
          );
          await tester.ensureVisible(later);
          await tester.pumpAndSettle();
          expect(tester.getBottomRight(later).dy, lessThanOrEqualTo(592));
          expect(tester.takeException(), isNull);
          await press(tester, later);
          expect(find.text('main-app'), findsOneWidget);
        },
      );
    }
  }
}
