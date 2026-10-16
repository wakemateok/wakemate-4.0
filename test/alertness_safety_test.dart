import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/screens/alertness_test.dart';
import 'package:my_app/utils/review_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  const target = ValueKey('alertness-response-target');

  Future<void> openTest(
    WidgetTester tester, {
    required bool pvtb,
    http.Client? client,
    Locale locale = const Locale('en'),
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(bottom: 48),
                viewPadding: const EdgeInsets.only(bottom: 48),
              ),
              child: child!,
            ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: ElevatedButton(
                  onPressed:
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              (_) =>
                                  pvtb
                                      ? AlertnessTestPage.pvtb(
                                        userId: 'test-user',
                                        client: client,
                                      )
                                      : AlertnessTestPage(
                                        userId: 'test-user',
                                        client: client,
                                      ),
                        ),
                      ),
                  child: const Text('Open test'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('Open test'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('alertness-start')));
    await tester.tap(find.byKey(const ValueKey('alertness-start')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(target));
  }

  Future<void> waitForStimulus(WidgetTester tester) async {
    final l10n =
        AppLocalizations.of(tester.element(find.byType(AlertnessTestPage)))!;
    for (var i = 0; i < 100; i++) {
      if (find.text(l10n.alertnessTapNow).evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('Stimulus did not appear');
  }

  for (final pvtb in [false, true]) {
    testWidgets(
      '${pvtb ? 'PVT-B' : 'brief'}: early press is detected on down and release is not a response',
      (tester) async {
        await openTest(tester, pvtb: pvtb);
        final l10n =
            AppLocalizations.of(
              tester.element(find.byType(AlertnessTestPage)),
            )!;
        final held = await tester.startGesture(
          tester.getCenter(find.byKey(target)),
        );
        await tester.pump();
        expect(find.text(l10n.alertnessTooEarly), findsWidgets);
        await waitForStimulus(tester);
        await held.up();
        await tester.pump();
        expect(find.text(l10n.alertnessTapNow), findsWidgets);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final language in ['zh', 'en', 'id']) {
    testWidgets(
      '$language test feedback and KSS fit large text above navigation area',
      (tester) async {
        await openTest(
          tester,
          pvtb: true,
          locale: Locale(language),
          scale: 1.5,
        );
        await tester.pump(const Duration(minutes: 3));
        await tester.pumpAndSettle();
        tester.view.physicalSize = const Size(320, 640);
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .onChanged!(8);
        await tester.pumpAndSettle();
        expect(find.text(reviewText('feedback', language)), findsOneWidget);
        expect(find.text(reviewText('sleepyAdvice', language)), findsOneWidget);
        final save = find.byKey(const ValueKey('alertness-save-result'));
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(592));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'PVT result stays open on failure, prevents double submit, and retries one timestamp',
    (tester) async {
      final bodies = <Map<String, dynamic>>[];
      final successfulReply = Completer<http.Response>();
      final client = MockClient((request) {
        bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        return bodies.length == 1
            ? Future.value(http.Response('unavailable', 503))
            : successfulReply.future;
      });
      await openTest(tester, pvtb: true, client: client);
      await waitForStimulus(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.tap(find.byKey(target));
      await tester.pump(const Duration(minutes: 3));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Your test summary'), findsOneWidget);
      tester
          .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
          .onChanged!(8);
      await tester.pump();
      expect(
        find.textContaining('Rest first and avoid driving'),
        findsOneWidget,
      );
      final save = find.byKey(const ValueKey('alertness-save-result'));
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(bodies.length, 1);
      await tester.tap(find.text('Discard result'));
      await tester.pumpAndSettle();
      expect(find.text('Discard this result?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 640);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(bodies.length, 2);
      expect(bodies[0]['test_at'], bodies[1]['test_at']);
      expect(bodies[0]['mean_rt'], greaterThanOrEqualTo(100));
      successfulReply.complete(http.Response('{"status":"success"}', 200));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Open test'), findsOneWidget);
    },
  );

  testWidgets('no valid response is not uploaded as a zero measurement', (
    tester,
  ) async {
    var submitted = false;
    await openTest(
      tester,
      pvtb: true,
      client: MockClient((request) async {
        submitted = true;
        return http.Response('{"status":"success"}', 200);
      }),
    );
    await tester.pump(const Duration(minutes: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('alertness-save-result')));
    await tester.pumpAndSettle();
    expect(submitted, isFalse);
    expect(find.text('Open test'), findsOneWidget);
  });
}
