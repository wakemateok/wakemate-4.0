import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_app/config/app_brand.dart';
import 'package:my_app/config/app_release.dart';
import 'package:my_app/screens/LoginPage.dart';
import 'package:my_app/screens/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hospital_review_widget_test.dart' as qa;

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
        final loader = FontLoader(entry.key);
        loader.addFont(
          File(entry.value).readAsBytes().then(ByteData.sublistView),
        );
        await loader.load();
      }
    }
  });
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'home_guide_seen_owner': true}),
  );

  test('branding is scoped to PVT-B and release version matches pubspec', () {
    expect(AppBrand.enabled, AppRelease.protocol == 'pvtb');
    expect(
      File('pubspec.yaml').readAsLinesSync(),
      contains('version: ${AppRelease.label}'),
    );
    final gradle = File('android/app/build.gradle').readAsStringSync();
    expect(gradle, contains('applicationId "com.example.my_app"'));
    expect(gradle, contains('applicationIdSuffix ".pvtb"'));
    expect(gradle, isNot(contains('"app_name", "WakeMate PVT-B"')));
    expect(
      File('scripts/build_signed_apks.ps1').readAsStringSync(),
      contains("\$Flavors = @('pvtb')"),
    );
  });

  test(
    'all new native icon resources are PVT-B overrides with valid PNG sizes',
    () {
      const root = 'android/app/src/pvtb/res';
      for (final entry
          in {
            'mdpi': 1.0,
            'hdpi': 1.5,
            'xhdpi': 2.0,
            'xxhdpi': 3.0,
            'xxxhdpi': 4.0,
          }.entries) {
        for (final type in [
          'ic_launcher',
          'ic_launcher_foreground',
          'ic_launcher_monochrome',
        ]) {
          final bytes =
              File('$root/mipmap-${entry.key}/$type.png').readAsBytesSync();
          expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
          final header = ByteData.sublistView(bytes);
          final size =
              ((type == 'ic_launcher' ? 48 : 108) * entry.value).round();
          expect(header.getUint32(16), size);
          expect(header.getUint32(20), size);
          expect(bytes[25], 6);
        }
      }
      expect(
        File('$root/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync(),
        contains('ic_launcher_foreground'),
      );
      expect(
        File('$root/mipmap-anydpi-v33/ic_launcher.xml').readAsStringSync(),
        contains('ic_launcher_monochrome'),
      );
      expect(File(AppBrand.symbolAsset).lengthSync(), greaterThan(1000));
      expect(File(AppBrand.logoAsset).lengthSync(), greaterThan(1000));
    },
  );

  for (final language in ['zh', 'en', 'id']) {
    testWidgets(
      '$language branding fits the small home toolbar without moving actions',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          qa.app(
            HomePage(
              userId: 'owner',
              repository: qa.FixtureHomeRepository(qa.fixture()),
              showQuestionnaireReminder: false,
            ),
            Locale(language),
          ),
        );
        await tester.pumpAndSettle();
        final logo = find.byKey(const ValueKey('home-logo'));
        expect(logo, AppBrand.enabled ? findsOneWidget : findsNothing);
        final title = find.byKey(const ValueKey('home-brand'));
        final feedback = find.byKey(const ValueKey('home-feedback'));
        expect(
          tester.getBottomRight(title).dx,
          lessThanOrEqualTo(tester.getTopLeft(feedback).dx),
        );
        if (AppBrand.enabled) {
          await tester.runAsync(
            () => precacheImage(
              const AssetImage(AppBrand.symbolAsset),
              tester.element(logo),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester
                .renderObject<RenderImage>(
                  find.descendant(of: logo, matching: find.byType(RawImage)),
                )
                .image,
            isNotNull,
          );
          expect(
            tester.widget<Text>(title).style!.color,
            AppBrand.wordmarkColor,
          );
          expect(
            (tester.widget<Image>(logo).image as AssetImage).assetName,
            AppBrand.symbolAsset,
          );
        }
        await qa.screenshot(
          tester,
          'brand-${AppRelease.protocol}-home-$language-20261027',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$language login brand remains scrollable above a phone keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpWidget(qa.app(const LoginPage(), Locale(language)));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('login-logo')),
          AppBrand.enabled ? findsOneWidget : findsNothing,
        );
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(AppBrand.logoAsset),
            tester.element(find.byKey(const ValueKey('login-logo'))),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .renderObject<RenderImage>(
                find.descendant(
                  of: find.byKey(const ValueKey('login-logo')),
                  matching: find.byType(RawImage),
                ),
              )
              .image,
          isNotNull,
        );
        await qa.screenshot(
          tester,
          'brand-${AppRelease.protocol}-login-$language-20261027',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        await tester.pumpAndSettle();
        final email = find.byType(TextField).first;
        await tester.ensureVisible(email);
        await tester.pumpAndSettle();
        await tester.enterText(email, 'brand-test@example.com');
        final submit = find.byType(ElevatedButton).first;
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        expect(submit.hitTestable(), findsOneWidget);
        expect(tester.getBottomRight(submit).dy, lessThanOrEqualTo(352));
        expect(tester.takeException(), isNull);
      },
      skip: !AppBrand.enabled,
    );
  }
}
