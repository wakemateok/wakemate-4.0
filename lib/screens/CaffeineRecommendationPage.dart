import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/api/home_data.dart';
import 'package:my_app/api/recommendation_failure.dart';
import 'package:my_app/services/recommendation_invalidation.dart';
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/utils/recommendation_deduplication.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/services/auth_service.dart';

import 'CaffeineHistory.dart';
import 'UserInputHistoryPage.dart';

class CaffeineRecommendationPage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;
  final bool forceRecalculate;
  final HomeRepository? repository;

  const CaffeineRecommendationPage({
    super.key,
    required this.userId,
    required this.selectedDate,
    this.forceRecalculate = false,
    this.repository,
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
  bool _requestStarted = false;
  RecommendationFailure? _failure;
  late final HomeRepository _repository;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? HomeRepository();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      sendAllDataAndFetchRecommendation();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    if (widget.repository == null) _repository.close();
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

  Future<void> _saveRecommendationData(
    List<Map<String, dynamic>> newEntries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || AuthService.instance.userId != widget.userId) return;
    final dataStr =
        prefs.getString('caffeine_recommendations_${widget.userId}') ?? '[]';
    List<Map<String, dynamic>> currentHistory;
    try {
      currentHistory = recommendationMapsFrom(json.decode(dataStr));
    } catch (_) {
      currentHistory = [];
    }

    final replacementDates = <String>{
      DateFormat('yyyy-MM-dd').format(widget.selectedDate),
      ...newEntries
          .map((item) => recommendationTiming(item))
          .whereType<DateTime>()
          .map((time) => DateFormat('yyyy-MM-dd').format(time)),
    };

    currentHistory =
        currentHistory.where((item) {
          final timingStr =
              item['recommended_caffeine_intake_timing']?.toString() ?? '';
          if (timingStr.isEmpty) return true;
          final parsed = apiTimestampToTaipei(timingStr);
          if (parsed == null) return true;
          return !replacementDates.contains(
            DateFormat('yyyy-MM-dd').format(parsed),
          );
        }).toList();

    currentHistory.addAll(dedupeRecommendations(newEntries));
    await prefs.setString(
      'caffeine_recommendations_${widget.userId}',
      json.encode(dedupeRecommendations(currentHistory)),
    );
  }

  Future<void> sendAllDataAndFetchRecommendation() async {
    if (_requestStarted) return;
    _requestStarted = true;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _failure = null;
    });
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    try {
      await invalidateFutureRecommendations(userId: widget.userId);
      final snapshot = await _repository.load(widget.userId, recalculate: true);
      if (!mounted) return;
      if (snapshot.calculationFailed ||
          !snapshot.hasSleep ||
          !snapshot.hasWake) {
        _failure =
            snapshot.recommendationFailure ??
            const RecommendationFailure('missing_inputs');
        _showError(_failure!.message(languageCode));
        return;
      }
      final entries = snapshot.recommendationsOn(widget.selectedDate);
      try {
        await _saveRecommendationData(snapshot.recommendations);
      } catch (error) {
        debugPrint('Confirmed recommendation cache could not be saved: $error');
      }
      await _configureNotifications(
        entries: snapshot.recommendations,
        languageCode: languageCode,
      );
      if (!mounted) return;
      if (entries.isEmpty) {
        _showEmptyResult();
        return;
      }
      _showSnackBar(l10n.recommendationFetched, color: Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => CaffeineHistoryPage(
                userId: widget.userId,
                selectedDate: widget.selectedDate,
                confirmedEntries: snapshot.recommendations,
              ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _failure = const RecommendationFailure('unavailable');
      _showError(_failure!.message(languageCode));
    } finally {
      _requestStarted = false;
    }
  }

  Future<void> _configureNotifications({
    required List<dynamic> entries,
    required String languageCode,
  }) async {
    if (!mounted || AuthService.instance.userId != widget.userId) return;
    var scheduledCount = 0;

    try {
      scheduledCount = await NotificationService.instance
          .replaceCaffeineReminders(
            userId: widget.userId,
            recommendations: entries,
            languageCode: languageCode,
          );
    } catch (error) {
      debugPrint('Caffeine reminder scheduling failed: $error');
    }

    try {
      await NotificationService.instance.showCalculationComplete(
        recommendationCount: entries.length,
        scheduledCount: scheduledCount,
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
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
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
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(l10n.recommendationTitle),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 48).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child:
                            _isLoading
                                ? _buildLoadingWidget(l10n)
                                : _buildMessageWidget(l10n),
                      ),
                    ),
                  ),
                ),
              ),
        ),
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
          onPressed: sendAllDataAndFetchRecommendation,
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
        if (_failure?.code == 'sleep_wake_overlap')
          TextButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => UserInputHistoryPage(
                        userId: widget.userId,
                        selectedDate: widget.selectedDate,
                      ),
                ),
              );
              if (mounted) await sendAllDataAndFetchRecommendation();
            },
            icon: const Icon(Icons.edit_note),
            label: Text(l10n.inputHistory),
          ),
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
