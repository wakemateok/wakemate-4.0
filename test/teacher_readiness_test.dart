import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/screens/custom_drawer.dart';
import 'package:my_app/screens/personalSettingsPage.dart';
import 'package:my_app/screens/CaffeineLogPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget localized(Widget page, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: page,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('settings loads without reading inherited widgets in initState', (
    tester,
  ) async {
    var gets = 0;
    final client = MockClient((request) async {
      gets++;
      return http.Response(
        jsonEncode([
          {
            'user_id': 'test-user',
            'gender': 'M',
            'age': 30,
            'height': 170,
            'weight': 65,
            'bmi': 22.49,
          },
        ]),
        200,
      );
    });
    await tester.pumpWidget(
      localized(SettingsPage(userId: 'test-user', client: client)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(gets, 1);
    expect(find.text('170'), findsOneWidget);
  });

  testWidgets('late settings response is ignored after leaving the page', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    await tester.pumpWidget(
      localized(
        SettingsPage(
          userId: 'test-user',
          client: MockClient((_) => response.future),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    response.complete(http.Response('[{"user_id":"test-user","age":30}]', 200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings failure keeps input and blocks duplicate submissions', (
    tester,
  ) async {
    final reply = Completer<http.Response>();
    final bodies = <Map<String, dynamic>>[];
    var posts = 0;
    await tester.pumpWidget(
      localized(
        SettingsPage(
          userId: 'test-user',
          client: MockClient((request) async {
            if (request.method == 'GET') return http.Response('[]', 200);
            posts++;
            bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
            return posts == 1 ? reply.future : http.Response('{}', 200);
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male'));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '30');
    await tester.enterText(fields.at(1), '170');
    await tester.enterText(fields.at(2), '65');
    final save = find.byType(ElevatedButton);
    await tester.ensureVisible(save);
    final submit = tester.widget<ElevatedButton>(save).onPressed!;
    submit();
    submit();
    await tester.pump();
    expect(posts, 1);
    expect(bodies.single['bmi'], 22.49);
    expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
    reply.complete(http.Response('unavailable', 503));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(fields.at(1)).controller!.text, '170');
    expect(tester.widget<TextFormField>(fields.at(2)).controller!.text, '65');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(posts, 2);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [
    const Locale('zh', 'TW'),
    const Locale('en'),
    const Locale('id'),
  ]) {
    testWidgets(
      '${locale.toLanguageTag()} settings fits a small phone with large text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder:
                (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.5),
                    padding: const EdgeInsets.only(bottom: 64),
                    viewPadding: const EdgeInsets.only(bottom: 64),
                  ),
                  child: child!,
                ),
            home: SettingsPage(
              userId: 'test-user',
              client: MockClient((_) async => http.Response('[]', 200)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final save = find.byType(ElevatedButton);
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(576));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('app flavor exposes only its intended alertness test', (
    tester,
  ) async {
    const mode = String.fromEnvironment(
      'WAKEMATE_ALERTNESS_MODE',
      defaultValue: 'combined',
    );
    await tester.pumpWidget(
      localized(
        const Scaffold(
          body: CustomDrawer(
            userId: 'test-user',
            userName: 'Test User',
            userEmail: 'test@example.com',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n =
        AppLocalizations.of(tester.element(find.byType(CustomDrawer)))!;
    expect(
      find.text(l10n.briefAlertnessTest),
      mode == 'pvtb' ? findsNothing : findsOneWidget,
    );
    expect(
      find.text(l10n.pvtbAlertnessTest),
      ['legacy', 'brief'].contains(mode) ? findsNothing : findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('caffeine save blocks rapid taps and keeps input after failure', (
    tester,
  ) async {
    final first = Completer<http.Response>();
    final bodies = <String>[];
    await tester.pumpWidget(
      localized(
        CaffeineLogPage(
          userId: 'test-user',
          selectedDate: DateTime(2026, 10, 20),
          client: MockClient((request) {
            bodies.add(request.body);
            return bodies.length == 1
                ? first.future
                : Future.value(http.Response('{}', 200));
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('caffeine-save'));
    await tester.ensureVisible(save);
    final submit = tester.widget<ElevatedButton>(save).onPressed!;
    submit();
    submit();
    await tester.pump();
    expect(bodies.length, 1);
    expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
    first.complete(http.Response('unavailable', 503));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(bodies.length, 2);
    expect(bodies[0], bodies[1]);
    expect(tester.takeException(), isNull);
  });
}
