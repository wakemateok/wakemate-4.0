import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 導入 Provider 套件
import 'package:provider/provider.dart';
import 'package:my_app/providers/locale_provider.dart';
//導入 Flutter 自動產生的 l10n 檔案
import 'package:my_app/gen_l10n/app_localizations.dart';

import '/screens/LoginPage.dart';
import '/screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //執行 runApp，並在最頂層提供LocaleProvider
  runApp(
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(), // 建立 "大腦"
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //使用Consumer監聽Provider的變化
    return Consumer<LocaleProvider>(
      builder: (context, provider, child) {
        //provider 改變時，MaterialApp 會自動重建
        return MaterialApp(
          title: 'WakeMate',
          theme: ThemeData(
            primaryColor: const Color(0xFF1F3D5B),
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.blue,
            ).copyWith(secondary: const Color(0xFF5E91B3)),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),

          // --- 關鍵的語系設定 ---

          //locale 來自 Provider，不再是寫死的 'zh'
          locale: provider.locale,

          //使用 AppLocalizations 提供的 delegates 和 locales
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          // --- 設定結束 ---

          // 登入檢查
          home: const AuthWrapper(),
        );
      },
    );
  }
}

// ---------------------------
// 登入狀態檢查
// ---------------------------
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
    // (您的 _checkLoginStatus 邏輯保持不變)
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn && userId != null && userId.isNotEmpty) {
      return {
        'userId': userId,
        'userName': prefs.getString('userName'),
        'userEmail': prefs.getString('userEmail'),
      };
    } else {
      return {'userId': null};
    }
  }

  @override
  Widget build(BuildContext context) {
    // (您的 FutureBuilder 邏輯保持不變)
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
          final userName = snapshot.data?['userName'] ?? "";
          final userEmail = snapshot.data?['userEmail'] ?? "";
          return HomePage(userId: userId, userName: userName, email: userEmail);
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
