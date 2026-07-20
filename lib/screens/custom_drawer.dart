import 'package:flutter/material.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/screens/LanguageSettingPage.dart';
import 'package:my_app/screens/LoginPage.dart';
import 'package:my_app/screens/alertness_test.dart';
import 'package:my_app/screens/notification_center_page.dart';
import 'package:my_app/screens/personalSettingsPage.dart';
import 'package:my_app/screens/questionnaire_prompt_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends StatelessWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final VoidCallback? onDailyQuestionnaireTap;
  final bool showDailyQuestionnaireBadge;

  const CustomDrawer({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.onDailyQuestionnaireTap,
    this.showDailyQuestionnaireBadge = false,
  });

  final Color _primaryColor = const Color(0xFF1F3D5B);
  final Color _accentColor = const Color(0xFF4DB6AC);
  final Color _lightColor = const Color(0xFFF7F9FC);

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
    bool showBadge = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.redAccent : _primaryColor,
        size: 26,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.redAccent : _primaryColor,
          fontSize: 16,
          fontWeight: isLogout ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing:
          showBadge
              ? Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              )
              : null,
      onTap: onTap,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenBaselineQuestionnaire =
        prefs.getBool(baselineQuestionnairePromptSeenKey) ?? false;

    await prefs.clear();
    if (hasSeenBaselineQuestionnaire) {
      await prefs.setBool(baselineQuestionnairePromptSeenKey, true);
    }

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName =
        userName.trim().isEmpty ? l10n.userFallback : userName.trim();

    return Drawer(
      child: SafeArea(
        child: Container(
          color: _lightColor,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor,
                      _primaryColor.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _accentColor,
                      radius: 32,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 8),
                    if (onDailyQuestionnaireTap != null)
                      _buildDrawerItem(
                        context,
                        icon: Icons.assignment_turned_in_outlined,
                        title: l10n.dailyQuestionnaire,
                        showBadge: showDailyQuestionnaireBadge,
                        onTap: () {
                          Navigator.pop(context);
                          onDailyQuestionnaireTap?.call();
                        },
                      ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: l10n.personalSettings,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsPage(userId: userId),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.bolt_outlined,
                      title: l10n.alertnessTest,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AlertnessTestPage(userId: userId),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.notifications_active_outlined,
                      title: l10n.notificationCenterTitle,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const NotificationCenterPage(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.language_outlined,
                      title: l10n.languageSettingsTitle,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LanguageSettingPage(),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: _primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.logout_rounded,
                      title: l10n.logout,
                      isLogout: true,
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 15, top: 10),
                child: Text(
                  'WakeMate v1.0.0',
                  style: TextStyle(
                    color: _primaryColor.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
