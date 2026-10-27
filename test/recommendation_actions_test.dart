import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_app/api/home_data.dart';
import 'package:my_app/screens/CaffeineHistory.dart';
import 'package:my_app/screens/drink_match_page.dart';
import 'package:my_app/screens/home_page.dart';
import 'package:my_app/screens/RegisterPage.dart';
import 'package:my_app/utils/password_policy.dart';
import 'package:my_app/utils/review_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hospital_review_widget_test.dart' as qa;

class DelayedRepository extends qa.FixtureHomeRepository {
  DelayedRepository(super.snapshot);
  Completer<HomeSnapshot>? pending;
  @override
  Future<HomeSnapshot> load(String userId, {bool recalculate = false}) async {
    if (!recalculate) return super.load(userId, recalculate: recalculate);
    loads++;
    lastRecalculate = true;
    pending = Completer<HomeSnapshot>();
    return pending!.future;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    if (const bool.fromEnvironment('WAKEMATE_CAPTURE_QA')) {
      for (final entry
          in {
            'ReviewQA': 'C:/Windows/Fonts/msjh.ttc',
            'MaterialIcons':
                'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          }.entries) {
        final font = FontLoader(entry.key);
        font.addFont(
          File(entry.value).readAsBytes().then(ByteData.sublistView),
        );
        await font.load();
      }
    }
  });
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'home_guide_seen_owner': true}),
  );

  test(
    'new password policy accepts short values but not blank or oversized values',
    () {
      for (final value in ['a', '1234', '密', ' a ', 'a' * 72, '密' * 24]) {
        expect(acceptsNewPassword(value), isTrue, reason: value);
      }
      for (final value in ['', ' ', '\t\n', '\u3000', 'a' * 73, '密' * 25]) {
        expect(acceptsNewPassword(value), isFalse);
      }
    },
  );

  for (final language in ['zh', 'en', 'id']) {
    testWidgets(
      '$language registration password can be shown and its button fits above the keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpWidget(qa.app(const RegisterPage(), Locale(language)));
        await tester.pumpAndSettle();
        final password = find.byType(TextField).last;
        await tester.ensureVisible(password);
        await tester.pumpAndSettle();
        await tester.enterText(password, 'a');
        expect(tester.widget<TextField>(password).obscureText, isTrue);
        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(password).obscureText, isFalse);
        expect(tester.widget<TextField>(password).controller!.text, 'a');
        await qa.screenshot(tester, 'registration-password-$language-20261027');
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        await tester.pumpAndSettle();
        final submit = find.byType(ElevatedButton);
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        expect(submit.hitTestable(), findsOneWidget);
        expect(tester.getBottomRight(submit).dy, lessThanOrEqualTo(352));
        expect(tester.takeException(), isNull);
      },
    );
    for (final width in [320.0, 390.0]) {
      testWidgets(
        '$language ${width.toInt()}px recommendation commands are distinct, visible and reachable',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = DelayedRepository(qa.fixture());
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
          final generate = find.byKey(
            const ValueKey('home-generate-recommendation'),
          );
          final history = find.byKey(
            const ValueKey('home-recommendation-history'),
          );
          final view = find.widgetWithText(
            OutlinedButton,
            reviewText('viewDrinks', language),
          );
          expect(generate, findsOneWidget);
          expect(history, findsOneWidget);
          expect(view, findsOneWidget);
          expect(find.byIcon(Icons.history), findsNothing);
          expect(find.byIcon(Icons.local_cafe_outlined), findsNothing);
          for (final button in [generate, history, view]) {
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            expect(button.hitTestable(), findsOneWidget);
            expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
            expect(tester.getTopLeft(button).dx, greaterThanOrEqualTo(0));
            expect(tester.getBottomRight(button).dx, lessThanOrEqualTo(width));
            expect(tester.getBottomRight(button).dy, lessThanOrEqualTo(796));
          }
          await qa.screenshot(
            tester,
            'recommendation-actions-$language-${width.toInt()}-20261027',
          );
          await tester.ensureVisible(generate);
          await tester.pumpAndSettle();
          await tester.tap(generate);
          await tester.pump();
          expect(tester.widget<FilledButton>(generate).onPressed, isNull);
          await tester.tap(generate);
          await tester.pump();
          expect(repo.loads, 2);
          repo.pending!.complete(repo.snapshot);
          await tester.pumpAndSettle();
          expect(repo.lastRecalculate, isTrue);
          expect(tester.widget<FilledButton>(generate).onPressed, isNotNull);
          await tester.ensureVisible(view);
          await tester.pumpAndSettle();
          await tester.tap(view);
          await tester.pumpAndSettle();
          final match = tester.widget<DrinkMatchPage>(
            find.byType(DrinkMatchPage),
          );
          expect(match.targetMg, 75);
          expect(match.recommendedAt.hour, 18);
          Navigator.of(tester.element(find.byType(DrinkMatchPage))).pop();
          await tester.pumpAndSettle();
          await tester.ensureVisible(history);
          await tester.pumpAndSettle();
          await tester.tap(history);
          await tester.pumpAndSettle();
          expect(find.byType(CaffeineHistoryPage), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
        skip: const String.fromEnvironment('WAKEMATE_ALERTNESS_MODE') != 'pvtb',
      );
    }
  }

  testWidgets(
    'manual generation stays disabled while prerequisite records are missing',
    (tester) async {
      final snapshot = HomeSnapshot(
        sleeps: [],
        wakes: [],
        intakes: [],
        recommendations: [],
        hasProfile: false,
      );
      await tester.pumpWidget(
        qa.app(
          HomePage(
            userId: 'owner',
            repository: qa.FixtureHomeRepository(snapshot),
            showQuestionnaireReminder: false,
          ),
          const Locale('zh'),
        ),
      );
      await tester.pumpAndSettle();
      final generate = find.byKey(
        const ValueKey('home-generate-recommendation'),
      );
      expect(tester.widget<FilledButton>(generate).onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
    skip: const String.fromEnvironment('WAKEMATE_ALERTNESS_MODE') != 'pvtb',
  );
}
