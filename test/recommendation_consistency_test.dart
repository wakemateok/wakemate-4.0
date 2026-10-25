import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/api/home_data.dart';
import 'package:my_app/api/recommendation_failure.dart';
import 'package:my_app/api/day_record_replacement.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/screens/CaffeineRecommendationPage.dart';
import 'package:my_app/screens/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hospital_review_widget_test.dart' as qa;

final sleeps = <Map<String, dynamic>>[
  {
    'id': 1,
    'user_id': 'owner',
    'sleep_start_time': '2026-10-20T00:00:00Z',
    'sleep_end_time': '2026-10-20T08:30:00Z',
    'is_active': true,
  },
];
final wakes = <Map<String, dynamic>>[
  {
    'id': 2,
    'user_id': 'owner',
    'target_start_time': '2026-10-20T08:00:00Z',
    'target_end_time': '2026-10-20T10:00:00Z',
    'is_active': true,
  },
  {
    'id': 3,
    'user_id': 'owner',
    'target_start_time': '2026-10-25T08:00:00Z',
    'target_end_time': '2026-10-25T10:00:00Z',
    'is_active': true,
  },
];
final referenceTime = DateTime.utc(2026, 10, 20);

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('WAKEMATE_CAPTURE_QA')) {
      final font = FontLoader('ReviewQA');
      font.addFont(
        File(
          'C:/Windows/Fonts/msjh.ttc',
        ).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        File(
          'C:/src/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
        ).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
      await icons.load();
    }
  });
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'home_guide_seen_owner': true}),
  );

  test(
    'unfinished overlap cannot be bypassed by leaving calculation and reopening home',
    () async {
      final calls = <String>[];
      final repo = HomeRepository(
        now: () => referenceTime,
        client: MockClient((r) async {
          calls.add('${r.method} ${r.url.path}');
          final endpoint = r.url.path.split('/')[1];
          final rows =
              endpoint == 'users_sleep'
                  ? sleeps
                  : endpoint == 'users_wake'
                  ? wakes
                  : <Map<String, dynamic>>[];
          return http.Response(jsonEncode(rows), 200);
        }),
      );
      for (final recalculate in [true, false]) {
        final result = await repo.load('owner', recalculate: recalculate);
        expect(result.calculationFailed, isTrue);
        expect(result.recommendationFailure?.code, 'sleep_wake_overlap');
        expect(result.recommendations, isEmpty);
        expect(result.hasWake, isTrue);
        expect(
          result.recommendationFailure!.message('zh'),
          contains('2026/10/20 16:30'),
        );
      }
      expect(
        calls.any(
          (call) =>
              call.startsWith('POST') || call.contains('/recommendations/'),
        ),
        isFalse,
      );
      repo.close();
    },
  );

  test('adjacent periods and deleted history do not cause false conflicts', () {
    final adjacent = [
      {...wakes.first, 'target_start_time': '2026-10-20T08:30:00Z'},
    ];
    expect(findSleepWakeConflict(sleeps, adjacent, now: referenceTime), isNull);
    expect(
      findSleepWakeConflict(
        [
          {...sleeps.first, 'is_active': false},
        ],
        wakes,
        now: referenceTime,
      ),
      isNull,
    );
    expect(
      findSleepWakeConflict(
        [
          {...sleeps.first, 'deleted_at': '2026-10-21T00:00:00Z'},
        ],
        wakes,
        now: referenceTime,
      ),
      isNull,
    );
    expect(
      findSleepWakeConflict(
        [
          {...sleeps.first, 'invalidated_at': '2026-10-21T00:00:00Z'},
        ],
        wakes,
        now: referenceTime,
      ),
      isNull,
    );
  });

  test(
    'structured 400 is localized with precise Taipei conflict times instead of raw JSON',
    () {
      final error = findSleepWakeConflict(sleeps, wakes, now: referenceTime)!;
      final parsed = RecommendationFailure.fromBody(
        jsonEncode({
          'detail': {'type': error.code, ...error.detail!},
        }),
      );
      for (final language in ['zh', 'en', 'id']) {
        final text = parsed.message(language);
        expect(text, contains('2026/10/20 08:00'));
        expect(text, contains('2026/10/20 16:30'));
        expect(text, isNot(contains('"detail"')));
        if (language != 'zh')
          expect(RegExp(r'[\u4e00-\u9fff]').hasMatch(text), isFalse);
      }
    },
  );

  test(
    'a server conflict cannot fetch or reuse otherwise active old recommendations',
    () async {
      final calls = <String>[];
      final repo = HomeRepository(
        now: () => referenceTime,
        client: MockClient((r) async {
          calls.add(r.url.path);
          if (r.url.path == '/users_sleep/')
            return http.Response(jsonEncode(sleeps), 200);
          if (r.url.path == '/users_wake/')
            return http.Response(
              jsonEncode([
                {...wakes.first, 'target_start_time': '2026-10-20T09:00:00Z'},
              ]),
              200,
            );
          if (r.method == 'POST')
            return http.Response(
              jsonEncode({
                'detail': {'type': 'sleep_wake_overlap'},
              }),
              400,
            );
          return http.Response('[]', 200);
        }),
      );
      final snapshot = await repo.load('owner', recalculate: true);
      expect(snapshot.recommendationFailure?.code, 'sleep_wake_overlap');
      expect(snapshot.recommendations, isEmpty);
      expect(calls, isNot(contains('/recommendations/')));
      repo.close();
    },
  );

  for (final language in ['zh', 'en', 'id']) {
    testWidgets(
      '$language blocked recommendation and home remain consistent above phone navigation',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final failure =
            findSleepWakeConflict(sleeps, wakes, now: referenceTime)!;
        final snapshot = HomeSnapshot(
          sleeps: sleeps,
          wakes: wakes,
          intakes: [],
          recommendations: [],
          hasProfile: true,
          calculationFailed: true,
          recommendationFailure: failure,
        );
        final repo = qa.FixtureHomeRepository(snapshot);
        await tester.pumpWidget(
          qa.app(
            CaffeineRecommendationPage(
              userId: 'owner',
              selectedDate: DateTime(2026, 10, 25),
              repository: repo,
            ),
            Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(failure.message(language)), findsOneWidget);
        await qa.screenshot(tester, 'overlap-$language-320');
        final l10n =
            AppLocalizations.of(
              tester.element(find.byType(CaffeineRecommendationPage)),
            )!;
        expect(find.text(l10n.inputHistory), findsOneWidget);
        await tester.ensureVisible(find.text(l10n.retry));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.retry));
        await tester.pumpAndSettle();
        expect(repo.loads, 2);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          qa.app(
            HomePage(
              userId: 'owner',
              repository: repo,
              showQuestionnaireReminder: false,
            ),
            Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(failure.message(language)), findsOneWidget);
        expect(find.textContaining('50 mg'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'rejected overlapping save stays distinct from saved-but-blocked calculation',
    (tester) async {
      await tester.pumpWidget(
        qa.app(const Scaffold(body: Text('Test')), const Locale('zh', 'TW')),
      );
      final l10n = AppLocalizations.of(tester.element(find.text('Test')))!;
      final error = findSleepWakeConflict(sleeps, wakes, now: referenceTime)!;
      final text = recordSaveErrorText(
        RecordSaveException(error.code, error.detail),
        l10n,
      );
      expect(text, contains('本次輸入未儲存'));
      expect(text, contains('2026/10/20 16:30'));
    },
  );
}
