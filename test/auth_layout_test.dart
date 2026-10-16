import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/screens/change_password_page.dart';

void main() {
  for (final language in ['zh', 'en', 'id']) {
    testWidgets('$language password change fits a small phone and keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.6),
                  viewInsets: const EdgeInsets.only(bottom: 240),
                  padding: const EdgeInsets.only(bottom: 64),
                ),
                child: child!,
              ),
          home: const ChangePasswordPage(requiredChange: true),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.byType(BackButton), findsNothing);
    });
  }
}
