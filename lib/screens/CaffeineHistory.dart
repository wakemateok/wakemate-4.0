import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'CaffeineRecommendationPage.dart';

class CaffeineHistoryPage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const CaffeineHistoryPage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<CaffeineHistoryPage> createState() => _CaffeineHistoryPageState();
}

class _CaffeineHistoryPageState extends State<CaffeineHistoryPage> {
  final Color _primaryColor = const Color(0xFF1F3D5B);
  final Color _accentColor = const Color(0xFF5E91B3);
  final Color _backgroundColor = const Color(0xFFF0F2F5);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF424242);

  List<dynamic> _allData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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
    } catch (_) {
      if (mounted) {
        setState(() {
          _allData = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _clearDataForSelectedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('caffeine_recommendations') ?? '[]';
    List<dynamic> data = dataStr.isNotEmpty ? jsonDecode(dataStr) : [];

    final selectedDateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(widget.selectedDate);

    data =
        data.where((item) {
          final timingStr =
              item['recommended_caffeine_intake_timing']?.toString() ?? '';
          if (timingStr.isEmpty) return true;
          final localDateTime = _parseAndLocalize(timingStr);
          if (localDateTime == null) return true;
          return DateFormat('yyyy-MM-dd').format(localDateTime) !=
              selectedDateStr;
        }).toList();

    await prefs.setString('caffeine_recommendations', jsonEncode(data));

    if (mounted) {
      setState(() => _allData = data);
    }
  }

  DateTime? _parseAndLocalize(String? datetimeStr) {
    return apiTimestampToTaipei(datetimeStr);
  }

  List<dynamic> _filterSelectedDateData() {
    if (_allData.isEmpty) return [];

    final selectedDateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(widget.selectedDate);

    final filtered =
        _allData.where((item) {
          final timingStr =
              item['recommended_caffeine_intake_timing']?.toString() ?? '';
          if (timingStr.isEmpty) return false;

          final localDateTime = _parseAndLocalize(timingStr);
          if (localDateTime == null) return false;

          return DateFormat('yyyy-MM-dd').format(localDateTime) ==
              selectedDateStr;
        }).toList();

    filtered.sort((a, b) {
      final aTime = _parseAndLocalize(
        a['recommended_caffeine_intake_timing']?.toString(),
      );
      final bTime = _parseAndLocalize(
        b['recommended_caffeine_intake_timing']?.toString(),
      );
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });

    return filtered;
  }

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
            "$title: $content",
            style: TextStyle(fontSize: 16, color: _textColor),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final historyForSelectedDate = _filterSelectedDateData();
    final hasHistory = historyForSelectedDate.isNotEmpty;
    final formattedDate = DateFormat('yyyy/MM/dd').format(widget.selectedDate);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          '${l10n.recommendationHistory} $formattedDate',
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
                padding: const EdgeInsets.all(16),
                itemCount: historyForSelectedDate.length,
                itemBuilder: (context, index) {
                  final item = historyForSelectedDate[index];
                  final recommendedTimingStr =
                      item['recommended_caffeine_intake_timing']?.toString() ??
                      '';
                  final recommendedAmount =
                      item['recommended_caffeine_amount'] ?? 'N/A';

                  final localDateTime = _parseAndLocalize(recommendedTimingStr);
                  final formattedTime =
                      localDateTime != null
                          ? DateFormat('HH:mm').format(localDateTime)
                          : 'N/A';

                  return Card(
                    color: _cardColor,
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.recommendationItem} #${index + 1}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDataRow(
                            icon: Icons.access_time_filled,
                            title: l10n.recommendedTiming,
                            content: formattedTime,
                          ),
                          const SizedBox(height: 12),
                          _buildDataRow(
                            icon: Icons.local_cafe,
                            title: l10n.recommendedAmount,
                            content: '$recommendedAmount mg',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
              : Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.coffee_outlined,
                        size: 80,
                        color: _accentColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.noRecommendationsForDate,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _textColor.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noRecommendationBody,
                        style: TextStyle(
                          fontSize: 16,
                          color: _textColor.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await _clearDataForSelectedDate();
                          if (!mounted) return;
                          await navigator.push(
                            MaterialPageRoute(
                              builder:
                                  (context) => CaffeineRecommendationPage(
                                    userId: widget.userId,
                                    selectedDate: widget.selectedDate,
                                  ),
                            ),
                          );
                          if (mounted) await _loadData();
                        },
                        icon: const Icon(Icons.auto_graph),
                        label: Text(l10n.calculateAgain),
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
