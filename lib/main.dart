import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/utils/auth_text.dart';
import 'screens/change_password_page.dart';

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

  static const double _minimumBottomReservedSpace = 64;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder:
          (context, child) => Consumer<LocaleProvider>(
            builder: (context, provider, child) {
              return MaterialApp(
                key: ValueKey(AuthService.instance.generation),
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
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  final bottomReserve =
                      mediaQuery.viewInsets.bottom > 0
                          ? mediaQuery.padding.bottom
                          : math.max(
                            mediaQuery.padding.bottom,
                            _minimumBottomReservedSpace,
                          );

                  return MediaQuery(
                    data: mediaQuery.copyWith(
                      padding: mediaQuery.padding.copyWith(
                        bottom: bottomReserve,
                      ),
                      viewPadding: mediaQuery.viewPadding.copyWith(
                        bottom: math.max(
                          mediaQuery.viewPadding.bottom,
                          bottomReserve,
                        ),
                      ),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
                home: const QuestionnaireGate(child: AuthWrapper()),
              );
            },
          ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<void>? _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = AuthService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(authText('server_unavailable', l10n.localeName)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed:
                            () => setState(() {
                              _initialization = AuthService.instance.initialize(
                                retry: true,
                              );
                            }),
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        final auth = AuthService.instance;
        final userId = auth.userId;

        if (userId != null && userId.isNotEmpty) {
          if (auth.passwordChangeRequired) {
            return const ChangePasswordPage(requiredChange: true);
          }
          final savedName = auth.userName.trim();
          final userName = savedName.isNotEmpty ? savedName : l10n.userFallback;
          final userEmail = auth.email;
          return HomePage(userId: userId, userName: userName, email: userEmail);
        }

        return const LoginPage();
      },
    );
  }
}
