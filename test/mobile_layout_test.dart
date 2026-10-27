import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/screens/notification_center_page.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/screens/CaffeineLogPage.dart';
import 'package:my_app/screens/SleepTimeLogPage.dart';
import 'package:my_app/screens/WakeTimeLogPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final locale in [
    const Locale('zh', 'TW'),
    const Locale('en'),
    const Locale('id'),
  ]) {
    for (final size in [const Size(320, 640), const Size(390, 844)]) {
      testWidgets(
        '${locale.toLanguageTag()} ${size.width.toInt()}px layouts respect large text and bottom navigation',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({
            'wakemate_notification_history': jsonEncode([
              {
                'type': 'caffeine_reminder',
                'status': 'due_unconfirmed',
                'title': 'WakeMate caffeine reminder',
                'body': '25 mg',
                'createdAt': '2026-10-15T01:00:00Z',
                'scheduledAt': '2026-10-15T02:00:00Z',
              },
            ]),
          });
          for (final page in <Widget>[
            NotificationCenterPage(
              notifications: NotificationService.forTesting(),
            ),
            CaffeineLogPage(
              userId: 'test-user',
              selectedDate: DateTime(2026, 10, 20),
            ),
            ActualSleepTimePage(
              userId: 'test-user',
              selectedDate: DateTime(2026, 10, 20),
            ),
            TargetWakeTimePage(
              userId: 'test-user',
              selectedDate: DateTime(2026, 10, 20),
            ),
          ]) {
            await tester.pumpWidget(
              MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder:
                    (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.5),
                        padding: const EdgeInsets.only(bottom: 48),
                        viewPadding: const EdgeInsets.only(bottom: 48),
                      ),
                      child: child!,
                    ),
                home: page,
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${page.runtimeType} overflow',
            );
            final button = find.byType(ElevatedButton).last;
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            expect(
              tester.getBottomRight(button).dy,
              lessThanOrEqualTo(size.height - 48),
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
}
