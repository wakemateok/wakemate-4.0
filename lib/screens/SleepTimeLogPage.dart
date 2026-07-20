import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_app/api/day_record_replacement.dart';
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActualSleepTimePage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const ActualSleepTimePage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<ActualSleepTimePage> createState() => _ActualSleepTimePageState();
}

class _ActualSleepTimePageState extends State<ActualSleepTimePage> {
  final TextEditingController sleepStartController = TextEditingController();
  final TextEditingController sleepEndController = TextEditingController();

  final String baseUrl = 'https://wakemate-api-4-0-qtgs.onrender.com';
  final Color _primaryColor = const Color(0xFF4B6B7A);
  final Color _accentColor = const Color(0xFF8BB9A1);
  final Color _bgLight = const Color(0xFFF9F9F7);
  static const int _maxSleepDurationHours = 48;

  @override
  void initState() {
    super.initState();
    _loadInitialTimes();
  }

  void _loadInitialTimes() {
    final selectedDate = widget.selectedDate;
    sleepStartController.text = DateFormat('yyyy-MM-dd HH:mm').format(
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day - 1, 23),
    );
    sleepEndController.text = DateFormat('yyyy-MM-dd HH:mm').format(
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 7),
    );
  }

  @override
  void dispose() {
    sleepStartController.dispose();
    sleepEndController.dispose();
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

  DateTime? _parseInputDateTime(String value) {
    try {
      return parseTaipeiInput(value);
    } catch (_) {
      return null;
    }
  }

  String _formatToApiTimestamp(String value) => taipeiInputToUtcIso(value);

  Future<void> _pickDateTime(TextEditingController controller) async {
    final initialDateTime =
        _parseInputDateTime(controller.text) ?? widget.selectedDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
    );
    if (pickedTime == null) return;

    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    controller.text = DateFormat('yyyy-MM-dd HH:mm').format(finalDateTime);
  }

  Future<void> _submitData() async {
    final l10n = AppLocalizations.of(context)!;
    final sleepStartTimeText = sleepStartController.text.trim();
    final sleepEndTimeText = sleepEndController.text.trim();

    final dtStart = _parseInputDateTime(sleepStartTimeText);
    final dtEnd = _parseInputDateTime(sleepEndTimeText);

    if (dtStart == null || dtEnd == null) {
      _showSnackBar(l10n.invalidDateTimeFormat);
      return;
    }

    if (!dtEnd.isAfter(dtStart)) {
      _showSnackBar(l10n.endAfterStart);
      return;
    }

    if (dtEnd.difference(dtStart).inMinutes > _maxSleepDurationHours * 60) {
      _showSnackBar(l10n.sleepTooLong);
      return;
    }

    var cleanupFailed = false;
    try {
      await deleteExistingDayRecords(
        baseUrl: baseUrl,
        endpoint: 'users_sleep',
        userId: widget.userId,
        selectedDate: dtEnd,
        dateField: 'sleep_end_time',
      );
    } catch (_) {
      cleanupFailed = true;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users_sleep/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': widget.userId,
              'sleep_start_time': _formatToApiTimestamp(sleepStartTimeText),
              'sleep_end_time': _formatToApiTimestamp(sleepEndTimeText),
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        await _handleSuccessfulSave(dtStart, dtEnd);
        if (cleanupFailed) {
          _showSnackBar(l10n.deleteOldRecordsWarning, color: Colors.orange);
        }
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final body =
            response.body.isEmpty ? '' : '\n${utf8.decode(response.bodyBytes)}';
        _showSnackBar('${l10n.sleepSaveFailed}: ${response.statusCode}$body');
      }
    } catch (e) {
      _showSnackBar('${l10n.networkError}: $e');
    }
  }

  Future<void> _handleSuccessfulSave(DateTime dtStart, DateTime dtEnd) async {
    final l10n = AppLocalizations.of(context)!;
    final duration = dtEnd.difference(dtStart);
    final totalHours = duration.inMinutes / 60.0;
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(dtEnd);
    await prefs.setDouble('sleep_$dateKey', totalHours);

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    _showSnackBar(
      '${l10n.sleepSaveSuccess}\n${l10n.duration}: $hours ${l10n.hours} $minutes ${l10n.minutes}',
      color: _accentColor,
    );
  }

  Widget _buildDateTimeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        helperText: l10n.dateTimeHelper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon, color: _primaryColor),
        suffixIcon: IconButton(
          tooltip: l10n.chooseDateTime,
          icon: const Icon(Icons.calendar_month_outlined),
          onPressed: () => _pickDateTime(controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: Text(
          l10n.sleepPageTitle,
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(color: _primaryColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                l10n.sleepInstruction,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _buildDateTimeField(
                controller: sleepStartController,
                label: l10n.sleepStart,
                icon: Icons.bedtime_outlined,
              ),
              const SizedBox(height: 16),
              _buildDateTimeField(
                controller: sleepEndController,
                label: l10n.sleepEnd,
                icon: Icons.access_time_rounded,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.save),
                  label: Text(
                    l10n.saveSleep,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
