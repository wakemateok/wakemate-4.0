import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  /// 預設語言：繁體中文台灣
  Locale _locale = const Locale('zh', 'TW');

  Locale get locale => _locale;

  /// ✅ 新增 getter 給 UI 使用
  String get localeCode => localeToCode(_locale);

  LocaleProvider() {
    _loadLanguage(); // 建構子載入儲存的語言
  }

  /// 讀取 SharedPreferences
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String code = prefs.getString('appLanguage') ?? 'zh_TW';

    _locale = _codeToLocale(code);
    notifyListeners();
  }

  /// 設定語言
  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', languageCode);

    _locale = _codeToLocale(languageCode);
    notifyListeners();
  }

  /// 字串 → Locale
  Locale _codeToLocale(String code) {
    switch (code) {
      case 'en_US':
        return const Locale('en', 'US');
      case 'zh':
        return const Locale('zh'); // 中文（無地區）
      case 'id_ID':
        return const Locale('id', 'ID'); // 印尼
      case 'zh_TW':
      default:
        return const Locale('zh', 'TW');
    }
  }

  /// Locale → 字串（反向對應）
  String localeToCode(Locale locale) {
    final lang = locale.languageCode;
    final country = locale.countryCode;

    if (lang == 'en' && country == 'US') return 'en_US';
    if (lang == 'zh' && country == 'TW') return 'zh_TW';
    if (lang == 'zh' && (country == null || country!.isEmpty)) return 'zh';
    if (lang == 'id') return 'id_ID';

    // 預設回 zh_TW
    return 'zh_TW';
  }
}
