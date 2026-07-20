import 'package:flutter/material.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/providers/locale_provider.dart';
import 'package:provider/provider.dart';

class LanguageSettingPage extends StatelessWidget {
  const LanguageSettingPage({super.key});

  final Color _primaryColor = const Color(0xFF1F3D5B);
  final Color _accentColor = const Color(0xFF4DB6AC);
  final Color _lightColor = const Color(0xFFF7F9FC);

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;
    final selectedLanguage = localeProvider.localeCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.languageSettingsTitle,
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      backgroundColor: _lightColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.selectYourLanguage,
            style: TextStyle(
              color: _primaryColor.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                _buildLanguageTile(
                  context,
                  '繁體中文（台灣）',
                  'zh_TW',
                  selectedLanguage,
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _buildLanguageTile(
                  context,
                  'Bahasa Indonesia',
                  'id_ID',
                  selectedLanguage,
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _buildLanguageTile(
                  context,
                  'English (US)',
                  'en_US',
                  selectedLanguage,
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _buildLanguageTile(context, '简体中文', 'zh', selectedLanguage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String title,
    String languageCode,
    String selectedLanguage,
  ) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600),
      ),
      value: languageCode,
      groupValue: selectedLanguage,
      onChanged: (String? value) {
        if (value != null && value != selectedLanguage) {
          context.read<LocaleProvider>().setLocale(value);
        }
      },
      activeColor: _accentColor,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
