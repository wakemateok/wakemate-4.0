import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
// ✅ 修正 #1：導入 SharedPreferences (移除註解)
import 'package:shared_preferences/shared_preferences.dart';

class ActualSleepTimePage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const ActualSleepTimePage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<ActualSleepTimePage> createState() => _ActualSleepTimePageState();
}

class _ActualSleepTimePageState extends State<ActualSleepTimePage> {
  // 控制器
  final TextEditingController sleepStartController = TextEditingController();
  final TextEditingController sleepEndController = TextEditingController();

  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';

  // 🎨 顏色變數 (套用 HomePage 的風格)
  final Color _primaryColor = const Color(0xFF4B6B7A); // 深灰藍
  final Color _accentColor = const Color(0xFF8BB9A1); // 柔綠藍
  final Color _bgLight = const Color(0xFFF9F9F7); // 米白

  @override
  void initState() {
    super.initState();
    _loadInitialTimes();
  }

  void _loadInitialTimes() {
    final now = widget.selectedDate;

    // 預設「開始睡覺時間」為前一晚的 23:00
    sleepStartController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime(now.year, now.month, now.day - 1, 23, 0));

    // 預設「結束睡眠時間」為今天的 07:00
    sleepEndController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime(now.year, now.month, now.day, 7, 0));
  }

  @override
  void dispose() {
    sleepStartController.dispose();
    sleepEndController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    // (您的 SnackBar 程式碼保持不變)
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontWeight: FontWeight.bold),
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
      // 假設使用者輸入的是當地時間，我們將其轉為 UTC 提交給 API
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(time, true);
      return dt.toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  Future<void> _submitData() async {
    final uuid = widget.userId;
    final sleepStartTimeText = sleepStartController.text.trim();
    final sleepEndTimeText = sleepEndController.text.trim();

    if (sleepStartTimeText.isEmpty || sleepEndTimeText.isEmpty) {
      _showSnackBar("請選擇睡眠的開始時間與結束時間。");
      return;
    }

    // 驗證時間順序
    late DateTime dtStart, dtEnd;
    try {
      dtStart = DateFormat('yyyy-MM-dd HH:mm').parse(sleepStartTimeText);
      dtEnd = DateFormat('yyyy-MM-dd HH:mm').parse(sleepEndTimeText);
      if (dtEnd.isBefore(dtStart)) {
        _showSnackBar("結束時間不能早於開始時間，請檢查日期和時間。", color: Colors.red);
        return;
      }
      if (dtEnd.difference(dtStart).inDays > 2) {
        _showSnackBar("睡眠時間過長 (超過48小時)，請確認。", color: Colors.red);
        return;
      }
    } catch (e) {
      _showSnackBar("時間格式錯誤，請重新選擇。", color: Colors.red);
      return;
    }

    // 轉換為 ISO8601
    final sleepStartTimeISO = formatToISO8601(sleepStartTimeText);
    final sleepEndTimeISO = formatToISO8601(sleepEndTimeText);

    final headers = {'Content-Type': 'application/json'};

    try {
      final sleepRes = await http.post(
        Uri.parse('$baseUrl/users_sleep/'),
        headers: headers,
        body: jsonEncode({
          'user_id': uuid,
          'sleep_start_time': sleepStartTimeISO,
          'sleep_end_time': sleepEndTimeISO,
        }),
      );

      if (sleepRes.statusCode == 200) {
        // ✅ 修正 #2：呼叫新的成功處理函數
        await _handleSuccessfulSave(dtStart, dtEnd);

        if (mounted) {
          // 提交成功後關閉頁面
          Navigator.of(context).pop();
        }
      } else {
        String sleepBody = sleepRes.body.isNotEmpty ? sleepRes.body : "無回應內容";
        _showSnackBar("睡眠紀錄儲存失敗：${sleepRes.statusCode}\n回應：$sleepBody");
      }
    } catch (e) {
      _showSnackBar("發生錯誤：$e");
    }
  }

  // ✅ 修正 #3：新函數，取代 _calculateAndShowSleepDuration
  // 負責計算、儲存到 SharedPreferences，並顯示 SnackBar
  Future<void> _handleSuccessfulSave(DateTime dtStart, DateTime dtEnd) async {
    try {
      final duration = dtEnd.difference(dtStart);

      // 1. 計算總小時 (double)
      final double totalHours = duration.inMinutes / 60.0;

      // 2. 準備 SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // 3. 產生 Key (以"結束日期"為準，這與 HomePage 邏輯一致)
      final String dateKey = DateFormat('yyyy-MM-dd').format(dtEnd);
      final String prefsKey = 'sleep_$dateKey';

      // 4. 儲存總時數
      // 附註：睡眠通常是覆蓋，而不是累加
      await prefs.setDouble(prefsKey, totalHours);
      print('[$prefsKey] 儲存成功：$totalHours 小時'); // 除錯用

      // 5. 顯示成功訊息 (原本的邏輯)
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      _showSnackBar(
        "睡眠紀錄儲存成功！\n😴 總時長：${hours}小時 ${minutes}分鐘",
        color: _accentColor, // ⭐️ 使用風格顏色
      );
    } catch (e) {
      _showSnackBar("資料格式錯誤，無法計算或儲存時長。", color: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 套用 HomePage 的風格
    return Scaffold(
      backgroundColor: _bgLight, // ⭐️
      appBar: AppBar(
        title: Text(
          '新增實際睡眠時間',
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
          ), // ⭐️
        ),
        backgroundColor: Colors.white.withOpacity(0.9), // ⭐️
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(color: _primaryColor), // ⭐️
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '請輸入您實際開始睡覺的時間與結束睡眠的時間，以記錄完整的睡眠週期。',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // 1. 開始睡覺時間
            TextField(
              controller: sleepStartController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: '開始睡覺時間（點擊選擇）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.bedtime_outlined,
                  color: _primaryColor,
                ), // ⭐️
                hintText: '例如：2025-11-05 23:00',
              ),
              onTap: () => _pickDateTime(sleepStartController),
            ),

            const SizedBox(height: 16),

            // 2. 結束睡眠時間
            TextField(
              controller: sleepEndController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: '結束睡眠時間（點擊選擇）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.access_time_rounded, // ⭐️
                  color: _primaryColor,
                ),
                hintText: '例如：2025-11-06 07:00',
              ),
              onTap: () => _pickDateTime(sleepEndController),
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
                  "儲存睡眠週期",
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
