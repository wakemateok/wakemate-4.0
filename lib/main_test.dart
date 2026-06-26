import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caffeine Recommendation',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CaffeineRecommendationPage(),
    );
  }
}

class CaffeineRecommendationPage extends StatefulWidget {
  const CaffeineRecommendationPage({super.key});

  @override
  State<CaffeineRecommendationPage> createState() =>
      _CaffeineRecommendationPageState();
}

class _CaffeineRecommendationPageState
    extends State<CaffeineRecommendationPage> {
  String responseText = "尚未發送請求，請選擇時間後點擊按鈕。";
  final _userIdController = TextEditingController(
    text: '550e8400-e29b-41d4-a716-446655440000',
  );
  final _caffeineAmountController = TextEditingController(
    text: '100',
  ); // 新增咖啡因量控制器
  final _drinkNameController = TextEditingController(
    text: 'Coffee',
  ); // 新增飲料名稱控制器

  // 使用 DateTime 物件來儲存時間，方便操作
  DateTime _targetStart = DateTime(2025, 9, 4, 7);
  DateTime _targetEnd = DateTime(2025, 9, 4, 23);
  DateTime _sleepStart = DateTime(2025, 9, 4, 23, 30);
  DateTime _sleepEnd = DateTime(2025, 9, 5, 6, 45);
  DateTime _caffeineIntakeTime = DateTime.now(); // 新增咖啡因攝取時間

  @override
  void dispose() {
    _userIdController.dispose();
    _caffeineAmountController.dispose();
    _drinkNameController.dispose();
    super.dispose();
  }

  // 格式化時間，供顯示和傳送
  String _formatDate(DateTime dateTime) {
    // 假設 API 只需要 UTC 時間，且格式為 ISO 8601
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(dateTime.toUtc());
  }

  // 顯示日期與時間選擇器並更新時間
  Future<void> _selectDateAndTime(
    BuildContext context, {
    required ValueChanged<DateTime> onDateTimeSelected,
  }) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (pickedTime != null) {
      final newDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      onDateTimeSelected(newDateTime);
    }
  }

  Future<void> sendAllDataAndFetchRecommendation() async {
    setState(() {
      responseText = "發送請求中，請稍候...";
    });

    final userId = _userIdController.text;

    try {
      // 1. 發送實際睡眠資料到 /users_sleep/
      final sleepData = {
        "user_id": userId,
        "sleep_start_time": _formatDate(_sleepStart),
        "sleep_end_time": _formatDate(_sleepEnd),
      };
      const sleepUrl = "https://wakemate-api-4-0-qtgs.onrender.com/users_sleep/";
      final sleepResponse = await http
          .post(
            Uri.parse(sleepUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(sleepData),
          )
          .timeout(const Duration(seconds: 15));

      if (sleepResponse.statusCode != 200) {
        setState(() {
          responseText =
              "❌ 發送睡眠資料失敗: ${sleepResponse.statusCode}\n回應: ${sleepResponse.body}";
        });
        return;
      }

      // 2. 發送目標清醒資料到 /users_wake/
      final wakeData = {
        "user_id": userId,
        "target_start_time": _formatDate(_targetStart),
        "target_end_time": _formatDate(_targetEnd),
      };
      const wakeUrl = "https://wakemate-api-4-0-qtgs.onrender.com/users_wake/";
      final wakeResponse = await http
          .post(
            Uri.parse(wakeUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(wakeData),
          )
          .timeout(const Duration(seconds: 15));

      if (wakeResponse.statusCode != 200) {
        setState(() {
          responseText =
              "❌ 發送清醒資料失敗: ${wakeResponse.statusCode}\n回應: ${wakeResponse.body}";
        });
        return;
      }

      // 3. 發送咖啡因攝取資料到 /users_intake/
      final intakeData = {
        "user_id": userId,
        "drink_name": _drinkNameController.text, // 使用新的控制器
        "caffeine_amount": int.parse(_caffeineAmountController.text), // 修正鍵名
        "taking_timestamp": _formatDate(_caffeineIntakeTime), // 修正鍵名
      };
      const intakeUrl = "https://wakemate-api-4-0-qtgs.onrender.com/users_intake/";
      final intakeResponse = await http
          .post(
            Uri.parse(intakeUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(intakeData),
          )
          .timeout(const Duration(seconds: 15));

      if (intakeResponse.statusCode != 200) {
        setState(() {
          responseText =
              "❌ 發送咖啡因攝取資料失敗: ${intakeResponse.statusCode}\n回應: ${intakeResponse.body}";
        });
        return;
      }

      // 4. 觸發後端計算並獲取建議 (使用 GET 請求)
      final recommendationUrl =
          "https://wakemate-api-4-0-qtgs.onrender.com/recommendations/?user_id=$userId";
      final recommendationResponse = await http
          .get(Uri.parse(recommendationUrl))
          .timeout(const Duration(seconds: 15));

      if (recommendationResponse.statusCode == 200) {
        final data = json.decode(recommendationResponse.body);
        setState(() {
          responseText =
              "✅ 計算成功，回傳結果：\n${const JsonEncoder.withIndent('  ').convert(data)}";
        });
      } else {
        setState(() {
          responseText =
              "❌ 觸發計算失敗: ${recommendationResponse.statusCode}\n請求網址: $recommendationUrl\n回應內容: ${recommendationResponse.body}";
        });
      }
    } on TimeoutException {
      setState(() {
        responseText = "⏳ 錯誤: 請求逾時 (Timeout)";
      });
    } on SocketException catch (e) {
      setState(() {
        responseText = "🌐 網路錯誤: $e";
      });
    } catch (e) {
      setState(() {
        responseText = "❌ 未知例外錯誤: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Caffeine Recommendation 測試")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputCard(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: sendAllDataAndFetchRecommendation,
                child: const Text("發送資料並取得建議"),
              ),
              const SizedBox(height: 20),
              _buildResponseText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("輸入資料", style: Theme.of(context).textTheme.headlineSmall),
            const Divider(),
            _buildTextField(_userIdController, "user_id"),
            _buildTimeField("目標清醒開始時間", _targetStart, (DateTime newDateTime) {
              setState(() {
                _targetStart = newDateTime;
              });
            }),
            _buildTimeField("目標清醒結束時間", _targetEnd, (DateTime newDateTime) {
              setState(() {
                _targetEnd = newDateTime;
              });
            }),
            _buildTimeField("實際睡眠開始時間", _sleepStart, (DateTime newDateTime) {
              setState(() {
                _sleepStart = newDateTime;
              });
            }),
            _buildTimeField("實際睡眠結束時間", _sleepEnd, (DateTime newDateTime) {
              setState(() {
                _sleepEnd = newDateTime;
              });
            }),
            _buildTextField(_drinkNameController, "飲料名稱"), // 新增飲料名稱輸入框
            _buildTextField(_caffeineAmountController, "咖啡因攝取量 (mg)"),
            _buildTimeField("咖啡因攝取時間", _caffeineIntakeTime, (
              DateTime newDateTime,
            ) {
              setState(() {
                _caffeineIntakeTime = newDateTime;
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
        ),
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    DateTime time,
    ValueChanged<DateTime> onDateTimeSelected,
  ) {
    final textController = TextEditingController(
      text: DateFormat("yyyy-MM-dd HH:mm").format(time),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: textController,
        readOnly: true,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap:
            () => _selectDateAndTime(
              context,
              onDateTimeSelected: onDateTimeSelected,
            ),
      ),
    );
  }

  Widget _buildResponseText() {
    final bool isSuccess = responseText.startsWith("✅");
    final Color color = isSuccess ? Colors.green : Colors.red;
    final String label = isSuccess ? "成功" : "錯誤";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "$label:\n",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text:
                  isSuccess
                      ? responseText.substring("✅ 計算成功，回傳結果：\n".length)
                      : responseText,
              style: TextStyle(
                fontFamily: isSuccess ? 'monospace' : null,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
