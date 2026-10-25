import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/screens/CaffeineLogPage.dart';
import 'package:my_app/screens/SleepTimeLogPage.dart';
import 'package:my_app/screens/WakeTimeLogPage.dart';
import 'package:my_app/screens/UserInputHistoryPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'teacher_readiness_test.dart' as fixture;
import 'hospital_review_widget_test.dart' as layout;

class FailingStorage extends InMemorySharedPreferencesStore {
  FailingStorage({this.failReads = false}) : super.empty();
  final bool failReads;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      throw PlatformException(code: 'storage_unavailable');
  @override
  Future<Map<String, Object>> getAll() async =>
      failReads
          ? throw PlatformException(code: 'storage_unavailable')
          : super.getAll();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final language in ['zh', 'en', 'id']) {
    testWidgets(
      '$language history error recovery and record actions fit a small phone',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var fail = true;
        final client = MockClient((request) async {
          if (fail) return http.Response('unavailable', 503);
          return http.Response(
            jsonEncode(
              request.url.path == '/users_intake/'
                  ? [
                    {
                      'id': 1,
                      'user_id': 'owner',
                      'taking_timestamp': '2026-10-25T02:00:00Z',
                      'drink_name': 'TEST-COFFEE',
                      'caffeine_amount': 50,
                    },
                  ]
                  : [],
            ),
            200,
          );
        });
        await tester.pumpWidget(
          layout.app(
            UserInputHistoryPage(
              userId: 'owner',
              selectedDate: DateTime(2026, 10, 25),
              client: client,
            ),
            Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final retry = find.byKey(const ValueKey('input-history-retry'));
        await tester.ensureVisible(retry);
        await tester.pumpAndSettle();
        expect(tester.getBottomRight(retry).dy, lessThanOrEqualTo(592));
        fail = false;
        await tester.tap(retry);
        await tester.pumpAndSettle();
        final l10n =
            AppLocalizations.of(
              tester.element(find.byType(UserInputHistoryPage)),
            )!;
        final delete = find.text(l10n.delete);
        await tester.scrollUntilVisible(delete, 150);
        await tester.pumpAndSettle();
        expect(tester.getBottomRight(delete).dy, lessThanOrEqualTo(592));
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final kind in ['caffeine', 'sleep', 'wake']) {
    testWidgets(
      '$kind save confirmed by server is not reported failed when local storage fails',
      (tester) async {
        var posts = 0;
        final client = MockClient((request) async {
          posts++;
          return http.Response(
            '{"status":"success","ids":[1],"calculation":{"status":"ok"}}',
            200,
          );
        });
        SharedPreferencesStorePlatform.instance = FailingStorage();
        bool? result;
        Widget page() => switch (kind) {
          'sleep' => ActualSleepTimePage(
            userId: 'owner',
            selectedDate: DateTime(2026, 10, 25),
            client: client,
          ),
          'wake' => TargetWakeTimePage(
            userId: 'owner',
            selectedDate: DateTime(2026, 10, 25),
            client: client,
          ),
          _ => CaffeineLogPage(
            userId: 'owner',
            selectedDate: DateTime(2026, 10, 25),
            client: client,
          ),
        };
        await tester.pumpWidget(
          fixture.localized(
            Builder(
              builder:
                  (context) => Scaffold(
                    body: TextButton(
                      onPressed:
                          () async =>
                              result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(builder: (_) => page()),
                              ),
                      child: const Text('Open'),
                    ),
                  ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final save = find.byType(ElevatedButton).last;
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(posts, 1);
        expect(
          result,
          isTrue,
          reason:
              'Server save succeeded; a cache error must not invite a duplicate save.',
        );
        expect(find.text('Open'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('a history read failure must not look like an empty database', (
    tester,
  ) async {
    var fail = true;
    final client = MockClient((request) async {
      if (request.url.path == '/users_sleep/' && fail) {
        return http.Response('private backend error', 503);
      }
      return http.Response('[]', 200);
    });
    await tester.pumpWidget(
      fixture.localized(
        UserInputHistoryPage(
          userId: 'owner',
          selectedDate: DateTime(2026, 10, 25),
          client: client,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n =
        AppLocalizations.of(tester.element(find.byType(UserInputHistoryPage)))!;
    expect(find.text(l10n.noInputRecords), findsNothing);
    expect(find.text('private backend error'), findsNothing);
    final retry = find.byKey(const ValueKey('input-history-retry'));
    expect(retry, findsOneWidget);
    fail = false;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text(l10n.noInputRecords), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'wake form still opens when the optional draft cache cannot be read',
    (tester) async {
      SharedPreferencesStorePlatform.instance = FailingStorage(failReads: true);
      await tester.pumpWidget(
        fixture.localized(
          TargetWakeTimePage(
            userId: 'owner',
            selectedDate: DateTime(2026, 10, 25),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'malformed history cannot be mistaken for a successful empty result',
    (tester) async {
      final client = MockClient(
        (request) async => http.Response('{"unexpected": "response"}', 200),
      );
      await tester.pumpWidget(
        fixture.localized(
          UserInputHistoryPage(
            userId: 'owner',
            selectedDate: DateTime(2026, 10, 25),
            client: client,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('input-history-retry')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('history never renders records belonging to another account', (
    tester,
  ) async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode(
          request.url.path == '/users_intake/'
              ? [
                {
                  'id': 1,
                  'user_id': 'other',
                  'taking_timestamp': '2026-10-25T02:00:00Z',
                  'drink_name': 'PRIVATE-OTHER-ACCOUNT',
                  'caffeine_amount': 50,
                },
              ]
              : [],
        ),
        200,
      ),
    );
    await tester.pumpWidget(
      fixture.localized(
        UserInputHistoryPage(
          userId: 'owner',
          selectedDate: DateTime(2026, 10, 25),
          client: client,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('PRIVATE-OTHER-ACCOUNT'), findsNothing);
    expect(find.byKey(const ValueKey('input-history-retry')), findsOneWidget);
  });
}
