import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_app/api/api_config.dart';
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/services/notification_service.dart';
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
  bool _isEmptyResult = false;

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
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveRecommendationData(dynamic newData) async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('caffeine_recommendations') ?? '[]';
    List<dynamic> currentHistory;
    try {
      currentHistory = json.decode(dataStr);
    } catch (_) {
      currentHistory = [];
    }

    final List<dynamic> newEntries = newData is List ? newData : [newData];
    final targetDateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

    currentHistory =
        currentHistory.where((item) {
          final timingStr =
              item['recommended_caffeine_intake_timing']?.toString() ?? '';
          if (timingStr.isEmpty) return true;
          final parsed = apiTimestampToTaipei(timingStr);
          if (parsed == null) return true;
          return DateFormat('yyyy-MM-dd').format(parsed) != targetDateStr;
        }).toList();

    currentHistory.addAll(newEntries);
    await prefs.setString(
      'caffeine_recommendations',
      json.encode(currentHistory),
    );
  }

  Future<void> sendAllDataAndFetchRecommendation() async {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    try {
      const calculationTimeout = Duration(seconds: 90);
      const fetchTimeout = Duration(seconds: 20);
      final calculationUrl =
          '${ApiConfig.baseUrl}/calculate/?user_id=${widget.userId}';
      final calculationResponse = await http
          .post(Uri.parse(calculationUrl))
          .timeout(calculationTimeout);

      if (calculationResponse.statusCode != 200) {
        final bodyPreview =
            calculationResponse.body.length > 160
                ? '${calculationResponse.body.substring(0, 160)}...'
                : calculationResponse.body;
        _showError(
          '${l10n.recommendationFailed}: '
          '${calculationResponse.statusCode}\n$bodyPreview',
        );
        return;
      }

      final recommendationUrl =
          '${ApiConfig.baseUrl}/recommendations/?user_id=${widget.userId}';
      final response = await http
          .get(Uri.parse(recommendationUrl))
          .timeout(fetchTimeout);

      if (response.statusCode != 200) {
        final bodyPreview =
            response.body.length > 120
                ? '${response.body.substring(0, 120)}...'
                : response.body;
        _showError(
          '${l10n.recommendationFailed}: ${response.statusCode}\n$bodyPreview',
        );
        return;
      }

      final data = json.decode(utf8.decode(response.bodyBytes));
      final entries = data is List ? data : [data];

      if (entries.isEmpty) {
        await _configureNotifications(
          entries: const [],
          languageCode: languageCode,
        );
        _showEmptyResult();
        return;
      }

      await _saveRecommendationData(entries);
      await _configureNotifications(
        entries: entries,
        languageCode: languageCode,
      );
      _showSnackBar(l10n.recommendationFetched, color: Colors.green);

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
    } on TimeoutException {
      _showError('${l10n.recommendationFailed}: timeout');
    } on SocketException {
      _showError('${l10n.networkError}: socket');
    } catch (e) {
      _showError('${l10n.recommendationFailed}: $e');
    }
  }

  Future<void> _configureNotifications({
    required List<dynamic> entries,
    required String languageCode,
  }) async {
    var scheduledCount = 0;

    try {
      scheduledCount = await NotificationService.instance
          .replaceCaffeineReminders(
            recommendations: entries,
            languageCode: languageCode,
          );
    } catch (error) {
      debugPrint('Caffeine reminder scheduling failed: $error');
    }

    try {
      await NotificationService.instance.showCalculationComplete(
        recommendationCount: scheduledCount,
        languageCode: languageCode,
      );
    } catch (error) {
      debugPrint('Calculation notification failed: $error');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isEmptyResult = false;
      _isLoading = false;
    });
    _animationController.forward(from: 1);
  }

  void _showEmptyResult() {
    final l10n = AppLocalizations.of(context)!;
    if (!mounted) return;
    setState(() {
      _errorMessage = l10n.noRecommendationBody;
      _isEmptyResult = true;
      _isLoading = false;
    });
    _animationController.forward(from: 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          l10n.recommendationTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
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
                    color: Colors.black.withValues(
                      alpha: 0.1 * _animationController.value,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child:
                                _isLoading
                                    ? _buildLoadingWidget(l10n)
                                    : _buildMessageWidget(l10n),
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

  Widget _buildLoadingWidget(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: _primaryColor, strokeWidth: 5),
        const SizedBox(height: 24),
        Text(
          l10n.calculatingRecommendation,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.recommendationNote,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMessageWidget(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isEmptyResult ? Icons.coffee_outlined : Icons.sentiment_dissatisfied,
          color: _isEmptyResult ? _accentColor : Colors.redAccent,
          size: 70,
        ),
        const SizedBox(height: 20),
        Text(
          _isEmptyResult
              ? l10n.noRecommendationTitle
              : l10n.recommendationFailed,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _isEmptyResult ? _primaryColor : Colors.redAccent,
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
            setState(() {
              _isLoading = true;
              _isEmptyResult = false;
              _errorMessage = "";
            });
            _animationController.reset();
            _animationController.forward();
            sendAllDataAndFetchRecommendation();
          },
          icon: const Icon(Icons.refresh, size: 20),
          label: Text(l10n.retry, style: const TextStyle(fontSize: 18)),
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
            l10n.back,
            style: TextStyle(color: _accentColor, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
