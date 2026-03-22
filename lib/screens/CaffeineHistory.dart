import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CaffeineRecommendationPage.dart'; // 確認路徑正確

class CaffeineHistoryPage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate; // 由首頁傳入的選定日期

  const CaffeineHistoryPage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<CaffeineHistoryPage> createState() => _CaffeineHistoryPageState();
}

class _CaffeineHistoryPageState extends State<CaffeineHistoryPage> {
  final Color _primaryColor = const Color(0xFF1F3D5B); // 深藍色
  final Color _accentColor = const Color(0xFF5E91B3); // 淺藍色
  final Color _backgroundColor = const Color(0xFFF0F2F5); // 淺灰色背景
  final Color _cardColor = Colors.white; // 卡片白色背景
  final Color _textColor = const Color(0xFF424242); // 深灰色文字

  List<dynamic> _allData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- 載入所有歷史數據 ---
  Future<void> _loadData() async {
    if (mounted) setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('caffeine_recommendations') ?? '[]';

    try {
      final List<dynamic> data =
          dataStr.isNotEmpty ? List<dynamic>.from(jsonDecode(dataStr)) : [];

      if (mounted) {
        setState(() {
          _allData = data;
          _loading = false;
        });
      }

      print('=== All Caffeine Data Loaded ===');
      print(_allData);
    } catch (e) {
      print('Error decoding JSON data: $e');
      if (mounted) {
        setState(() {
          _allData = [];
          _loading = false;
        });
      }
    }
  }

  // --- 清除當日資料 ---
  Future<void> _clearDataForSelectedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('caffeine_recommendations') ?? '[]';
    List<dynamic> data = dataStr.isNotEmpty ? jsonDecode(dataStr) : [];

    final String selectedDateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(widget.selectedDate);

    data =
        data.where((item) {
          final String timingStr =
              item['recommended_caffeine_intake_timing'] ?? '';
          if (timingStr.isEmpty) return true;
          final DateTime? localDateTime = _parseAndLocalize(timingStr);
          if (localDateTime == null) return true;
          final String itemDateStr = DateFormat(
            'yyyy-MM-dd',
          ).format(localDateTime);
          return itemDateStr != selectedDateStr;
        }).toList();

    await prefs.setString('caffeine_recommendations', jsonEncode(data));

    setState(() {
      _allData = data;
    });

    print('✅ 已清除 $selectedDateStr 的舊紀錄');
  }

  // --- 時間解析 ---
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
      print('Time parsing failed for "$datetimeStr". Error: $e');
      return null;
    }
  }

  // --- 篩選當日資料 ---
  List<dynamic> _filterSelectedDateData() {
    if (_allData.isEmpty) return [];

    final String selectedDateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(widget.selectedDate);

    final filtered =
        _allData.where((item) {
          final String timingStr =
              item['recommended_caffeine_intake_timing'] ?? '';
          if (timingStr.isEmpty) return false;

          final DateTime? localDateTime = _parseAndLocalize(timingStr);
          if (localDateTime == null) return false;

          final String itemDateStr = DateFormat(
            'yyyy-MM-dd',
          ).format(localDateTime);
          return itemDateStr == selectedDateStr;
        }).toList();

    print('=== Filtered Data for $selectedDateStr ===');
    print(filtered);

    return filtered;
  }

  // --- UI 輔助函式 ---
  Widget _buildDataRow({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      children: [
        Icon(icon, color: _accentColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "$title：$content",
            style: TextStyle(fontSize: 16, color: _textColor),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyForSelectedDate = _filterSelectedDateData();
    final hasHistory = historyForSelectedDate.isNotEmpty;
    final formattedDate = DateFormat('yyyy/MM/dd').format(widget.selectedDate);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "$formattedDate 建議結果",
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : hasHistory
              ? ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: historyForSelectedDate.length,
                itemBuilder: (context, index) {
                  final item = historyForSelectedDate[index];
                  final recommendedTimingStr =
                      item['recommended_caffeine_intake_timing'] ?? 'N/A';
                  final recommendedAmount =
                      item['recommended_caffeine_amount'] ?? 'N/A';

                  final localDateTime = _parseAndLocalize(recommendedTimingStr);
                  final formattedTime =
                      localDateTime != null
                          ? DateFormat('HH:mm').format(localDateTime)
                          : '格式錯誤';

                  return Card(
                    color: _cardColor,
                    elevation: 4.0,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "咖啡因建議 #${index + 1}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDataRow(
                            icon: Icons.access_time_filled,
                            title: "建議攝取時間",
                            content: formattedTime,
                          ),
                          const SizedBox(height: 12),
                          _buildDataRow(
                            icon: Icons.local_cafe,
                            title: "建議攝取量",
                            content: "$recommendedAmount 毫克",
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
              : Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.coffee_outlined,
                        size: 80,
                        color: _accentColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "$formattedDate 無建議紀錄",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "點擊下方按鈕可計算此日期的咖啡因建議。",
                        style: TextStyle(
                          fontSize: 16,
                          color: _textColor.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _clearDataForSelectedDate(); // ✅ 先清資料
                          if (mounted) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CaffeineRecommendationPage(
                                      userId: widget.userId,
                                      selectedDate: widget.selectedDate,
                                    ),
                              ),
                            );
                            if (result == true || result == null) {
                              // ✅ 回來後重新載入資料並刷新
                              await _loadData();
                              if (mounted) setState(() {});
                            }
                          }
                        },
                        icon: const Icon(Icons.auto_graph),
                        label: const Text("重新計算並生成最新建議"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
