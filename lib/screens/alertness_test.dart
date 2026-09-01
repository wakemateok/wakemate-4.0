import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/api/api_config.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';

enum AlertnessTestVersion { brief, pvtb3Minute }

class AlertnessTestPage extends StatefulWidget {
  final String userId;
  final AlertnessTestVersion version;

  const AlertnessTestPage({super.key, required this.userId})
    : version = AlertnessTestVersion.brief;

  const AlertnessTestPage.pvtb({super.key, required this.userId})
    : version = AlertnessTestVersion.pvtb3Minute;

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

  final Random _random = Random();
  Timer? _timer;
  Timer? _durationTimer;
  Timer? _clockTimer;
  Timer? _counterTimer;
  bool _isWaiting = true;
  bool _testStarted = false;
  Color _boxColor = const Color(0xFF5E91B3);
  String _resultMessage = "";
  DateTime? _startTime;
  DateTime? _testDeadline;
  final List<Duration> _reactionTimes = [];
  int _currentTrial = 0;
  Duration _remainingTime = Duration.zero;
  int _stimulusElapsedMs = 0;
  bool _hasCompleted = false;
  bool _isError = false;

  int _lapses = 0;
  int _falseStarts = 0;

  static const Duration _requestTimeout = Duration(seconds: 60);
  final String baseUrl = ApiConfig.baseUrl;
  int? _selectedKssLevel;

  bool get _isPvtB => widget.version == AlertnessTestVersion.pvtb3Minute;

  int? get _trialLimit => _isPvtB ? null : 6;

  Duration get _testDuration =>
      _isPvtB ? const Duration(minutes: 3) : Duration.zero;

  Duration get _responseWindow =>
      _isPvtB ? const Duration(seconds: 30) : const Duration(seconds: 2);

  Duration get _feedbackDelay => const Duration(seconds: 1);

  Duration get _falseStartDelay =>
      _isPvtB ? const Duration(seconds: 1) : const Duration(milliseconds: 1500);

  Duration get _reactionAdjustment =>
      _isPvtB ? Duration.zero : const Duration(milliseconds: 100);

  String get _deviceLabel => _isPvtB ? 'Mobile PVT-B 3min' : 'Mobile';

