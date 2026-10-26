import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_app/api/home_data.dart';
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/config/app_release.dart';
import 'package:my_app/screens/feedback_page.dart';
import 'package:my_app/screens/home_page.dart';
import 'package:my_app/services/feedback_service.dart';
import 'package:my_app/utils/feedback_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hospital_review_widget_test.dart' as qa;

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    if (const bool.fromEnvironment('WAKEMATE_CAPTURE_QA')) {
      final font = FontLoader('ReviewQA');
      font.addFont(
        File(
          'C:/Windows/Fonts/msjh.ttc',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        File(
          'C:/src/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await icons.load();
    }
  });
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'home_guide_seen_owner': true}),
  );

  HomeSnapshot snapshot({bool intake = false}) => HomeSnapshot(
    sleeps: [],
    wakes: [],
    intakes:
        intake
            ? [
              {
                'user_id': 'owner',
                'taking_timestamp': DateTime.now().toUtc().toIso8601String(),
                'caffeine_amount': 125,
              },
            ]
            : [],
    recommendations: [],
    hasProfile: false,
  );

  test(
    'missing records are distinct from recorded totals without changing numbers',
    () {
      final empty = snapshot().summary(taipeiDateOnly(taipeiNow()));
      expect(empty.caffeineMg, 0);
      expect(empty.hasCaffeineRecord || empty.hasSleepRecord, isFalse);
      final caffeineOnly = snapshot(
        intake: true,
      ).summary(taipeiDateOnly(taipeiNow()));
      expect(caffeineOnly.caffeineMg, 125);
      expect(caffeineOnly.hasCaffeineRecord, isTrue);
      expect(caffeineOnly.hasSleepRecord, isFalse);
      final shortSleep = HomeSnapshot(
        sleeps: [
          {
            'sleep_start_time': '2026-10-25T16:00:00Z',
            'sleep_end_time': '2026-10-25T16:00:15Z',
          },
        ],
        wakes: [],
        intakes: [],
        recommendations: [],
        hasProfile: false,
      );
      expect(shortSleep.summary(DateTime(2026, 10, 26)).hasSleepRecord, isTrue);
    },
  );

  test(
    'mailto preserves Unicode and punctuation without injecting recipient fields',
    () {
      const draft = FeedbackDraft(
        description: ' 中文 & + ? #\nTidak bisa masuk ',
        subject: '卡住\r\nBcc: other@example.com',
        language: 'zh',
      );
      final uri = draft.mailUri;
      expect(uri.scheme, 'mailto');
      expect(uri.path, 'wakemateok@gmail.com');
      expect(uri.queryParameters.keys, unorderedEquals(['subject', 'body']));
      expect(uri.queryParameters['body'], draft.emailBody);
      expect(uri.queryParameters['subject'], isNot(contains('\n')));
      expect(uri.toString(), contains('%20'));
      expect(uri.toString(), isNot(contains('+')));
      expect(draft.emailBody, contains(AppRelease.label));
      expect(draft.emailBody, isNot(contains('user_id')));
      expect(draft.emailBody, isNot(contains('access_token')));
    },
  );

  test(
    'metadata can be omitted and release diagnostics match the package version',
    () {
      const draft = FeedbackDraft(description: 'Report', includeVersion: false);
      expect(draft.emailBody, isNot(contains('Version:')));
      expect(draft.emailBody, isNot(contains('Protocol:')));
      expect(
        File('pubspec.yaml').readAsLinesSync(),
        contains('version: ${AppRelease.label}'),
      );
    },
  );

  for (final language in ['zh', 'en', 'id']) {
    testWidgets(
      '$language empty home has blank metrics and a prominent brand',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          qa.app(
            HomePage(
              userId: 'owner',
              repository: qa.FixtureHomeRepository(snapshot()),
              showQuestionnaireReminder: false,
            ),
            Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('0'), findsNothing);
        expect(find.text('0.0'), findsNothing);
        final brand = tester.widget<Text>(
          find.byKey(const ValueKey('home-brand')),
        );
        expect(brand.style!.fontWeight, FontWeight.w800);
        expect(brand.style!.fontSize, 32);
        await qa.screenshot(tester, 'home-empty-$language-20261026');
        await tester.tap(find.byKey(const ValueKey('home-feedback')));
        await tester.pumpAndSettle();
        expect(find.byType(FeedbackPage), findsOneWidget);
        expect(find.text(feedbackText('title', language)), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$language recorded caffeine remains visible without missing sleep zeros',
      (tester) async {
        await tester.pumpWidget(
          qa.app(
            HomePage(
              userId: 'owner',
              repository: qa.FixtureHomeRepository(snapshot(intake: true)),
              showQuestionnaireReminder: false,
            ),
            Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('125'), findsWidgets);
        expect(find.text('0.0'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$language feedback validation, email and copy fit a small phone keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        Uri? opened;
        String? copied;
        await tester.pumpWidget(
          qa.app(
            FeedbackPage(
              openEmail: (uri) async {
                opened = uri;
                return true;
              },
              copyReport: (value) async {
                copied = value;
              },
            ),
            Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        final send = find.byKey(const ValueKey('feedback-open-mail'));
        await tester.ensureVisible(send);
        await tester.tap(send);
        await tester.pumpAndSettle();
        expect(opened, isNull);
        final description = find.byKey(const ValueKey('feedback-description'));
        await tester.ensureVisible(description);
        await tester.enterText(description, '測試內容 + &\nLaporan masalah');
        await tester.ensureVisible(send);
        await tester.tap(send);
        await tester.pumpAndSettle();
        expect(opened!.path, 'wakemateok@gmail.com');
        final status = find.byKey(const ValueKey('feedback-status'));
        await tester.ensureVisible(status);
        await tester.pumpAndSettle();
        expect(find.text(feedbackText('mailOpened', language)), findsOneWidget);
        expect(tester.getBottomRight(status).dy, lessThanOrEqualTo(352));
        await qa.screenshot(tester, 'feedback-$language-20261026');
        final copy = find.byKey(const ValueKey('feedback-copy'));
        await tester.ensureVisible(copy);
        await tester.tap(copy);
        await tester.pumpAndSettle();
        expect(copied, contains('測試內容 + &'));
        expect(find.text(feedbackText('copied', language)), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final throws in [false, true]) {
    testWidgets('missing mail app offers a copy fallback (throw=$throws)', (
      tester,
    ) async {
      await tester.pumpWidget(
        qa.app(
          FeedbackPage(
            openEmail: (_) async {
              if (throws) throw PlatformException(code: 'no_activity');
              return false;
            },
            copyReport: (_) async {},
          ),
          const Locale('en'),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('feedback-description')),
        'A problem',
      );
      final button = find.byKey(const ValueKey('feedback-open-mail'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text(feedbackText('mailUnavailable', 'en')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'opening email cannot be submitted repeatedly while a launcher is pending',
    (tester) async {
      var calls = 0;
      final gate = Completer<bool>();
      await tester.pumpWidget(
        qa.app(
          FeedbackPage(
            openEmail: (_) {
              calls++;
              return gate.future;
            },
          ),
          const Locale('en'),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('feedback-description')),
        'A problem',
      );
      final button = find.byKey(const ValueKey('feedback-open-mail'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.tap(button);
      expect(calls, 1);
      gate.complete(false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'drawer feedback opens the same form and preserves the getting-started entry',
    (tester) async {
      await tester.pumpWidget(
        qa.app(
          HomePage(
            userId: 'owner',
            repository: qa.FixtureHomeRepository(snapshot()),
            showQuestionnaireReminder: false,
          ),
          const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      final homeContext = tester.element(find.byType(HomePage));
      Scaffold.of(tester.element(find.byIcon(Icons.menu))).openDrawer();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.checklist_outlined), findsOneWidget);
      await tester.tap(find.text(feedbackText('title', 'en')));
      await tester.pumpAndSettle();
      expect(find.byType(FeedbackPage), findsOneWidget);
      Navigator.of(homeContext).maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(FeedbackPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'version opt-out is honored by both mail and copy; copy failure is explicit',
    (tester) async {
      Uri? opened;
      String? copied;
      await tester.pumpWidget(
        qa.app(
          FeedbackPage(
            openEmail: (uri) async {
              opened = uri;
              return true;
            },
            copyReport: (value) async {
              copied = value;
              throw PlatformException(code: 'clipboard_unavailable');
            },
          ),
          const Locale('en'),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('feedback-description')),
        'Report without diagnostics',
      );
      final version = find.byKey(const ValueKey('feedback-version'));
      await tester.ensureVisible(version);
      await tester.pumpAndSettle();
      await tester.tap(version);
      await tester.pumpAndSettle();
      final mail = find.byKey(const ValueKey('feedback-open-mail'));
      await tester.ensureVisible(mail);
      await tester.pumpAndSettle();
      await tester.tap(mail);
      await tester.pumpAndSettle();
      expect(opened!.queryParameters['body'], isNot(contains('Version:')));
      final copy = find.byKey(const ValueKey('feedback-copy'));
      await tester.ensureVisible(copy);
      await tester.pumpAndSettle();
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(copied, isNot(contains('Version:')));
      expect(find.text(feedbackText('copyFailed', 'en')), findsOneWidget);
      expect(find.text(feedbackText('copied', 'en')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unsent report asks before discarding and retains input when staying',
    (tester) async {
      await tester.pumpWidget(
        qa.app(
          Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FeedbackPage(),
                          ),
                        ),
                    child: const Text('Open'),
                  ),
                ),
          ),
          const Locale('en'),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('feedback-description')),
        'Unsent report',
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text(feedbackText('discardTitle', 'en')), findsOneWidget);
      await tester.tap(find.text(feedbackText('stay', 'en')));
      await tester.pumpAndSettle();
      expect(find.text('Unsent report'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(feedbackText('leave', 'en')));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
