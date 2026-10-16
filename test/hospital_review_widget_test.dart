import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_app/api/home_data.dart';
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/data/drink_matches.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/screens/CaffeineLogPage.dart';
import 'package:my_app/screens/drink_match_page.dart';
import 'package:my_app/screens/home_page.dart';
import 'package:my_app/utils/review_text.dart';
import 'package:my_app/widgets/taipei_datetime_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FixtureHomeRepository extends HomeRepository {
  FixtureHomeRepository(this.snapshot);
  final HomeSnapshot snapshot;
  int loads = 0;
  bool lastRecalculate = false;
  @override
  Future<HomeSnapshot> load(String userId, {bool recalculate = false}) async {
    loads++;
    lastRecalculate = recalculate;
    return snapshot;
  }
}

HomeSnapshot fixture() {
  final today = taipeiDateOnly(taipeiNow());
  return HomeSnapshot(
    sleeps: [
      {
        'sleep_start_time': taipeiInputToUtcIso('${dayKey(today)} 00:00'),
        'sleep_end_time': taipeiInputToUtcIso('${dayKey(today)} 08:00'),
      },
    ],
    wakes: [
      {'is_active': true},
    ],
    intakes: [
      {
        'taking_timestamp': taipeiInputToUtcIso('${dayKey(today)} 09:00'),
        'caffeine_amount': 125,
      },
    ],
    hasProfile: true,
    hasTest: true,
    recommendations: [
      {
        'recommended_caffeine_intake_timing': taipeiInputToUtcIso(
          '${dayKey(today)} 18:00',
        ),
        'recommended_caffeine_amount': 75,
      },
    ],
  );
}

Widget app(Widget page, Locale locale, {double scale = 1.5}) => MaterialApp(
  theme: ThemeData(
    primaryColor: const Color(0xFF1F3D5B),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
    ).copyWith(secondary: const Color(0xFF5E91B3)),
    fontFamily:
        const bool.fromEnvironment('WAKEMATE_CAPTURE_QA') ? 'ReviewQA' : null,
  ),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder:
      (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(bottom: 48),
          viewPadding: const EdgeInsets.only(bottom: 48),
        ),
        child: RepaintBoundary(
          key: const ValueKey('qa-boundary'),
          child: child!,
        ),
      ),
  home: page,
);

