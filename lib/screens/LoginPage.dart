import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';
import 'RegisterPage.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ✂️ 移除 nameController
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';
  bool isLoading = false;

  // 🎨 色彩主題 (與您上次的優化設計一致)
  final Color _primaryColor = const Color(0xFF1F3D5B); // 主深藍色
  final Color _accentColor = const Color(0xFF4DB6AC); // 輔助色 - 青綠色
  final Color _backgroundColor = const Color(0xFFF0F2F5); // 淺灰色背景
  final Color _cardColor = Colors.white; // 卡片白色背景
  final Color _errorColor = const Color(0xFFE53935); // 紅色

  @override
  void dispose() {
    // ✂️ 移除 nameController.dispose()
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // **🎯 修改：將使用者資訊儲存到 SharedPreferences (不再儲存 Name)**
  Future<void> _saveLoginInfo(String userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    // 注意：由於登入不要求名稱，這裡不再儲存 userName
    // 如果您後續需要顯示名稱，可能需要從 API 回傳的 data 中取得。
    await prefs.setString('userEmail', email);
    await prefs.setBool('isLoggedIn', true);
  }

  Future<void> _loginUser() async {
    // ✂️ 移除 name 相關邏輯
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // 📌 檢查：現在只需檢查 Email 與密碼
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("請輸入 Email 與密碼")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final headers = {'Content-Type': 'application/json'};
      // **🎯 修改：API 請求 Body 僅包含 Email 和 Password**
      final body = jsonEncode({
        // "name": name, // 移除 name
        "email": email,
        "password": password,
      });

      final res = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: headers,
        body: body,
      );

      print('Response Status Code: ${res.statusCode}');
      print('Response Body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final String? uuidFromServer =
            data['user_id']?.toString() ?? data['id']?.toString();
        // 嘗試從回傳資料中獲取名稱 (如果後端有回傳的話)
        final String? nameFromServer = data['name']?.toString() ?? '用戶';

        if (uuidFromServer != null && uuidFromServer.isNotEmpty) {
          // **🎯 關鍵步驟：儲存登入資訊 (不含 Name)**
          await _saveLoginInfo(uuidFromServer, email);

          final now = DateFormat('HH:mm').format(DateTime.now());
          final snackBar = SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "登入成功！$now",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: _accentColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);

          // 導航到主頁面
          // ⚠️ 注意：HomePage 現在需要處理 nameFromServer 可能為 null/'用戶' 的情況
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => HomePage(
                    userId: uuidFromServer,
                    // 將從伺服器取得的名稱或預設值傳入
                    userName: nameFromServer ?? '用戶',
                    email: emailController.text.trim(),
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("登入成功，但無法取得使用者 ID")));
          print('Response Body: ${res.body}');
        }
      } else if (res.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("❌ 登入失敗：Email 或密碼不正確"), // 📌 更新提示文字
            backgroundColor: _errorColor,
          ),
        );
      } else {
        try {
          final errorMsg = jsonDecode(res.body)['error'] ?? "伺服器發生未知錯誤";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ 登入失敗：$errorMsg"),
              backgroundColor: _errorColor,
            ),
          );
        } on FormatException {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("❌ 登入失敗：伺服器回傳了無效的回應"),
              backgroundColor: _errorColor,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("錯誤：無法連線到伺服器"),
          backgroundColor: _errorColor,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "歡迎回來",
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor.withOpacity(0.1), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - (kToolbarHeight + 24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  color: _cardColor,
                  elevation: 10.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  shadowColor: _primaryColor.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "帳號登入",
                          style: TextStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.w900,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "請輸入您的 Email 與密碼", // 📌 更新提示文字
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ✂️ 移除 名稱輸入框

                        // --- Email 輸入框 ---
                        _buildTextField(
                          controller: emailController,
                          labelText: "Email",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        // --- 密碼輸入框 ---
                        _buildTextField(
                          controller: passwordController,
                          labelText: "密碼",
                          icon: Icons.lock_outline,
                          obscureText: true,
                        ),

                        const SizedBox(height: 40),

                        // --- 登入按鈕 ---
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _loginUser,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 8,
                              shadowColor: _primaryColor.withOpacity(0.5),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _primaryColor,
                                    _primaryColor.withOpacity(0.8),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                constraints: const BoxConstraints(
                                  minHeight: 55,
                                ),
                                child:
                                    isLoading
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                        : const Text(
                                          "登入",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- 註冊連結 ---
                        TextButton(
                          onPressed:
                              isLoading
                                  ? null
                                  : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const RegisterPage(),
                                      ),
                                    );
                                  },
                          style: TextButton.styleFrom(
                            foregroundColor: _accentColor,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("還沒有帳號？"),
                              Text(
                                "點此註冊",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  decorationColor: _accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 提取的 TextField 創建函數
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: _primaryColor.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(
            color: _primaryColor.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: _primaryColor, width: 2.0),
        ),
        prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.8)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 10.0,
        ),
      ),
    );
  }
}
