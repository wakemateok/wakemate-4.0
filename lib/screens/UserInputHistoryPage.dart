import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // 必須導入 'dart:convert' 才能使用 utf8.decode
import 'dart:async';
import 'package:intl/intl.dart';

// --- 數據模型 (與 CaffeineHistoryPage 共享) ---
class UserDayData {
  final List<dynamic> wakePeriods; // 目標清醒時段
  final List<dynamic> sleepCycles; // 睡眠時段
  final List<dynamic> caffeineIntakes; // 咖啡因攝取

  UserDayData({
    required this.wakePeriods,
    required this.sleepCycles,
    required this.caffeineIntakes,
  });

  bool get isEmpty =>
      wakePeriods.isEmpty && sleepCycles.isEmpty && caffeineIntakes.isEmpty;
}

class UserInputHistoryPage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const UserInputHistoryPage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<UserInputHistoryPage> createState() => _UserInputHistoryPageState();
}

class _UserInputHistoryPageState extends State<UserInputHistoryPage> {
  // 定義顏色和樣式
  final Color _primaryColor = const Color(0xFF1F3D5B);
  final Color _accentColor = const Color(0xFF5E91B3);
  final Color _backgroundColor = const Color(0xFFF0F2F5);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF424242);
  final String baseUrl =
      'https://wakemate-api-4-0-qtgs.onrender.com'; // API Base URL

  late Future<UserDayData> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserInputHistory();
  }

  // --- 數據獲取和過濾邏輯 ---

  // ✅ 修正點：在這裡扣除 8 小時
  DateTime? _parseAndLocalize(String? datetimeStr) {
    if (datetimeStr == null || datetimeStr.isEmpty) return null;
    try {
      // 1. 先解析 API 回傳的 UTC 時間字串
      final parsedTime = DateTime.parse(datetimeStr);
      // 2. 轉換為本地時間 (這一步會自動 +8 小時)
      final localTime = parsedTime.toLocal();
      // 3. 根據您的要求，手動減去 8 小時來修正
      return localTime.subtract(const Duration(hours: 8));
    } catch (e) {
      print('Error parsing or adjusting time: $e');
      return null;
    }
  }

  bool _isDateInRange(DateTime dateTime, DateTime dateStart, DateTime dateEnd) {
    return dateTime.isAfter(
          dateStart.subtract(const Duration(milliseconds: 1)),
        ) &&
        dateTime.isBefore(dateEnd);
  }

  Future<List<dynamic>> _fetchData(
    String endpoint,
    String userId,
    String dateQuery,
  ) async {
    try {
      final url = '$baseUrl/$endpoint/?user_id=$userId&date=$dateQuery';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 🚨 修正點：使用 response.bodyBytes 和 utf8.decode 進行強制 UTF-8 解碼
        final String decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody) as List<dynamic>;
      } else {
        // 🚨 修正點：錯誤訊息也需要解碼
        final String decodedErrorBody = utf8.decode(response.bodyBytes);
        print('API Error for $endpoint: ${response.statusCode}');
        print('API Error Body: $decodedErrorBody');
        // 如果 API 返回 404/204 等表示無數據的狀態碼，可以視為空列表
        return [];
      }
    } catch (e) {
      print('Network Error for $endpoint: $e');
      // 如果發生網路錯誤，拋出錯誤，讓 FutureBuilder 處理
      throw Exception('無法連線到 $endpoint: $e');
    }
  }

  /// 實際從 API 獲取使用者輸入歷史數據
  Future<UserDayData> _fetchUserInputHistory() async {
    final dateQuery = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final userId = widget.userId;

    // 同時發送三個請求
    final List<List<dynamic>> rawResults = await Future.wait([
      _fetchData(
        'users_wake',
        userId,
        dateQuery,
      ).catchError((_) => []), // 捕獲錯誤，返回空列表
      _fetchData('users_sleep', userId, dateQuery).catchError((_) => []),
      _fetchData('users_intake', userId, dateQuery).catchError((_) => []),
    ]);

    final rawWakePeriods = rawResults[0];
    final rawSleepCycles = rawResults[1];
    final rawCaffeineIntakes = rawResults[2];

    // --- 數據過濾 (本地時間篩選) ---
    final dateStart = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );
    final dateEnd = dateStart.add(const Duration(days: 1));

    // 喚醒時段 (以 target_start_time 判斷)
    final filteredWake =
        rawWakePeriods.where((item) {
          final localStart = _parseAndLocalize(
            item['target_start_time'] as String?,
          );
          return localStart != null &&
              _isDateInRange(localStart, dateStart, dateEnd);
        }).toList();

    // 睡眠週期 (以 sleep_end_time 判斷屬於哪一天)
    final filteredSleep =
        rawSleepCycles.where((item) {
          final localEnd = _parseAndLocalize(item['sleep_end_time'] as String?);
          return localEnd != null &&
              _isDateInRange(localEnd, dateStart, dateEnd);
        }).toList();

    // 咖啡因攝取 (以 taking_timestamp 判斷)
    final filteredIntake =
        rawCaffeineIntakes.where((item) {
          final localTake = _parseAndLocalize(
            item['taking_timestamp'] as String?,
          );
          return localTake != null &&
              _isDateInRange(localTake, dateStart, dateEnd);
        }).toList();

    return UserDayData(
      wakePeriods: filteredWake,
      sleepCycles: filteredSleep,
      caffeineIntakes: filteredIntake,
    );
  }

  // --- UI 建構區塊 (其餘保持不變) ---

  Widget _buildDataRow({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              "$title:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textColor.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: TextStyle(fontSize: 14, color: _textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required IconData icon,
    required List<dynamic> dataList,
    required String isEmptyMessage,
    required Widget Function(dynamic item) buildItem,
  }) {
    return Card(
      color: _cardColor,
      elevation: 2.0,
      margin: const EdgeInsets.only(top: 8, bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            if (dataList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  isEmptyMessage,
                  style: TextStyle(color: _textColor.withOpacity(0.5)),
                ),
              )
            else
              ...dataList.map((item) => buildItem(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySection(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 80, color: _accentColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "請返回首頁，點擊「新增紀錄」按鈕，選擇對應時段進行記錄。",
            style: TextStyle(fontSize: 14, color: _textColor.withOpacity(0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat(
      'yyyy/MM/dd',
    ).format(widget.selectedDate);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "$formattedDate 輸入歷史",
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<UserDayData>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  const SizedBox(height: 16),
                  Text("正在載入該日輸入數據...", style: TextStyle(color: _textColor)),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return _buildEmptySection(
              Icons.error_outline,
              "載入輸入歷史時發生錯誤：\n${snapshot.error}",
            );
          } else if (snapshot.hasData) {
            final UserDayData userData = snapshot.data!;

            if (userData.isEmpty) {
              return Center(
                child: _buildEmptySection(
                  Icons.sentiment_dissatisfied,
                  "該日無任何輸入記錄。",
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                _buildSectionTitle(Icons.person_pin_outlined, "您的輸入歷史"),

                // 1. 實際睡眠週期
                _buildInputCard(
                  title: "實際睡眠週期",
                  icon: Icons.bedtime_outlined,
                  dataList: userData.sleepCycles,
                  isEmptyMessage: "無實際睡眠記錄",
                  buildItem: (item) {
                    final start = _parseAndLocalize(
                      item['sleep_start_time'] as String?,
                    );
                    final end = _parseAndLocalize(
                      item['sleep_end_time'] as String?,
                    );

                    if (start == null || end == null) return const SizedBox();

                    final duration = end.difference(start);
                    final hours = duration.inHours;
                    final minutes = duration.inMinutes % 60;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDataRow(
                          icon: Icons.arrow_right_alt,
                          title: "開始時間",
                          content: DateFormat('MM/dd HH:mm').format(start),
                          iconColor: _accentColor,
                        ),
                        _buildDataRow(
                          icon: Icons.arrow_right_alt,
                          title: "結束時間",
                          content: DateFormat('MM/dd HH:mm').format(end),
                          iconColor: _accentColor,
                        ),
                        _buildDataRow(
                          icon: Icons.timer,
                          title: "總時長",
                          content: "${hours}小時 ${minutes}分鐘",
                          iconColor: _accentColor,
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),

                // 2. 目標清醒時段
                _buildInputCard(
                  title: "目標清醒時段",
                  icon: Icons.access_time_filled,
                  dataList: userData.wakePeriods,
                  isEmptyMessage: "無目標清醒時段記錄",
                  buildItem: (item) {
                    final start = _parseAndLocalize(
                      item['target_start_time'] as String?,
                    );
                    final end = _parseAndLocalize(
                      item['target_end_time'] as String?,
                    );

                    if (start == null || end == null) return const SizedBox();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDataRow(
                          icon: Icons.wb_sunny_outlined,
                          title: "開始時間",
                          content: DateFormat('MM/dd HH:mm').format(start),
                          iconColor: _accentColor,
                        ),
                        _buildDataRow(
                          icon: Icons.wb_sunny_outlined,
                          title: "結束時間",
                          content: DateFormat('MM/dd HH:mm').format(end),
                          iconColor: _accentColor,
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),

                // 3. 咖啡因攝取
                _buildInputCard(
                  title: "咖啡因攝取",
                  icon: Icons.local_cafe_outlined,
                  dataList: userData.caffeineIntakes,
                  isEmptyMessage: "無咖啡因攝取記錄",
                  buildItem: (item) {
                    final time = _parseAndLocalize(
                      item['taking_timestamp'] as String?,
                    );
                    final amount = item['caffeine_amount'] ?? 'N/A';
                    final name = item['drink_name'] ?? '未知飲料';

                    if (time == null) return const SizedBox();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDataRow(
                          icon: Icons.schedule,
                          title: "飲用時間",
                          content: DateFormat('MM/dd HH:mm').format(time),
                          iconColor: _accentColor,
                        ),
                        _buildDataRow(
                          icon: Icons.spa,
                          title: "內容",
                          content: "$name ($amount 毫克)",
                          iconColor: _accentColor,
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
