import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:my_app/screens/CaffeineHistory.dart';
import 'package:my_app/screens/CaffeineRecommendationPage.dart';
import 'package:my_app/screens/home_page.dart';
import 'package:my_app/api/home_data.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'auth_security_test.dart' as auth_fixture;
import 'hospital_review_widget_test.dart' as layout;

class UnavailablePreferences extends InMemorySharedPreferencesStore {
  UnavailablePreferences({this.failReads = false}) : super.empty();
  final bool failReads;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      throw PlatformException(code: 'cache_unavailable');
  @override
  Future<Map<String, Object>> getAll() async =>
      failReads
          ? throw PlatformException(code: 'cache_unavailable')
          : super.getAll();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final language in ['zh', 'en', 'id']) {
    testWidgets('$language empty history controls fit above phone navigation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        layout.app(
          CaffeineHistoryPage(
            userId: 'user-one',
            selectedDate: DateTime(2026, 10, 25),
            confirmedEntries: const [],
          ),
          Locale(language),
        ),
      );
      await tester.pumpAndSettle();
      final l10n =
          AppLocalizations.of(
            tester.element(find.byType(CaffeineHistoryPage)),
          )!;
      final button = find.text(l10n.calculateAgain);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(button).dy, lessThanOrEqualTo(592));
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'successful secure login and rotation survive optional cache write failures',
    () async {
      final store = auth_fixture.MemorySessionStore();
      final auth = AuthService(
        store: store,
        baseUri: Uri.parse('https://api.example.com'),
        client: MockClient(
          (request) async => auth_fixture.jsonResponse(
            auth_fixture.pair(request.url.path == '/login/' ? '1' : '2'),
          ),
        ),
      );
      SharedPreferencesStorePlatform.instance = UnavailablePreferences();
      var updates = 0;
      auth.addListener(() => updates++);
      await auth.login('test@example.com', 'Password-2026!');
      expect(auth.userId, 'user-one');
      expect(updates, 1);
      expect(await auth.refresh(), isTrue);
      expect(auth.accessToken, 'wma_2');
      expect(jsonDecode(store.value!)['access_token'], 'wma_2');
      expect(updates, 2);
    },
  );

  testWidgets(
    'history storage read failure is a retryable error, not a stuck spinner',
    (tester) async {
      SharedPreferencesStorePlatform.instance = UnavailablePreferences(
        failReads: true,
      );
      await tester.pumpWidget(
        layout.app(
          CaffeineHistoryPage(
            userId: 'user-one',
            selectedDate: DateTime(2026, 10, 25),
          ),
          const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.byKey(const ValueKey('recommendation-history-retry')),
        findsOneWidget,
      );
      SharedPreferences.setMockInitialValues({});
      await tester.tap(
        find.byKey(const ValueKey('recommendation-history-retry')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('recommendation-history-retry')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'confirmed calculation is visible when the history cache is unreadable',
    (tester) async {
      SharedPreferencesStorePlatform.instance = UnavailablePreferences(
        failReads: true,
      );
      final snapshot = HomeSnapshot(
        sleeps: [{}],
        wakes: [{}],
        intakes: [],
        hasProfile: true,
        recommendations: [
          {
            'user_id': 'user-one',
            'recommended_caffeine_amount': 50,
            'recommended_caffeine_intake_timing': '2026-10-27T08:00:00Z',
          },
        ],
      );
      await tester.pumpWidget(
        layout.app(
          CaffeineRecommendationPage(
            userId: 'user-one',
            selectedDate: DateTime(2026, 10, 27),
            repository: layout.FixtureHomeRepository(snapshot),
          ),
          const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CaffeineHistoryPage), findsOneWidget);
      expect(find.textContaining('50 mg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'old unconfirmed future cache cannot resurface on the history page',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'caffeine_recommendations_user-one': jsonEncode([
          {
            'user_id': 'user-one',
            'recommended_caffeine_amount': 125,
            'recommended_caffeine_intake_timing': '2030-10-27T08:00:00Z',
          },
        ]),
      });
      await tester.pumpWidget(
        layout.app(
          CaffeineHistoryPage(
            userId: 'user-one',
            selectedDate: DateTime(2030, 10, 27),
            confirmedEntries: const [],
          ),
          const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('125 mg'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'returning from recalculation cannot restore the parent history old result',
    (tester) async {
      final selected = DateTime(2026, 10, 27);
      Map<String, dynamic> recommendation(int amount) => {
        'user_id': 'user-one',
        'recommended_caffeine_amount': amount,
        'recommended_caffeine_intake_timing': '2026-10-27T08:00:00Z',
      };
      final repo = layout.FixtureHomeRepository(
        HomeSnapshot(
          sleeps: [{}],
          wakes: [{}],
          intakes: [],
          hasProfile: true,
          recommendations: [recommendation(50)],
        ),
      );
      await tester.pumpWidget(
        layout.app(
          CaffeineHistoryPage(
            userId: 'user-one',
            selectedDate: selected,
            confirmedEntries: [recommendation(125)],
            repository: repo,
          ),
          const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      final l10n =
          AppLocalizations.of(
            tester.element(find.byType(CaffeineHistoryPage)),
          )!;
      final button = find.text(l10n.calculateAgain);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('50 mg'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back).last);
      await tester.pumpAndSettle();
      expect(find.textContaining('125 mg'), findsNothing);
      expect(find.textContaining('50 mg'), findsOneWidget);
      expect(repo.loads, greaterThanOrEqualTo(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('optional welcome cache failure cannot crash a loaded homepage', (
    tester,
  ) async {
    SharedPreferencesStorePlatform.instance = UnavailablePreferences(
      failReads: true,
    );
    await tester.pumpWidget(
      layout.app(
        HomePage(
          userId: 'user-one',
          showQuestionnaireReminder: false,
          repository: layout.FixtureHomeRepository(layout.fixture()),
        ),
        const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(HomePage), findsOneWidget);
  });
}
