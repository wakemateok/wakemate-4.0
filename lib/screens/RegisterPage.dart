import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'LoginPage.dart';

// RegisterPage 是一個 StatefulWidget，允許它管理自己的狀態
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

// _RegisterPageState 類別用於保存 RegisterPage 的可變狀態
class _RegisterPageState extends State<RegisterPage> {
  // TextEditingController 用來管理文字輸入框的內容
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // API 的基本網址
  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';

  // 一個布林值，用來追蹤非同步操作是否正在進行
  bool isLoading = false;

  // 定義顏色和樣式
  final Color _primaryColor = const Color(0xFF1F3D5B); // 深藍色
  final Color _accentColor = const Color(0xFF5E91B3); // 淺藍色
  final Color _backgroundColor = const Color(0xFFF0F2F5); // 淺灰色背景
  final Color _cardColor = Colors.white; // 卡片白色背景
  final Color _textColor = const Color(0xFF424242); // 深灰色文字

  // 這個非同步函數處理使用者註冊流程
  Future<void> _registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // 在發送請求前，先進行客戶端的基本驗證
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("請輸入所有欄位")));
      return;
    }

    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegExp.hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Email 格式不正確！")));
      return;
    }

    // 設定 loading 狀態為 true，以禁用按鈕並提供使用者回饋
    setState(() => isLoading = true);

    try {
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        "email": email,
        "password": password,
        "name": name,
        "created_at": DateTime.now().toIso8601String(),
      });

      final res = await http.post(
        Uri.parse('$baseUrl/users/'), // 註冊的 API 路徑
        headers: headers,
        body: body,
      );

      // 檢查 Widget 是否仍然在畫面上，以避免在銷毀後操作 context
      if (!mounted) return;

      // 根據伺服器回傳的狀態碼處理回應
      if (res.statusCode == 200 || res.statusCode == 201) {
        // 註冊成功
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("註冊成功！請登入")));
        Navigator.pop(context); // 返回上一頁（登入頁面）
      } else if (res.statusCode == 409) {
        // 處理衝突錯誤，例如 Email 已被註冊
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("❌ 註冊失敗：此 Email 已被註冊")));
      } else {
        // 處理所有其他伺服器端錯誤
        try {
          final errorMsg = jsonDecode(res.body)['error'] ?? "發生未知錯誤";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("❌ 註冊失敗：$errorMsg")));
        } on FormatException {
          // 如果伺服器回應不是有效的 JSON 格式
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("❌ 註冊失敗：伺服器回傳了無效的回應")));
        }
      }
    } catch (e) {
      // 捕捉網路連線等例外
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("錯誤：無法連線到伺服器")));
    } finally {
      // 無論成功或失敗，最後都將 loading 狀態設回 false
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "註冊新帳號",
          style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      body: Center(
        child: SingleChildScrollView(
          // 使用 SingleChildScrollView 避免鍵盤彈出時溢位
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 12.0, // 增加陰影效果
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0), // 設定圓角
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 讓 Column 佔用最小空間
                children: [
                  Text(
                    "創建新帳號",
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "名稱",
                      labelStyle: TextStyle(color: _textColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _accentColor, width: 2),
                      ),
                      prefixIcon: Icon(Icons.person, color: _primaryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: _textColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _accentColor, width: 2),
                      ),
                      prefixIcon: Icon(Icons.email, color: _primaryColor),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: "密碼",
                      labelStyle: TextStyle(color: _textColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _accentColor, width: 2),
                      ),
                      prefixIcon: Icon(Icons.lock, color: _primaryColor),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 5,
                      ),
                      child:
                          isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                              : const Text(
                                "註冊",
                                style: TextStyle(fontSize: 18),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
