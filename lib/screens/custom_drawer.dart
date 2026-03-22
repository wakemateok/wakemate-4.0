import 'package:flutter/material.dart';
import 'package:my_app/screens/LoginPage.dart';
import 'package:my_app/screens/alertness_test.dart';
import 'package:my_app/screens/personalSettingsPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/screens/LanguageSettingPage.dart';

class CustomDrawer extends StatelessWidget {
  final String userId;
  final String userName;
  final String userEmail;

  const CustomDrawer({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
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
      onTap: onTap,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 一次清掉全部登入資訊

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
    return Drawer(
      child: SafeArea(
        child: Container(
          color: _lightColor,
          child: Column(
            children: [
              // Header 區塊
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _primaryColor.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.4),
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
                            userName,
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

              // 中間內容：滾動列表
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: "個人身體數據",
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
                      title: "清醒度測試",
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
                      icon: Icons.language_outlined,
                      title: "語言設定",
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
                        vertical: 10.0,
                        horizontal: 20.0,
                      ),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: _primaryColor.withOpacity(0.15),
                      ),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.logout_rounded,
                      title: "登出",
                      isLogout: true,
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),

              // 底部版本資訊
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0, top: 10.0),
                child: Text(
                  'WakeMate v1.0.0 © 2024',
                  style: TextStyle(
                    color: _primaryColor.withOpacity(0.5),
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
