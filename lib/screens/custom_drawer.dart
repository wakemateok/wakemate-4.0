import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/screens/LanguageSettingPage.dart';
import 'package:my_app/screens/alertness_test.dart';
import 'package:my_app/screens/notification_center_page.dart';
import 'package:my_app/screens/personalSettingsPage.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/utils/auth_text.dart';
import 'package:my_app/screens/change_password_page.dart';

class CustomDrawer extends StatelessWidget {
  static const String _configuredMode = String.fromEnvironment(
    'WAKEMATE_ALERTNESS_MODE',
    defaultValue: '',
  );
  static String get _alertnessMode =>
      _configuredMode.isNotEmpty
          ? _configuredMode
          : appFlavor == 'legacy'
          ? 'brief'
          : appFlavor == 'pvtb'
          ? 'pvtb'
          : 'combined';

  final String userId;
  final String userName;
  final String userEmail;
  final VoidCallback? onDataChanged;
  final VoidCallback? onDailyQuestionnaireTap;
  final bool showDailyQuestionnaireBadge;

  const CustomDrawer({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.onDataChanged,
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
    try {
      await AuthService.instance.signOut();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authText(
                error is AuthException ? error.code : 'server_unavailable',
                Localizations.localeOf(context).languageCode,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName =
        userName.trim().isEmpty ? l10n.userFallback : userName.trim();
    final showBriefAlertness = _alertnessMode != 'pvtb';
    final showPvtbAlertness = !['brief', 'legacy'].contains(_alertnessMode);

    return Drawer(
      child: SafeArea(
        child: Material(
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
                        ).then((_) => onDataChanged?.call());
                      },
                    ),
                    if (showBriefAlertness)
                      _buildDrawerItem(
                        context,
                        icon: Icons.bolt_outlined,
                        title: l10n.briefAlertnessTest,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      AlertnessTestPage(userId: userId),
                            ),
                          ).then((_) => onDataChanged?.call());
                        },
                      ),
                    if (showPvtbAlertness)
                      _buildDrawerItem(
                        context,
                        icon: Icons.timer_outlined,
                        title: l10n.pvtbAlertnessTest,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      AlertnessTestPage.pvtb(userId: userId),
                            ),
                          ).then((_) => onDataChanged?.call());
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
                      icon: Icons.lock_reset,
                      title: authText(
                        'changePassword',
                        Localizations.localeOf(context).languageCode,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
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
                    'WakeMate v1.2.4',
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