Future<void> screenshot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('WAKEMATE_CAPTURE_QA')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('qa-boundary')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory(
      'C:/Users/tec05/.codex/tmp/wakemate-hospital-review-20261016/qa',
    );
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    if (const bool.fromEnvironment('WAKEMATE_CAPTURE_QA')) {
      final loader = FontLoader('ReviewQA');
      loader.addFont(
        File(
          'C:/Windows/Fonts/msjh.ttc',
        ).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        File(
          'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
      await icons.load();
      final cupertino = FontLoader('CupertinoSystemDisplay');
      cupertino.addFont(
        File(
          'C:/Windows/Fonts/msjh.ttc',
        ).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
      await cupertino.load();
    }
  });
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'home_guide_seen_owner': true}),
  );
  void size(WidgetTester tester, double width) {
    tester.view.physicalSize = Size(width, width == 320 ? 640 : 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final language in ['zh', 'en', 'id']) {
    for (final width in [320.0, 390.0]) {
      testWidgets(
        '$language ${width.toInt()}px home has calendar totals, inline results and date-driven entry without overflow',
        (tester) async {
          size(tester, width);
          final repo = FixtureHomeRepository(fixture());
          await tester.pumpWidget(
            app(
              HomePage(
                userId: 'owner',
                repository: repo,
                showQuestionnaireReminder: false,
              ),
              Locale(language),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await screenshot(tester, 'home-$language-${width.toInt()}');
          final result = find.text('18:00 · 75 mg');
          await tester.ensureVisible(result);
          await tester.pumpAndSettle();
          expect(result, findsOneWidget);
          expect(tester.takeException(), isNull);
          await screenshot(
            tester,
            'recommendations-$language-${width.toInt()}',
          );
          final selectedDay = taipeiDateOnly(
            taipeiNow(),
          ).subtract(const Duration(days: 1));
          await tester.drag(find.byType(ListView).first, const Offset(0, 900));
          await tester.pumpAndSettle();
          final day = find.text('${selectedDay.day}').first;
          await tester.ensureVisible(day);
          await tester.tap(day);
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsOneWidget);
          final l10n =
              AppLocalizations.of(tester.element(find.byType(HomePage)))!;
          await tester.tap(find.text(l10n.addCaffeineRecord));
          await tester.pumpAndSettle();
          final log = tester.widget<CaffeineLogPage>(
            find.byType(CaffeineLogPage),
          );
          expect(dayKey(log.selectedDate), dayKey(selectedDay));
          expect(tester.takeException(), isNull);
          Navigator.of(tester.element(find.byType(CaffeineLogPage))).pop();
          await tester.pumpAndSettle();
          expect(repo.loads, 2);
          expect(repo.lastRecalculate, isFalse);
          expect(find.text('18:00 · 75 mg'), findsNothing);
        },
      );
    }

    testWidgets(
      '$language welcome tasks track completion and stay dismissible',
      (tester) async {
        size(tester, 320);
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(
          app(
            HomePage(
              userId: 'owner',
              repository: FixtureHomeRepository(fixture()),
              showQuestionnaireReminder: false,
            ),
            Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(reviewText('firstSteps', language)), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.text(reviewText('firstSteps', language)), findsNothing);
        expect(
          (await SharedPreferences.getInstance()).getBool(
            'home_guide_seen_owner',
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$language 24-hour wheel preserves date and time and respects safe area',
      (tester) async {
        size(tester, 320);
        DateTime? result;
        await tester.pumpWidget(
          app(
            Builder(
              builder:
                  (context) => Scaffold(
                    body: TextButton(
                      onPressed:
                          () async =>
                              result = await showTaipeiDateTimePicker(
                                context,
                                initial: DateTime(2026, 10, 20, 23, 45),
                              ),
                      child: const Text('Open'),
                    ),
                  ),
            ),
            Locale(language),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
              .use24hFormat,
          isTrue,
        );
        tester
            .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
            .onDateTimeChanged(DateTime(2026, 10, 20, 22, 35));
        await tester.pump();
        await tester.tap(find.text(reviewText('date', language)));
        await tester.pumpAndSettle();
        await tester.drag(
          find.text(language == 'zh' ? '20日' : '20'),
          const Offset(0, -32),
          touchSlopY: 0,
        );
        await tester.pumpAndSettle();
        expect(find.text('2026/10/21 22:35'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await screenshot(tester, 'picker-$language-320');
        final done = find.byKey(const ValueKey('picker-done'));
        await tester.ensureVisible(done);
        await tester.pumpAndSettle();
        expect(tester.getBottomRight(done).dy, lessThanOrEqualTo(592));
        await tester.tap(done);
        await tester.pumpAndSettle();
        expect(result, DateTime(2026, 10, 21, 22, 35));
      },
    );

    testWidgets(
      '$language drink conversion opens a partial intake without saving automatically',
      (tester) async {
        size(tester, 320);
        final match = matchDrinks(75).first;
        await tester.pumpWidget(
          app(
            DrinkMatchPage(
              userId: 'owner',
              targetMg: 75,
              recommendedAt: DateTime(2026, 10, 20, 18, 30),
            ),
            Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await screenshot(tester, 'drinks-$language-320');
        final log = find.byKey(ValueKey('drink-log-${match.item.id}'));
        await tester.scrollUntilVisible(log, 150, maxScrolls: 30);
        await tester.pumpAndSettle();
        await tester.tap(log);
        await tester.pumpAndSettle();
        final page = tester.widget<CaffeineLogPage>(
          find.byType(CaffeineLogPage),
        );
        expect(page.initialCatalogId, match.item.id);
        expect(page.initialPortion, match.fraction);
        expect(page.initialTimestamp, DateTime(2026, 10, 20, 18, 30));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'partial cup amount is submitted only after explicit save, with editable Taipei timestamp',
    (tester) async {
      size(tester, 390);
      final bodies = <Map<String, dynamic>>[];
      final match = matchDrinks(75).first;
      await tester.pumpWidget(
        app(
          CaffeineLogPage(
            userId: 'owner',
            selectedDate: DateTime(2026, 10, 20),
            initialCatalogId: match.item.id,
            initialPortion: match.fraction,
            initialTimestamp: DateTime(2026, 10, 20, 18, 30),
            client: MockClient((request) async {
              bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
              return http.Response('unavailable', 503);
            }),
          ),
          const Locale('en'),
          scale: 1,
        ),
      );
      await tester.pumpAndSettle();
      expect(bodies, isEmpty);
      expect(
        tester
            .widget<DropdownButtonFormField<double>>(
              find.byKey(const ValueKey('catalog-portion')),
            )
            .initialValue,
        match.fraction,
      );
      final save = find.byKey(const ValueKey('caffeine-save'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(bodies, hasLength(1));
      expect(bodies.single['caffeine_amount'], match.caffeineMg);
      expect(bodies.single['taking_timestamp'], '2026-10-20T10:30:00.000Z');
      expect(tester.takeException(), isNull);
    },
  );
}
