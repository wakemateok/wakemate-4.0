import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
// ✅ 修正 #1：導入 SharedPreferences
import 'package:shared_preferences/shared_preferences.dart';

class CaffeineLogPage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const CaffeineLogPage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<CaffeineLogPage> createState() => _CaffeineLogPageState();
}

class _CaffeineLogPageState extends State<CaffeineLogPage> {
  final TextEditingController caffeineController = TextEditingController();
  final TextEditingController drinkNameController = TextEditingController(
    text: "咖啡",
  );
  final TextEditingController takingTimeController = TextEditingController();

  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';

  @override
  void initState() {
    super.initState();
    // 預設飲用時間
    // ⭐️ 邏輯調整：預設時間應該是來自 HomePage 選擇的日期，而不是 DateTime.now()
    // 這樣使用者在 11/6 新增時，時間才會預設為 11/6
    final initialTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      DateTime.now().hour, // 使用當前小時
      DateTime.now().minute, // 使用當前分鐘
    );
    takingTimeController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(initialTime);
  }

  @override
  void dispose() {
    caffeineController.dispose();
    drinkNameController.dispose();
    takingTimeController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    // (您的 SnackBar 程式碼保持不變)
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            color == Colors.green
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// 彈出日期+時間選擇器
  Future<void> _pickDateTime(TextEditingController controller) async {
    // (您的 _pickDateTime 程式碼保持不變)
    DateTime initialDateTime;
    try {
      initialDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(controller.text);
    } catch (e) {
      initialDateTime = DateTime.now();
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );
    if (pickedTime == null) return;

    DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    controller.text = DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);
  }

  /// 將 yyyy-MM-dd HH:mm 轉成 ISO8601
  String formatToISO8601(String time) {
    // (您的 formatToISO8601 程式碼保持不變)
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(time);
      return dt.toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  /// 🔑 關鍵：儲存到 SharedPreferences 的函數
  Future<void> _saveToLocal(
    double caffeineAmount,
    String takingTimeString,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. 取得飲用時間 'yyyy-MM-dd HH:mm'
      final DateTime takingDateTime = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).parse(takingTimeString);

      // 2. 轉換成 HomePage 使用的 Key 格式 'yyyy-MM-dd'
      final String dateKey = DateFormat('yyyy-MM-dd').format(takingDateTime);

      // 3. 產生與 HomePage 一致的 Key 名稱
      final String prefsKey = 'caffeine_$dateKey';

      // 4. 取得舊資料並累加
      double currentTotal = prefs.getDouble(prefsKey) ?? 0;
      double newTotal = currentTotal + caffeineAmount;

      // 5. 儲存新總數
      await prefs.setDouble(prefsKey, newTotal);
      print('[$prefsKey] 儲存成功：$newTotal mg'); // 方便您在主控台除錯
    } catch (e) {
      print('儲存到 SharedPreferences 失敗：$e');
      // 即使本機儲存失敗，也不要阻擋 API 流程，所以只印出錯誤
    }
  }

  Future<void> _submitData() async {
    final uuid = widget.userId;
    final caffeine = caffeineController.text.trim();
    final drinkName = drinkNameController.text.trim();
    final takingTime = takingTimeController.text.trim();

    if (caffeine.isEmpty || drinkName.isEmpty || takingTime.isEmpty) {
      _showSnackBar("請填寫所有欄位");
      return;
    }

    final int? caffeineAmount = int.tryParse(caffeine); // 保持 int
    if (caffeineAmount == null || caffeineAmount <= 0) {
      _showSnackBar("咖啡因含量必須是有效的正整數。");
      return;
    }

    final headers = {'Content-Type': 'application/json'};

    try {
      final intakeRes = await http.post(
        Uri.parse('$baseUrl/users_intake/'),
        headers: headers,
        body: jsonEncode({
          'user_id': uuid,
          'caffeine_amount': caffeineAmount,
          'drink_name': drinkName,
          'taking_timestamp': formatToISO8601(takingTime),
        }),
      );

      if (intakeRes.statusCode == 200) {
        // ✅ 修正 #2：在 API 成功後，呼叫本機儲存
        await _saveToLocal(caffeineAmount.toDouble(), takingTime);

        _showSnackBar(
          "咖啡因攝取記錄儲存成功！",
          // ⭐️ 樣式：使用您在 HomePage 定義的輔助色
          color: const Color(0xFF8BB9A1), // 柔綠藍
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        String intakeBody =
            intakeRes.body.isNotEmpty ? intakeRes.body : "無回應內容";
        _showSnackBar("咖啡因記錄儲存失敗：${intakeRes.statusCode}\n回應：$intakeBody");
      }
    } catch (e) {
      _showSnackBar("發生錯誤：$e");
    }
  }

  @override
  Widget build(BuildContext buildContext) {
    // ⭐️ 樣式：套用您在 HomePage 定義的顏色
    final Color _primaryColor = const Color(0xFF4B6B7A);
    final Color _accentColor = const Color(0xFF8BB9A1);
    final Color _bgLight = const Color(0xFFF9F9F7);

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: Text(
          '新增咖啡因紀錄',
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withOpacity(0.9), //
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(color: _primaryColor), //
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '記錄您攝取的咖啡因，以便 WakeMate 為您提供個人化的咖啡因建議。',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: caffeineController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "咖啡因含量 (毫克)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: "例如：150",
                prefixIcon: Icon(
                  Icons.local_cafe_outlined, // ⭐️
                  color: _primaryColor, // ⭐️
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: drinkNameController,
              decoration: InputDecoration(
                labelText: '飲料名稱',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '例如 拿鐵',
                prefixIcon: Icon(
                  Icons.local_drink_outlined, // ⭐️
                  color: _primaryColor, // ⭐️
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: takingTimeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: '飲用時間（點擊選擇）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.access_time_rounded, // ⭐️
                  color: _primaryColor, // ⭐️
                ),
              ),
              onTap: () => _pickDateTime(takingTimeController),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor, // ⭐️
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  "儲存咖啡因記錄",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
