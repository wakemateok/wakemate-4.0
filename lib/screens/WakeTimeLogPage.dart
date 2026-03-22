import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Key 用於儲存多個目標清醒時間段 (本地)
const String _kTargetWakePeriodsKey = 'target_wake_periods_list_json';

// 用於儲存每個時間段的資料結構
class TimeSlot {
  final Key key = UniqueKey();
  TextEditingController startController;
  TextEditingController endController;

  TimeSlot({String? startTime, String? endTime})
    : startController = TextEditingController(text: startTime),
      endController = TextEditingController(text: endTime);

  // 轉換為本地儲存用的格式
  Map<String, String> toJson() => {
    'start': startController.text,
    'end': endController.text,
  };

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['start'] as String?,
      endTime: json['end'] as String?,
    );
  }
}

class TargetWakeTimePage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const TargetWakeTimePage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<TargetWakeTimePage> createState() => _TargetWakeTimePageState();
}

class _TargetWakeTimePageState extends State<TargetWakeTimePage> {
  // 🎨 顏色變數 (套用 HomePage 的風格)
  final Color _primaryColor = const Color(0xFF4B6B7A); // 深灰藍
  final Color _accentColor = const Color(0xFF8BB9A1); // 柔綠藍
  final Color _bgLight = const Color(0xFFF9F9F7); // 米白

  // API Base URL
  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';

  // 管理所有時間段的列表
  final List<TimeSlot> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPeriods();
  }

  // ============== 資料加載與儲存 (本地) ==============
  void _loadSavedPeriods() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_kTargetWakePeriodsKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        setState(() {
          _timeSlots.addAll(jsonList.map((j) => TimeSlot.fromJson(j)));
        });
      } catch (e) {
        // 如果載入失敗，會進入 _addTimeSlot()
      }
    }

    // 如果沒有任何儲存的時段，則新增一個預設時段
    if (_timeSlots.isEmpty) {
      _addTimeSlot();
    }
  }

  void _addTimeSlot() {
    final now = widget.selectedDate;
    final defaultStart = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime(now.year, now.month, now.day, 9, 0));
    final defaultEnd = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime(now.year, now.month, now.day, 10, 0));

    setState(() {
      _timeSlots.add(TimeSlot(startTime: defaultStart, endTime: defaultEnd));
    });
  }

  void _removeTimeSlot(Key key) {
    setState(() {
      _timeSlots.removeWhere((slot) => slot.key == key);
      if (_timeSlots.isEmpty) {
        _addTimeSlot(); // 確保至少有一個時段
      }
    });
  }

  // ============== API 提交邏輯 ==============
  /// 將 yyyy-MM-dd HH:mm 轉成 ISO8601 (UTC 格式)
  String _formatToISO8601(String time) {
    try {
      // 假設使用者輸入的是當地時間，我們將其視為 UTC 提交給 API
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(time, true);
      return dt.toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  Future<void> _saveData() async {
    if (_timeSlots.any(
      (slot) =>
          slot.startController.text.isEmpty || slot.endController.text.isEmpty,
    )) {
      _showSnackBar("請填寫所有時段的開始與結束時間。", color: Colors.red);
      return;
    }

    // 1. 驗證時間邏輯
    try {
      for (var slot in _timeSlots) {
        final dtStart = DateFormat(
          'yyyy-MM-dd HH:mm',
        ).parse(slot.startController.text);
        final dtEnd = DateFormat(
          'yyyy-MM-dd HH:mm',
        ).parse(slot.endController.text);

        if (dtEnd.isBefore(dtStart)) {
          _showSnackBar("錯誤：有時段的結束時間早於開始時間，請修正。", color: Colors.red);
          return;
        }
      }
    } catch (e) {
      _showSnackBar("時間格式錯誤，請重新選擇。", color: Colors.red);
      return;
    }

    final headers = {'Content-Type': 'application/json'};
    int successfulSubmissions = 0;

    try {
      // 針對每一個時段，執行一次 API 提交
      for (var slot in _timeSlots) {
        final payload = {
          'user_id': widget.userId,
          'target_start_time': _formatToISO8601(slot.startController.text),
          'target_end_time': _formatToISO8601(slot.endController.text),
        };

        final res = await http.post(
          Uri.parse('$baseUrl/users_wake/'),
          headers: headers,
          body: jsonEncode(payload),
        );

        if (res.statusCode == 200) {
          successfulSubmissions++;
        } else {
          // 提交失敗，顯示錯誤但繼續下一個時段
          _showSnackBar(
            "第 ${_timeSlots.indexOf(slot) + 1} 個時段提交失敗 (Status: ${res.statusCode})",
            color: Colors.orange,
          );
        }
      }

      // 2. 處理結果並更新本地緩存
      if (successfulSubmissions == _timeSlots.length) {
        // 全部成功：更新本地緩存
        final jsonList = _timeSlots.map((slot) => slot.toJson()).toList();
        final jsonString = json.encode(jsonList);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kTargetWakePeriodsKey, jsonString);

        _showSnackBar(
          "成功儲存 ${_timeSlots.length} 個目標清醒時段！",
          color: _accentColor, // ✅
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else if (successfulSubmissions > 0) {
        // 部分成功：僅更新本地緩存 (如果所有時段都通過本地驗證)
        _showSnackBar(
          "成功提交 $successfulSubmissions 個時段，有 ${(_timeSlots.length - successfulSubmissions)} 個提交失敗。",
          color: Colors.orange,
        );
      } else {
        // 全部失敗
        _showSnackBar("所有目標清醒時段提交失敗，請檢查網路或 API 狀態。", color: Colors.red);
      }
    } catch (e) {
      _showSnackBar("發生網路錯誤：$e");
    }
  }

  // ============== UI 輔助函數 ==============
  void _showSnackBar(String message, {Color color = Colors.red}) {
    // 保持您的 SnackBar 樣式
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

  // 建立單一時段的 UI
  Widget _buildTimeSlot(TimeSlot slot) {
    return Padding(
      key: slot.key,
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '目標清醒時段 #${_timeSlots.indexOf(slot) + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              if (_timeSlots.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _removeTimeSlot(slot.key),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ✅ 修正：從 Row 改為 Column，以適應小螢幕
          Column(
            children: [
              // 1. 開始時間
              TextField(
                controller: slot.startController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '開始時間',
                  hintText: '例如: 05:00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.access_time, color: _primaryColor),
                ),
                onTap: () => _pickDateTime(slot.startController),
              ),

              // ✅ 修正：加入垂直間距
              const SizedBox(height: 16),

              // 2. 結束時間
              TextField(
                controller: slot.endController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '結束時間',
                  hintText: '例如: 06:00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    Icons.access_time_filled,
                    color: _primaryColor,
                  ),
                ),
                onTap: () => _pickDateTime(slot.endController),
              ),
            ],
          ),
          const Divider(height: 25, color: Colors.grey),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: Text(
          '設定目標清醒時段',
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '請輸入您希望保持清醒或專注的特定時段。',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // 動態生成的時間段列表
            ..._timeSlots.map(_buildTimeSlot).toList(),

            // 新增時段按鈕
            OutlinedButton.icon(
              onPressed: _addTimeSlot,
              style: OutlinedButton.styleFrom(
                foregroundColor: _accentColor,
                side: BorderSide(color: _accentColor, width: 2),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                "新增時段框框",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 40),

            // 儲存按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveData, // 呼叫 API 提交邏輯
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                icon: const Icon(Icons.cloud_upload),
                label: const Text(
                  "儲存並提交目標清醒時段",
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
