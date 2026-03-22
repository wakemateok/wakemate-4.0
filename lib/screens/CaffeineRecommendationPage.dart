import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CaffeineHistory.dart';

class CaffeineRecommendationPage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const CaffeineRecommendationPage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<CaffeineRecommendationPage> createState() =>
      _CaffeineRecommendationPageState();
}

class _CaffeineRecommendationPageState extends State<CaffeineRecommendationPage>
    with SingleTickerProviderStateMixin {
  final Color _primaryColor = const Color(0xFF1F3D5B);
  final Color _accentColor = const Color(0xFF5E91B3);

  bool _isLoading = true;
  String _errorMessage = "";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.bounceOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sendAllDataAndFetchRecommendation();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    if (!mounted) return;
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

  Future<void> _saveRecommendationData(dynamic newData) async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('caffeine_recommendations') ?? '[]';
    List<dynamic> currentHistory;
    try {
      currentHistory = json.decode(dataStr);
    } catch (e) {
      print('Error decoding existing history: $e. Starting with empty list.');
      currentHistory = [];
    }

    final List<dynamic> newEntries = newData is List ? newData : [newData];

    final String targetDateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(widget.selectedDate);

    currentHistory =
        currentHistory.where((item) {
          final String timingStr =
              item['recommended_caffeine_intake_timing'] ?? '';
          if (timingStr.isEmpty) return true;
          final DateTime? parsed = DateTime.tryParse(timingStr)?.toLocal();
          if (parsed == null) return true;
          final String itemDateStr = DateFormat('yyyy-MM-dd').format(parsed);
          return itemDateStr != targetDateStr;
        }).toList();

    currentHistory.addAll(newEntries);

    await prefs.setString(
      'caffeine_recommendations',
      json.encode(currentHistory),
    );

    print('✅ 已更新推薦資料，共 ${currentHistory.length} 筆');
  }

  Future<void> sendAllDataAndFetchRecommendation() async {
    final userId = widget.userId;

    try {
      const timeout = Duration(seconds: 15);

      // ✅ 只保留「取得推薦」的部分
      final recommendationUrl =
          "https://wakemate-api-4-0.onrender.com/recommendations/?user_id=$userId";
      final recommendationResponse = await http
          .get(Uri.parse(recommendationUrl))
          .timeout(timeout);

      if (recommendationResponse.statusCode == 200) {
        final data = json.decode(recommendationResponse.body);
        _showSnackBar("計算成功！", color: Colors.green);
        await _saveRecommendationData(data);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => CaffeineHistoryPage(
                  userId: widget.userId,
                  selectedDate: widget.selectedDate,
                ),
          ),
        );
      } else {
        String bodyPreview =
            recommendationResponse.body.length > 50
                ? recommendationResponse.body.substring(0, 50) + '...'
                : recommendationResponse.body;
        _showSnackBar(
          "計算失敗: ${recommendationResponse.statusCode}",
          color: Colors.red,
        );
        if (mounted) {
          setState(() {
            _errorMessage =
                "伺服器錯誤 (Status: ${recommendationResponse.statusCode})。\n回應內容預覽: $bodyPreview";
            _isLoading = false;
          });
          _animationController.reverse();
        }
      }
    } on TimeoutException {
      _showSnackBar("錯誤：請求逾時，請檢查您的網路連線。", color: Colors.red);
      if (mounted) {
        setState(() {
          _errorMessage = "連線逾時。請檢查網路後重試。";
          _isLoading = false;
        });
        _animationController.reverse();
      }
    } on SocketException {
      _showSnackBar("網路連線錯誤，請檢查您的網路。", color: Colors.red);
      if (mounted) {
        setState(() {
          _errorMessage = "無法連線到伺服器。請檢查網路。";
          _isLoading = false;
        });
        _animationController.reverse();
      }
    } catch (e) {
      _showSnackBar("發生未知錯誤: $e", color: Colors.red);
      if (mounted) {
        setState(() {
          _errorMessage = "發生未知錯誤: $e";
          _isLoading = false;
        });
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "咖啡因建議",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(color: Colors.white),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _animationController.value * 5,
                    sigmaY: _animationController.value * 5,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(
                      0.1 * _animationController.value,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child:
                                _isLoading
                                    ? _buildLoadingWidget()
                                    : _buildErrorWidget(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: _primaryColor, strokeWidth: 5),
        const SizedBox(height: 24),
        Text(
          "正在為您分析咖啡因數據...",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "這可能需要一點時間，請耐心等候",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.sentiment_dissatisfied, color: Colors.redAccent, size: 70),
        const SizedBox(height: 20),
        Text(
          "哎呀！計算失敗了...",
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[700], fontSize: 15),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = "";
              });
              _animationController.reset();
              _animationController.forward();
              sendAllDataAndFetchRecommendation();
            }
          },
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text("重新嘗試", style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 8,
          ),
        ),
        const SizedBox(height: 15),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "返回主頁",
            style: TextStyle(color: _accentColor, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
