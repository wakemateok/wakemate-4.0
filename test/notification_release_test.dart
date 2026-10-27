import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_app/screens/notification_center_page.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hospital_review_widget_test.dart' as qa;

void main() {
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  var invalidIcon = false;
  var pendingFailed = false;
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
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    SharedPreferences.setMockInitialValues({});
    invalidIcon = false;
    pendingFailed = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'initialize':
              if (invalidIcon) {
                throw PlatformException(code: 'invalid_icon');
              }
              return true;
            case 'pendingNotificationRequests':
              if (pendingFailed) {
                throw PlatformException(code: 'pending_read_failed');
              }
              return [];
            case 'areNotificationsEnabled':
            case 'requestNotificationsPermission':
              return true;
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
    'PVT-B dynamic notification icon has a release keep rule and artifact gate',
    () {
      expect(
        File(
          'android/app/src/pvtb/res/raw/wakemate_notification_keep.xml',
        ).readAsStringSync(),
        contains('tools:keep="@drawable/ic_notification"'),
      );
      expect(
        File('scripts/build_signed_apks.ps1').readAsStringSync(),
        contains('verify_release_apk.ps1'),
      );
      expect(
        File('scripts/verify_release_apk.ps1').readAsStringSync(),
        contains('drawable/ic_notification'),
      );
      expect(
        File(
          'android/app/src/main/res/drawable/ic_notification.xml',
        ).existsSync(),
        isTrue,
      );
    },
  );

  for (final language in ['zh', 'en', 'id']) {
    void size(WidgetTester tester) {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets(
      '$language invalid icon is explicit and cannot look like zero pending reminders',
      (tester) async {
        size(tester);
        invalidIcon = true;
        await tester.pumpWidget(
          qa.app(
            NotificationCenterPage(
              notifications: NotificationService.forTesting(),
            ),
            Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('pending-reminder-count')),
              )
              .data,
          '?',
        );
        expect(find.textContaining('invalid_icon'), findsOneWidget);
        expect(find.byIcon(Icons.notifications_none_outlined), findsNothing);
        await qa.screenshot(
          tester,
          'notification-invalid-icon-$language-20261027',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        expect(find.textContaining('invalid_icon'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '$language a native read failure preserves successfully loaded history',
      (tester) async {
        size(tester);
        final service = NotificationService.forTesting();
        await service.showTestNotification(languageCode: language);
        pendingFailed = true;
        await tester.pumpWidget(
          qa.app(
            NotificationCenterPage(notifications: service),
            Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('pending-reminder-count')),
              )
              .data,
          '?',
        );
        expect(find.textContaining('pending_read_failed'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byIcon(Icons.notifications_active_outlined),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(
          find.byIcon(Icons.notifications_active_outlined),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.notifications_none_outlined), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('$language a confirmed empty native list can show zero', (
      tester,
    ) async {
      size(tester);
      await tester.pumpWidget(
        qa.app(
          NotificationCenterPage(
            notifications: NotificationService.forTesting(),
          ),
          Locale(language),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('pending-reminder-count')))
            .data,
        '0',
      );
      await tester.scrollUntilVisible(
        find.byIcon(Icons.notifications_none_outlined),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
