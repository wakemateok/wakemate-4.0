import 'package:flutter/material.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/LoginPage.dart';
import 'screens/home_page.dart';
import 'screens/questionnaire_prompt_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'WakeMate',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color(0xFF1F3D5B),
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.blue,
            ).copyWith(secondary: const Color(0xFF5E91B3)),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          locale: provider.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const QuestionnaireGate(child: AuthWrapper()),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<Map<String, String?>>? _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _checkLoginStatus();
  }

  Future<Map<String, String?>> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn && userId != null && userId.isNotEmpty) {
      return {
        'userId': userId,
        'userName': prefs.getString('userName'),
        'userEmail': prefs.getString('userEmail'),
      };
    }

    return {'userId': null};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, String?>>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userId = snapshot.data?['userId'];

        if (userId != null && userId.isNotEmpty) {
          final savedName = snapshot.data?['userName']?.trim() ?? "";
          final userName = savedName.isNotEmpty ? savedName : l10n.userFallback;
          final userEmail = snapshot.data?['userEmail'] ?? "";
          return HomePage(userId: userId, userName: userName, email: userEmail);
        }

        return const LoginPage();
      },
    );
  }
}
