import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';

class UserHistoryData {
  final List<Map<String, dynamic>> wakePeriods;
  final List<Map<String, dynamic>> sleepCycles;
  final List<Map<String, dynamic>> caffeineIntakes;

  UserHistoryData({
    required this.wakePeriods,
    required this.sleepCycles,
    required this.caffeineIntakes,
  });

  bool get isEmpty =>
      wakePeriods.isEmpty && sleepCycles.isEmpty && caffeineIntakes.isEmpty;
}

class UserInputHistoryPage extends StatefulWidget {
  final String userId;
  final DateTime selectedDate;

  const UserInputHistoryPage({
    super.key,
    required this.userId,
    required this.selectedDate,
  });

  @override
  State<UserInputHistoryPage> createState() => _UserInputHistoryPageState();
}

class _UserInputHistoryPageState extends State<UserInputHistoryPage> {
  final Color _primaryColor = const Color(0xFF1F3D5B);
  final Color _accentColor = const Color(0xFF5E91B3);
  final Color _backgroundColor = const Color(0xFFF0F2F5);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF424242);
  final String baseUrl = 'https://wakemate-api-4-0-qtgs.onrender.com';
  static const int _maxSingleCaffeineMg = 500;
  static const int _maxRecordDurationHours = 48;

  late Future<UserHistoryData> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  void _refreshHistory() {
    _userDataFuture = _fetchUserInputHistory();
  }

  void _refreshHistoryWithSetState() {
    if (!mounted) return;
    setState(_refreshHistory);
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

  bool get _isZh => AppLocalizations.of(context)!.localeName.startsWith('zh');
  bool get _isId => AppLocalizations.of(context)!.localeName.startsWith('id');

  String get _caffeineOutOfRangeMessage {
    if (_isId) {
      return 'Jumlah kafein per catatan harus 1-$_maxSingleCaffeineMg mg. Jika memang lebih tinggi, pisahkan menjadi beberapa catatan atau periksa kembali input.';
    }
    if (_isZh) {
      return '單筆咖啡因含量需介於 1-$_maxSingleCaffeineMg mg；若真的超過，請拆成多筆或確認是否輸入錯誤。';
    }
    return 'Caffeine amount must be 1-$_maxSingleCaffeineMg mg per entry. If it is higher, split it into multiple records or check the input.';
  }

  String get _recordTooLongMessage {
    if (_isId) {
      return 'Rentang waktu tidak boleh lebih dari $_maxRecordDurationHours jam.';
    }
    if (_isZh) {
      return '時間長度不可超過 $_maxRecordDurationHours 小時。';
    }
    return 'Time range cannot be longer than $_maxRecordDurationHours hours.';
  }

  DateTime? _parseAndLocalize(String? datetimeStr) {
    return apiTimestampToTaipei(datetimeStr);
  }

  DateTime? _parseInputDateTime(String value) {
    try {
      return parseTaipeiInput(value);
    } catch (_) {
      return null;
    }
  }

  String _formatForInput(DateTime? value) {
    if (value == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(value);
  }

  String _formatToApiTimestamp(String value) {
    return taipeiInputToUtcIso(value);
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

  Future<List<Map<String, dynamic>>> _fetchData(String endpoint) async {
    final url = '$baseUrl/$endpoint/?user_id=${widget.userId}';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return [];

    final decoded = json.decode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return [];

    return decoded.whereType<Map>().map((item) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
  }

  int _compareByDateDesc(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    String field,
  ) {
    final aTime = _parseAndLocalize(a[field]?.toString());
    final bTime = _parseAndLocalize(b[field]?.toString());
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return bTime.compareTo(aTime);
  }

  Future<UserHistoryData> _fetchUserInputHistory() async {
    final rawResults = await Future.wait<List<Map<String, dynamic>>>([
      _fetchData('users_wake').catchError((_) => <Map<String, dynamic>>[]),
      _fetchData('users_sleep').catchError((_) => <Map<String, dynamic>>[]),
      _fetchData('users_intake').catchError((_) => <Map<String, dynamic>>[]),
    ]);

    final wakePeriods =
        rawResults[0]
          ..sort((a, b) => _compareByDateDesc(a, b, 'target_start_time'));
    final sleepCycles =
        rawResults[1]
          ..sort((a, b) => _compareByDateDesc(a, b, 'sleep_end_time'));
    final caffeineIntakes =
        rawResults[2]
          ..sort((a, b) => _compareByDateDesc(a, b, 'taking_timestamp'));

    return UserHistoryData(
      wakePeriods: wakePeriods,
      sleepCycles: sleepCycles,
      caffeineIntakes: caffeineIntakes,
    );
  }

  Future<bool> _updateEntry({
    required String endpoint,
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/$endpoint/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _showSnackBar(l10n.updated, color: _accentColor);
        _refreshHistoryWithSetState();
        return true;
      }

      _showSnackBar('${l10n.updateFailed}: ${response.statusCode}');
      return false;
    } catch (e) {
      _showSnackBar('${l10n.updateFailed}: $e');
      return false;
    }
  }

  Future<void> _deleteEntry({required String endpoint, required int id}) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.confirmDelete),
            content: Text(l10n.deleteConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/$endpoint/$id'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _showSnackBar(l10n.deleted, color: _accentColor);
        _refreshHistoryWithSetState();
      } else {
        _showSnackBar('${l10n.deleteFailed}: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('${l10n.deleteFailed}: $e');
    }
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
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: l10n.chooseDateTime,
          icon: const Icon(Icons.calendar_month_outlined),
          onPressed: () => _pickDateTime(controller),
        ),
      ),
    );
  }

  Future<void> _showSleepEditDialog(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final id = item['id'] as int?;
    if (id == null) return;

    final startController = TextEditingController(
      text: _formatForInput(
        _parseAndLocalize(item['sleep_start_time'] as String?),
      ),
    );
    final endController = TextEditingController(
      text: _formatForInput(
        _parseAndLocalize(item['sleep_end_time'] as String?),
      ),
    );

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('${l10n.edit} ${l10n.actualSleepPeriod}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDateTimeField(
                    controller: startController,
                    label: l10n.startTime,
                  ),
                  const SizedBox(height: 16),
                  _buildDateTimeField(
                    controller: endController,
                    label: l10n.endTime,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final start = _parseInputDateTime(startController.text);
                  final end = _parseInputDateTime(endController.text);
                  if (start == null || end == null) {
                    _showSnackBar(l10n.invalidDateTimeFormat);
                    return;
                  }
                  if (!end.isAfter(start)) {
                    _showSnackBar(l10n.endAfterStart);
                    return;
                  }
                  if (end.difference(start).inMinutes >
                      _maxRecordDurationHours * 60) {
                    _showSnackBar(_recordTooLongMessage);
                    return;
                  }

                  Navigator.pop(dialogContext);
                  await _updateEntry(
                    endpoint: 'users_sleep',
                    id: id,
                    payload: {
                      'sleep_start_time': _formatToApiTimestamp(
                        startController.text,
                      ),
                      'sleep_end_time': _formatToApiTimestamp(
                        endController.text,
                      ),
                    },
                  );
                },
                child: Text(l10n.save),
              ),
            ],
          ),
    );

    startController.dispose();
    endController.dispose();
  }

  Future<void> _showWakeEditDialog(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final id = item['id'] as int?;
    if (id == null) return;

    final startController = TextEditingController(
      text: _formatForInput(
        _parseAndLocalize(item['target_start_time'] as String?),
      ),
    );
    final endController = TextEditingController(
      text: _formatForInput(
        _parseAndLocalize(item['target_end_time'] as String?),
      ),
    );

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('${l10n.edit} ${l10n.targetWakePeriod}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDateTimeField(
                    controller: startController,
                    label: l10n.startTime,
                  ),
                  const SizedBox(height: 16),
                  _buildDateTimeField(
                    controller: endController,
                    label: l10n.endTime,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final start = _parseInputDateTime(startController.text);
                  final end = _parseInputDateTime(endController.text);
                  if (start == null || end == null) {
                    _showSnackBar(l10n.invalidDateTimeFormat);
                    return;
                  }
                  if (!end.isAfter(start)) {
                    _showSnackBar(l10n.endAfterStart);
                    return;
                  }
                  if (end.difference(start).inMinutes >
                      _maxRecordDurationHours * 60) {
                    _showSnackBar(_recordTooLongMessage);
                    return;
                  }

                  Navigator.pop(dialogContext);
                  await _updateEntry(
                    endpoint: 'users_wake',
                    id: id,
                    payload: {
                      'target_start_time': _formatToApiTimestamp(
                        startController.text,
                      ),
                      'target_end_time': _formatToApiTimestamp(
                        endController.text,
                      ),
                    },
                  );
                },
                child: Text(l10n.save),
              ),
            ],
          ),
    );

    startController.dispose();
    endController.dispose();
  }

  Future<void> _showIntakeEditDialog(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final id = item['id'] as int?;
    if (id == null) return;

    final timeController = TextEditingController(
      text: _formatForInput(
        _parseAndLocalize(item['taking_timestamp'] as String?),
      ),
    );
    final nameController = TextEditingController(
      text: (item['drink_name'] ?? '').toString(),
    );
    final amountController = TextEditingController(
      text: (item['caffeine_amount'] ?? '').toString(),
    );

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('${l10n.edit} ${l10n.caffeineLog}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.drinkName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.caffeineAmountMg,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDateTimeField(
                    controller: timeController,
                    label: l10n.drinkingTime,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = int.tryParse(amountController.text.trim());
                  final time = _parseInputDateTime(timeController.text);
                  if (nameController.text.trim().isEmpty) return;
                  if (amount == null || amount <= 0) return;
                  if (amount > _maxSingleCaffeineMg) {
                    _showSnackBar(_caffeineOutOfRangeMessage);
                    return;
                  }
                  if (time == null) {
                    _showSnackBar(l10n.invalidDateTimeFormat);
                    return;
                  }

                  Navigator.pop(dialogContext);
                  await _updateEntry(
                    endpoint: 'users_intake',
                    id: id,
                    payload: {
                      'drink_name': nameController.text.trim(),
                      'caffeine_amount': amount,
                      'taking_timestamp': _formatToApiTimestamp(
                        timeController.text,
                      ),
                    },
                  );
                },
                child: Text(l10n.save),
              ),
            ],
          ),
    );

    timeController.dispose();
    nameController.dispose();
    amountController.dispose();
  }

  Widget _buildDataRow({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(
              '$title:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textColor.withValues(alpha: 0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: TextStyle(fontSize: 14, color: _textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l10n.edit),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> dataList,
    required String isEmptyMessage,
    required Widget Function(Map<String, dynamic> item) buildItem,
  }) {
    return Card(
      color: _cardColor,
      elevation: 2,
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _primaryColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            if (dataList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  isEmptyMessage,
                  style: TextStyle(color: _textColor.withValues(alpha: 0.5)),
                ),
              )
            else
              ...dataList.map(buildItem),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySection(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 80, color: _accentColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSleepItem(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final start = _parseAndLocalize(item['sleep_start_time'] as String?);
    final end = _parseAndLocalize(item['sleep_end_time'] as String?);
    if (start == null || end == null) return const SizedBox.shrink();

    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final id = item['id'] as int?;

    return _buildEntryContainer(
      children: [
        _buildDataRow(
          icon: Icons.arrow_right_alt,
          title: l10n.startTime,
          content: DateFormat('yyyy/MM/dd HH:mm').format(start),
          iconColor: _accentColor,
        ),
        _buildDataRow(
          icon: Icons.arrow_right_alt,
          title: l10n.endTime,
          content: DateFormat('yyyy/MM/dd HH:mm').format(end),
          iconColor: _accentColor,
        ),
        _buildDataRow(
          icon: Icons.timer,
          title: l10n.duration,
          content: '$hours ${l10n.hours} $minutes ${l10n.minutes}',
          iconColor: _accentColor,
        ),
        if (id != null)
          _buildActions(
            onEdit: () => _showSleepEditDialog(item),
            onDelete: () => _deleteEntry(endpoint: 'users_sleep', id: id),
          ),
      ],
    );
  }

  Widget _buildWakeItem(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final start = _parseAndLocalize(item['target_start_time'] as String?);
    final end = _parseAndLocalize(item['target_end_time'] as String?);
    if (start == null || end == null) return const SizedBox.shrink();

    final id = item['id'] as int?;

    return _buildEntryContainer(
      children: [
        _buildDataRow(
          icon: Icons.wb_sunny_outlined,
          title: l10n.startTime,
          content: DateFormat('yyyy/MM/dd HH:mm').format(start),
          iconColor: _accentColor,
        ),
        _buildDataRow(
          icon: Icons.wb_sunny_outlined,
          title: l10n.endTime,
          content: DateFormat('yyyy/MM/dd HH:mm').format(end),
          iconColor: _accentColor,
        ),
        if (id != null)
          _buildActions(
            onEdit: () => _showWakeEditDialog(item),
            onDelete: () => _deleteEntry(endpoint: 'users_wake', id: id),
          ),
      ],
    );
  }

  Widget _buildIntakeItem(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final time = _parseAndLocalize(item['taking_timestamp'] as String?);
    if (time == null) return const SizedBox.shrink();

    final amount = item['caffeine_amount'] ?? 'N/A';
    final name = item['drink_name'] ?? '';
    final id = item['id'] as int?;

    return _buildEntryContainer(
      children: [
        _buildDataRow(
          icon: Icons.schedule,
          title: l10n.drinkingTime,
          content: DateFormat('yyyy/MM/dd HH:mm').format(time),
          iconColor: _accentColor,
        ),
        _buildDataRow(
          icon: Icons.local_cafe_outlined,
          title: l10n.drinkName,
          content: '$name ($amount mg)',
          iconColor: _accentColor,
        ),
        if (id != null)
          _buildActions(
            onEdit: () => _showIntakeEditDialog(item),
            onDelete: () => _deleteEntry(endpoint: 'users_intake', id: id),
          ),
      ],
    );
  }

  Widget _buildEntryContainer({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.18)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.allInputHistory,
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
      body: FutureBuilder<UserHistoryData>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    l10n.historyLoading,
                    style: TextStyle(color: _textColor),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: _buildEmptySection(
                Icons.error_outline,
                '${l10n.networkError}\n${snapshot.error}',
              ),
            );
          }

          final userData = snapshot.data;
          if (userData == null || userData.isEmpty) {
            return Center(
              child: _buildEmptySection(
                Icons.sentiment_dissatisfied,
                l10n.noInputRecords,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                l10n.allInputHistorySubtitle,
                style: TextStyle(
                  color: _textColor.withValues(alpha: 0.65),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              _buildSectionTitle(Icons.person_pin_outlined, l10n.inputHistory),
              _buildInputCard(
                title: l10n.actualSleepPeriod,
                icon: Icons.bedtime_outlined,
                dataList: userData.sleepCycles,
                isEmptyMessage: l10n.noSleepRecords,
                buildItem: _buildSleepItem,
              ),
              _buildInputCard(
                title: l10n.targetWakePeriod,
                icon: Icons.access_time_filled,
                dataList: userData.wakePeriods,
                isEmptyMessage: l10n.noWakeRecords,
                buildItem: _buildWakeItem,
              ),
              _buildInputCard(
                title: l10n.caffeineLog,
                icon: Icons.local_cafe_outlined,
                dataList: userData.caffeineIntakes,
                isEmptyMessage: l10n.noCaffeineRecords,
                buildItem: _buildIntakeItem,
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}
