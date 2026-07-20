import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/gen_l10n/app_localizations.dart';

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
  String _resultMessage = "";
  DateTime? _startTime;
  final List<Duration> _reactionTimes = [];
  int _currentTrial = 0;
  final int _totalTrials = 6;
  bool _isError = false;

  int _lapses = 0;
  int _falseStarts = 0;

  final String baseUrl = 'https://wakemate-api-4-0-qtgs.onrender.com';
  int? _selectedKssLevel;

  void _startTest() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _reactionTimes.clear();
      _currentTrial = 0;
      _lapses = 0;
      _falseStarts = 0;
      _resultMessage = l10n.alertnessWait;
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
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isWaiting = false;
        _boxColor = _successColor;
        _startTime = DateTime.now();
        _resultMessage = l10n.alertnessTapNow;
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
    final l10n = AppLocalizations.of(context)!;

    if (_isWaiting) {
      _timer?.cancel();
      setState(() {
        _testStarted = false;
        _boxColor = _errorColor;
        _isError = true;
        _resultMessage = l10n.alertnessTooEarly;
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
            "${l10n.alertnessTrialPrefix}$_currentTrial${l10n.alertnessTrialSuffix}: ${adjustedReaction.inMilliseconds} ${l10n.millisecondsUnit}";
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

  String _getKssDescription(int level, AppLocalizations l10n) {
    switch (level) {
      case 1:
        return l10n.kss1;
      case 2:
        return l10n.kss2;
      case 3:
        return l10n.kss3;
      case 4:
        return l10n.kss4;
      case 5:
        return l10n.kss5;
      case 6:
        return l10n.kss6;
      case 7:
        return l10n.kss7;
      case 8:
        return l10n.kss8;
      case 9:
        return l10n.kss9;
      default:
        return "";
    }
  }

  void _showResultDialog(double avgTime) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.alertnessResultTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const SizedBox(height: 10),
                Text(
                  l10n.alertnessEachReactionTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555555),
                  ),
                ),
                ..._reactionTimes.asMap().entries.map((entry) {
                  int index = entry.key;
                  Duration time = entry.value;
                  return Text(
                    "${l10n.alertnessTrialPrefix}${index + 1}${l10n.alertnessTrialSuffix}: ${time.inMilliseconds} ${l10n.millisecondsUnit}",
                    style: const TextStyle(color: Color(0xFF777777)),
                  );
                }),
                const Divider(
                  height: 30,
                  thickness: 1.5,
                  color: Color(0xFFDDDDDD),
                ),
                Text(
                  "${l10n.alertnessAverageReactionTime}: ${avgTime.toStringAsFixed(2)} ${l10n.millisecondsUnit}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: _primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.alertnessChooseKss,
                  style: const TextStyle(
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
                          hint: Text(l10n.alertnessChooseKssHint),
                          items:
                              kssLevels.map((int level) {
                                return DropdownMenuItem<int>(
                                  value: level,
                                  child: Text(
                                    "$level - ${_getKssDescription(level, l10n)}",
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
              child: Text(l10n.alertnessRetest),
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
              child: Text(l10n.alertnessDoneClose),
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
    final l10n = AppLocalizations.of(context)!;
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
            SnackBar(
              content: Text(l10n.alertnessDataSent),
              backgroundColor: const Color(0xFF28A745),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.alertnessSubmitFailedStatus} ${res.statusCode}',
              ),
              backgroundColor: _errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.alertnessNetworkSubmitFailed),
            backgroundColor: const Color(0xFFDC3545),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.alertnessTest,
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
                _resultMessage.isEmpty
                    ? l10n.alertnessTapToStart
                    : _resultMessage,
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
                          ? Text(
                            l10n.tapHere,
                            style: const TextStyle(
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
                child: Text(l10n.startTest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
