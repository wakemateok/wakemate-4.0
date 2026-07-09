import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/main.dart';
import 'package:my_app/screens/LoginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows login page when there is no saved session', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AuthWrapper(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
