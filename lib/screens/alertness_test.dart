import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AlertnessTestPage extends StatefulWidget {
  final String userId;

  const AlertnessTestPage({super.key, required this.userId});

  @override
  State<AlertnessTestPage> createState() => _AlertnessTestPageState();
}

class _AlertnessTestPageState extends State<AlertnessTestPage> {
  // 定義顏色和樣式
  final Color _primaryColor = const Color(0xFF1F3D5B); // 深藍色
  final Color _successColor = const Color(0xFF32C669); // 綠色
  final Color _errorColor = const Color(0xFFE53935); // 紅色
  final Color _backgroundColor = const Color(0xFFF0F2F5); // 淺灰色背景
  final Color _boxDefaultColor = const Color(0xFF5E91B3); // 淺藍色

  Timer? _timer;
  bool _isWaiting = true;
  bool _testStarted = false;
  Color _boxColor = const Color(0xFF5E91B3);
  String _resultMessage = "點擊開始";
  DateTime? _startTime;
  final List<Duration> _reactionTimes = [];
  int _currentTrial = 0;
  final int _totalTrials = 6;
  bool _isError = false;

  int _lapses = 0;
  int _falseStarts = 0;

  final String baseUrl = 'https://wakemate-api-4-0.onrender.com';
  int? _selectedKssLevel;

  void _startTest() {
    setState(() {
      _reactionTimes.clear();
      _currentTrial = 0;
      _lapses = 0;
      _falseStarts = 0;
      _resultMessage = "請等待...";
    });
    _runTestSequence();
  }

  void _runTestSequence() {
    if (_currentTrial >= _totalTrials) {
      _testCompleted();
      return;
    }

    setState(() {
      _isWaiting = true;
      _testStarted = true;
      _boxColor = _boxDefaultColor;
      _isError = false;
    });

    int randomDelay = 1000 + Random().nextInt(4000);
    _timer = Timer(Duration(milliseconds: randomDelay), () {
      if (!mounted) return;
      setState(() {
        _isWaiting = false;
        _boxColor = _successColor;
        _startTime = DateTime.now();
        _resultMessage = "請點擊！";
      });

      _timer = Timer(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        if (_boxColor == _successColor) {
          _lapses++;
          _runTestSequence();
        }
      });
    });
  }

  void _boxTapped() {
    if (!_testStarted) return;

    if (_isWaiting) {
      _timer?.cancel();
      setState(() {
        _testStarted = false;
        _boxColor = _errorColor;
        _isError = true;
        _resultMessage = "❌ 點太快了！重來";
        _falseStarts++;
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _runTestSequence();
        }
      });
    } else {
      _timer?.cancel();
      final reaction = DateTime.now().difference(_startTime!);

      // 在此處減去 100 毫秒來調整反應時間
      final adjustedReaction = reaction - const Duration(milliseconds: 100);

      _reactionTimes.add(adjustedReaction);
      _currentTrial++;

      setState(() {
        _testStarted = false;
        _boxColor = _boxDefaultColor;
        _isError = false;
        _resultMessage =
            "第$_currentTrial次: ${adjustedReaction.inMilliseconds} 毫秒";
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _runTestSequence();
        }
      });
    }
  }

  void _testCompleted() {
    setState(() {
      _testStarted = false;
      _boxColor = _boxDefaultColor;
    });

    final avgTime = _averageReactionTime();
    _showResultDialog(avgTime);
  }

  String _getKssDescription(int level) {
    switch (level) {
      case 1:
        return "極度警醒";
      case 2:
        return "非常警醒";
      case 3:
        return "警醒";
      case 4:
        return "比較警醒";
      case 5:
        return "不太警醒但也無睏意";
      case 6:
        return "有一些睏意傾向";
      case 7:
        return "有睏意，但是不需要努力保持清醒";
      case 8:
        return "有睏意，且需要一定的努力保持清醒";
      case 9:
        return "非常睏倦，需要極大的努力保持清醒";
      default:
        return "";
    }
  }

  void _showResultDialog(double avgTime) {
    setState(() {
      _selectedKssLevel = null;
    });

    final List<int> kssLevels = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: _backgroundColor,
          title: Text(
            "測試結果",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "每次反應時間：",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),
                ..._reactionTimes.asMap().entries.map((entry) {
                  int index = entry.key;
                  Duration time = entry.value;
                  return Text(
                    "第${index + 1}次：${time.inMilliseconds} 毫秒",
                    style: const TextStyle(color: Color(0xFF777777)),
                  );
                }).toList(),
                const Divider(
                  height: 30,
                  thickness: 1.5,
                  color: Color(0xFFDDDDDD),
                ),
                Text(
                  "平均反應時間：${avgTime.toStringAsFixed(2)} 毫秒",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: _primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  "選擇您覺得的清醒程度 (KSS):",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),
                StatefulBuilder(
                  builder: (context, setInnerState) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _primaryColor.withOpacity(0.5),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedKssLevel,
                          isExpanded: true,
                          hint: const Text("選擇 KSS 分數"),
                          items:
                              kssLevels.map((int level) {
                                return DropdownMenuItem<int>(
                                  value: level,
                                  child: Text(
                                    "$level - ${_getKssDescription(level)}",
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (int? newValue) {
                            setInnerState(() {
                              _selectedKssLevel = newValue;
                            });
                          },
                          dropdownColor: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: [
            TextButton(
              onPressed: () {
                _sendAverageReactionTime(
                  avgTime,
                  _selectedKssLevel,
                  _lapses,
                  _falseStarts,
                );
                Navigator.of(context).pop();
                _startTest();
              },
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text("再測一次"),
            ),
            ElevatedButton(
              onPressed: () {
                _sendAverageReactionTime(
                  avgTime,
                  _selectedKssLevel,
                  _lapses,
                  _falseStarts,
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("完成並關閉"),
            ),
          ],
        );
      },
    );
  }

  double _averageReactionTime() {
    if (_reactionTimes.isEmpty) return 0;
    final totalMs = _reactionTimes
        .map((d) => d.inMilliseconds)
        .reduce((a, b) => a + b);
    return totalMs / _reactionTimes.length;
  }

  Future<void> _sendAverageReactionTime(
    double avgTime,
    int? kssLevel,
    int lapses,
    int falseStarts,
  ) async {
    final url = Uri.parse('$baseUrl/users_pvt/');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'mean_rt': avgTime,
          'lapses': lapses,
          'false_starts': falseStarts,
          'kss_level': kssLevel,
          'device': 'Mobile',
          'test_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('數據已成功送出！'),
              backgroundColor: Color(0xFF28A745),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('送出失敗，狀態碼：${res.statusCode}'),
              backgroundColor: _errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('網路錯誤，無法送出數據'),
            backgroundColor: Color(0xFFDC3545),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          "清醒度測試",
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _resultMessage,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _isError ? _errorColor : _primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _boxTapped,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: _boxColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _boxColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child:
                      !_testStarted
                          ? const Text(
                            "點擊此處",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: !_testStarted ? _startTest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text("開始測試"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