  void _startTest() {
    final l10n = AppLocalizations.of(context)!;
    _cancelAllTimers();
    setState(() {
      _reactionTimes.clear();
      _currentTrial = 0;
      _lapses = 0;
      _falseStarts = 0;
      _resultMessage = l10n.alertnessWait;
      _isWaiting = true;
      _testStarted = true;
      _boxColor = _boxDefaultColor;
      _isError = false;
      _stimulusElapsedMs = 0;
      _hasCompleted = false;
      _testDeadline = _isPvtB ? DateTime.now().add(_testDuration) : null;
      _remainingTime = _testDuration;
    });

    if (_isPvtB) {
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _refreshRemainingTime();
      });
      _durationTimer = Timer(_testDuration, _testCompleted);
    }

    _runTestSequence();
  }

  void _runTestSequence() {
    if (!mounted || _hasCompleted) return;

    final trialLimit = _trialLimit;
    if (_timeExpired || (trialLimit != null && _currentTrial >= trialLimit)) {
      _testCompleted();
      return;
    }

    _timer?.cancel();
    _counterTimer?.cancel();
    setState(() {
      _isWaiting = true;
      _testStarted = true;
      _boxColor = _boxDefaultColor;
      _isError = false;
      _stimulusElapsedMs = 0;
      _resultMessage = AppLocalizations.of(context)!.alertnessWait;
    });

    final randomDelay = _boundedByRemaining(_randomInterStimulusDelay());
    if (_timeExpired) {
      _testCompleted();
      return;
    }

    _timer = Timer(randomDelay, () {
      if (!mounted || _hasCompleted) return;
      if (_timeExpired) {
        _testCompleted();
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isWaiting = false;
        _boxColor = _successColor;
        _startTime = DateTime.now();
        _stimulusElapsedMs = 0;
        _resultMessage = l10n.alertnessTapNow;
      });

      if (_isPvtB) {
        _startStimulusCounter();
      }

      final responseWindow = _boundedByRemaining(_responseWindow);
      if (responseWindow <= Duration.zero) {
        _testCompleted();
        return;
      }

      _timer = Timer(responseWindow, () {
        if (!mounted || _hasCompleted) return;
        if (_boxColor == _successColor) {
          _counterTimer?.cancel();
          _lapses++;
          _currentTrial++;
          setState(() {
            _isWaiting = true;
            _boxColor = _boxDefaultColor;
            _isError = false;
            _stimulusElapsedMs = 0;
            _resultMessage = l10n.alertnessNoResponse;
          });
          _scheduleNextTrial(_feedbackDelay);
        }
      });
    });
  }

  void _boxTapped() {
    if (!_testStarted || _hasCompleted) return;
    final l10n = AppLocalizations.of(context)!;

    if (_isWaiting) {
      _timer?.cancel();
      _counterTimer?.cancel();
      _falseStarts++;
      setState(() {
        _boxColor = _errorColor;
        _isError = true;
        _isWaiting = true;
        _stimulusElapsedMs = 0;
        _resultMessage = l10n.alertnessTooEarly;
      });

      _scheduleNextTrial(_falseStartDelay);
    } else {
      _timer?.cancel();
      _counterTimer?.cancel();
      final reaction = DateTime.now().difference(_startTime!);
      final rawAdjustedReaction = reaction - _reactionAdjustment;
      final adjustedReaction =
          rawAdjustedReaction.isNegative ? Duration.zero : rawAdjustedReaction;

      if (_isPvtB && adjustedReaction < const Duration(milliseconds: 100)) {
        _falseStarts++;
        _currentTrial++;
        setState(() {
          _isWaiting = true;
          _boxColor = _errorColor;
          _isError = true;
          _stimulusElapsedMs = adjustedReaction.inMilliseconds;
          _resultMessage = l10n.alertnessTooEarly;
        });
        _scheduleNextTrial(_feedbackDelay);
        return;
      }

      _reactionTimes.add(adjustedReaction);
      if (_isPvtB && adjustedReaction > const Duration(milliseconds: 500)) {
        _lapses++;
      }
      _currentTrial++;

      setState(() {
        _isWaiting = true;
        _boxColor = _boxDefaultColor;
        _isError = false;
        _stimulusElapsedMs = adjustedReaction.inMilliseconds;
        _resultMessage =
            "${l10n.alertnessTrialPrefix}$_currentTrial${l10n.alertnessTrialSuffix}: ${adjustedReaction.inMilliseconds} ${l10n.millisecondsUnit}";
      });

      _scheduleNextTrial(_feedbackDelay);
    }
  }

  void _testCompleted() {
    if (_hasCompleted) return;
    _cancelAllTimers();
    if (!mounted) return;
    _hasCompleted = true;

    setState(() {
      _testStarted = false;
      _isWaiting = true;
      _boxColor = _boxDefaultColor;
      _stimulusElapsedMs = 0;
      if (_isPvtB) {
        _remainingTime = Duration.zero;
      }
    });

    final avgTime = _averageReactionTime();
    _showResultDialog(avgTime);
  }

  Duration _randomInterStimulusDelay() {
    if (_isPvtB) {
      return Duration(milliseconds: _random.nextInt(3001));
    }

    return Duration(milliseconds: 1000 + _random.nextInt(4000));
  }

  bool get _timeExpired {
    if (!_isPvtB || _testDeadline == null) return false;
    return !DateTime.now().isBefore(_testDeadline!);
  }

  Duration _boundedByRemaining(Duration duration) {
    if (!_isPvtB || _testDeadline == null) return duration;

    final remaining = _testDeadline!.difference(DateTime.now());
    if (remaining <= Duration.zero) return Duration.zero;
    return remaining < duration ? remaining : duration;
  }

  void _scheduleNextTrial(Duration delay) {
    if (_hasCompleted) return;

    final nextDelay = _boundedByRemaining(delay);
    if (nextDelay <= Duration.zero) {
      _testCompleted();
      return;
    }

    _timer = Timer(nextDelay, () {
      if (mounted) {
        _runTestSequence();
      }
    });
  }

  void _startStimulusCounter() {
    _counterTimer?.cancel();
    _counterTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _startTime == null || _isWaiting || _hasCompleted) {
        return;
      }

      setState(() {
        _stimulusElapsedMs =
            DateTime.now().difference(_startTime!).inMilliseconds;
      });
    });
  }

  void _refreshRemainingTime() {
    if (!mounted || !_isPvtB || !_testStarted || _testDeadline == null) return;

    final remaining = _testDeadline!.difference(DateTime.now());
    setState(() {
      _remainingTime = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  void _cancelAllTimers() {
    _timer?.cancel();
    _timer = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    _clockTimer?.cancel();
    _clockTimer = null;
    _counterTimer?.cancel();
    _counterTimer = null;
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
                ..._buildResultSummary(l10n),
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
                          color: _primaryColor.withValues(alpha: 0.5),
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
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': widget.userId,
              'mean_rt': avgTime,
              'lapses': lapses,
              'false_starts': falseStarts,
              'kss_level': kssLevel,
              'device': _deviceLabel,
              'test_at': DateTime.now().toUtc().toIso8601String(),
            }),
          )
          .timeout(_requestTimeout);

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
              content: Text(_formatSubmitError(res, l10n)),
              backgroundColor: _errorColor,
            ),
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsRequestTimeout),
            backgroundColor: const Color(0xFFDC3545),
          ),
        );
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

  String _formatSubmitError(http.Response res, AppLocalizations l10n) {
    final body = res.body.trim();
    if (res.statusCode == 503 ||
        body.contains('<!DOCTYPE html') ||
        body.contains('<html') ||
        body.contains('Service Suspended')) {
      return l10n.settingsServerUnavailable;
    }

    return '${l10n.alertnessSubmitFailedStatus} ${res.statusCode}';
  }

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pageTitle =
        _isPvtB ? l10n.pvtbAlertnessTest : l10n.briefAlertnessTest;
    final showIntro =
        !_testStarted &&
        _reactionTimes.isEmpty &&
        _currentTrial == 0 &&
        _resultMessage.isEmpty;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          pageTitle,
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
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewPadding.bottom + 32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showIntro)
                _buildIntroCard(l10n)
              else
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
              if (_isPvtB && _testStarted) ...[
                const SizedBox(height: 20),
                _buildProgressCard(l10n),
              ],
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
                        color: _boxColor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _buildBoxContent(l10n),
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

  Widget _buildIntroCard(AppLocalizations l10n) {
    final introTitle =
        _isPvtB ? l10n.pvtbAlertnessIntroTitle : l10n.alertnessIntroTitle;
    final introBody =
        _isPvtB ? l10n.pvtbAlertnessIntroBody : l10n.alertnessIntroBody;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.touch_app_outlined, color: _primaryColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  introTitle,
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            introBody,
            style: TextStyle(
              color: _primaryColor.withValues(alpha: 0.82),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResultSummary(AppLocalizations l10n) {
    if (_isPvtB) {
      return [
        _buildResultStat(l10n.alertnessCompletedTrials, '$_currentTrial'),
        _buildResultStat(l10n.alertnessLapses, '$_lapses'),
        _buildResultStat(l10n.alertnessFalseStarts, '$_falseStarts'),
      ];
    }

    return [
      Text(
        l10n.alertnessEachReactionTime,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF555555),
        ),
      ),
      ..._reactionTimes.asMap().entries.map((entry) {
        final index = entry.key;
        final time = entry.value;
        return Text(
          "${l10n.alertnessTrialPrefix}${index + 1}${l10n.alertnessTrialSuffix}: ${time.inMilliseconds} ${l10n.millisecondsUnit}",
          style: const TextStyle(color: Color(0xFF777777)),
        );
      }),
    ];
  }

  Widget _buildResultStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF555555),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildProgressMetric(
              l10n.alertnessTimeRemaining,
              _formatDuration(_remainingTime),
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: _primaryColor.withValues(alpha: 0.12),
          ),
          Expanded(
            child: _buildProgressMetric(
              l10n.alertnessCompletedTrials,
              '$_currentTrial',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _primaryColor.withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBoxContent(AppLocalizations l10n) {
    if (!_testStarted) {
      return Text(
        l10n.tapHere,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (_isPvtB && !_isWaiting) {
      return Text(
        '$_stimulusElapsedMs\n${l10n.millisecondsUnit}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 38,
          fontWeight: FontWeight.bold,
          height: 1.15,
        ),
        textAlign: TextAlign.center,
      );
    }

    return const SizedBox.shrink();
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.isNegative ? 0 : duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
