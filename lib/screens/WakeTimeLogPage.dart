import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_app/api/day_record_replacement.dart';
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeSlot {
  final Key key = UniqueKey();
  final TextEditingController startController;
  final TextEditingController endController;

  TimeSlot({String? startTime, String? endTime})
    : startController = TextEditingController(text: startTime),
      endController = TextEditingController(text: endTime);

  Map<String, String> toJson() => {
    'start': startController.text,
    'end': endController.text,
  };

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['start'] as String?,
      endTime: json['end'] as String?,
    );
  }

  void dispose() {
    startController.dispose();
    endController.dispose();
  }
}

class TargetWakeTimePage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const TargetWakeTimePage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<TargetWakeTimePage> createState() => _TargetWakeTimePageState();
}

class _TargetWakeTimePageState extends State<TargetWakeTimePage> {
  final Color _primaryColor = const Color(0xFF4B6B7A);
  final Color _accentColor = const Color(0xFF8BB9A1);
  final Color _bgLight = const Color(0xFFF9F9F7);
  final String baseUrl = 'https://wakemate-api-4-0-qtgs.onrender.com';
  static const int _maxWakeDurationHours = 48;

  final List<TimeSlot> _timeSlots = [];

  String get _targetWakePeriodsKey {
    final dateKey = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    return 'target_wake_periods_${widget.userId}_$dateKey';
  }

  @override
  void initState() {
    super.initState();
    _loadSavedPeriods();
  }

  @override
  void dispose() {
    for (final slot in _timeSlots) {
      slot.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedPeriods() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_targetWakePeriodsKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        if (!mounted) return;
        setState(() {
          _timeSlots.addAll(
            jsonList.whereType<Map<String, dynamic>>().map(
              (item) => TimeSlot.fromJson(item),
            ),
          );
        });
      } catch (_) {
        // Fall through and create a default slot.
      }
    }

    if (mounted && _timeSlots.isEmpty) {
      _addTimeSlot();
    }
  }

  void _addTimeSlot() {
    final selectedDate = widget.selectedDate;
    final defaultStart = DateFormat('yyyy-MM-dd HH:mm').format(
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9),
    );
    final defaultEnd = DateFormat('yyyy-MM-dd HH:mm').format(
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10),
    );

    setState(() {
      _timeSlots.add(TimeSlot(startTime: defaultStart, endTime: defaultEnd));
    });
  }

  void _removeTimeSlot(Key key) {
    setState(() {
      final removed = _timeSlots.where((slot) => slot.key == key).toList();
      _timeSlots.removeWhere((slot) => slot.key == key);
      for (final slot in removed) {
        slot.dispose();
      }
      if (_timeSlots.isEmpty) _addTimeSlot();
    });
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

  String _formatToISO8601(String value) => taipeiInputToUtcIso(value);

  bool get _isZh => AppLocalizations.of(context)!.localeName.startsWith('zh');
  bool get _isId => AppLocalizations.of(context)!.localeName.startsWith('id');

  String get _wakePeriodTooLongMessage {
    if (_isId) {
      return 'Rentang waktu target tetap terjaga tidak boleh lebih dari $_maxWakeDurationHours jam.';
    }
    if (_isZh) {
      return '目標清醒時段不可超過 $_maxWakeDurationHours 小時。';
    }
    return 'Target wake period cannot be longer than $_maxWakeDurationHours hours.';
  }

  Future<void> _saveData() async {
    final l10n = AppLocalizations.of(context)!;

    if (_timeSlots.any(
      (slot) =>
          slot.startController.text.trim().isEmpty ||
          slot.endController.text.trim().isEmpty,
    )) {
      _showSnackBar(l10n.invalidDateTimeFormat);
      return;
    }

    for (final slot in _timeSlots) {
      final start = _parseInputDateTime(slot.startController.text);
      final end = _parseInputDateTime(slot.endController.text);

      if (start == null || end == null) {
        _showSnackBar(l10n.invalidDateTimeFormat);
        return;
      }
      if (!end.isAfter(start)) {
        _showSnackBar(l10n.endAfterStart);
        return;
      }
      if (end.difference(start).inMinutes > _maxWakeDurationHours * 60) {
        _showSnackBar(_wakePeriodTooLongMessage);
        return;
      }
    }

    var cleanupFailed = false;
    try {
      await deleteExistingDayRecords(
        baseUrl: baseUrl,
        endpoint: 'users_wake',
        userId: widget.userId,
        selectedDate: widget.selectedDate,
        dateField: 'target_start_time',
      );
    } catch (_) {
      cleanupFailed = true;
    }

    var successfulSubmissions = 0;
    final headers = {'Content-Type': 'application/json'};

    for (final slot in _timeSlots) {
      try {
        final payload = {
          'user_id': widget.userId,
          'target_start_time': _formatToISO8601(slot.startController.text),
          'target_end_time': _formatToISO8601(slot.endController.text),
        };

        final response = await http
            .post(
              Uri.parse('$baseUrl/users_wake/'),
              headers: headers,
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          successfulSubmissions++;
        } else {
          final body =
              response.body.isEmpty
                  ? ''
                  : '\n${utf8.decode(response.bodyBytes)}';
          _showSnackBar('${l10n.wakeSaveFailed}: ${response.statusCode}$body');
        }
      } catch (e) {
        _showSnackBar('${l10n.networkError}: $e');
      }
    }

    if (successfulSubmissions == _timeSlots.length) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _targetWakePeriodsKey,
        jsonEncode(_timeSlots.map((slot) => slot.toJson()).toList()),
      );

      _showSnackBar(
        cleanupFailed
            ? '${l10n.wakeSaveSuccess}\n${l10n.deleteOldRecordsWarning}'
            : l10n.wakeSaveSuccess,
        color: _accentColor,
      );
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    if (successfulSubmissions > 0) {
      _showSnackBar(l10n.wakeSavePartial, color: Colors.orange);
    } else {
      _showSnackBar(l10n.wakeSaveFailed);
    }
  }

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

  Widget _buildDateTimeField({
    required TextEditingController controller,
    required String label,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        helperText: l10n.dateTimeHelper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(Icons.access_time, color: _primaryColor),
        suffixIcon: IconButton(
          tooltip: l10n.chooseDateTime,
          icon: const Icon(Icons.calendar_month_outlined),
          onPressed: () => _pickDateTime(controller),
        ),
      ),
    );
  }

  Widget _buildTimeSlot(TimeSlot slot) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      key: slot.key,
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.wakeSlot} #${_timeSlots.indexOf(slot) + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              if (_timeSlots.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _removeTimeSlot(slot.key),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDateTimeField(
            controller: slot.startController,
            label: l10n.startTime,
          ),
          const SizedBox(height: 16),
          _buildDateTimeField(
            controller: slot.endController,
            label: l10n.endTime,
          ),
          const Divider(height: 25, color: Colors.grey),
        ],
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
          l10n.wakePageTitle,
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
                l10n.wakeInstruction,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ..._timeSlots.map(_buildTimeSlot),
              OutlinedButton.icon(
                onPressed: _addTimeSlot,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accentColor,
                  side: BorderSide(color: _accentColor, width: 2),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(
                  l10n.addWakeSlot,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(
                    l10n.saveWakeSlots,
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
