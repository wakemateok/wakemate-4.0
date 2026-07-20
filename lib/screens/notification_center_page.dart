import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/services/notification_service.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final Color _primaryColor = const Color(0xFF1F3D5B);
  final Color _accentColor = const Color(0xFF4DB6AC);
  final Color _bgLight = const Color(0xFFF7F9FC);

  List<WakeMateNotificationLogEntry> _records = [];
  int _pendingReminderCount = 0;
  bool _isLoading = true;
  bool _isSendingTest = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  String _text({required String zh, required String en, required String id}) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'id':
        return id;
      case 'en':
        return en;
      default:
        return zh;
    }
  }

  Future<void> _loadRecords() async {
    final records =
        await NotificationService.instance.loadNotificationHistory();
    final pendingReminderCount =
        await NotificationService.instance.pendingCaffeineReminderCount();
    if (!mounted) return;
    setState(() {
      _records = records;
      _pendingReminderCount = pendingReminderCount;
      _isLoading = false;
    });
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isSendingTest = true);

    final languageCode = Localizations.localeOf(context).languageCode;
    final sent = await NotificationService.instance.showTestNotification(
      languageCode: languageCode,
    );
    await _loadRecords();

    if (!mounted) return;
    setState(() => _isSendingTest = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? _text(
                zh: '已送出測試通知',
                en: 'Test notification sent.',
                id: 'Notifikasi tes terkirim.',
              )
              : _text(
                zh: '此裝置不支援 App 內通知測試',
                en: 'Notification test is not supported on this device.',
                id: 'Tes notifikasi tidak didukung di perangkat ini.',
              ),
        ),
      ),
    );
  }

  Future<void> _clearRecords() async {
    await NotificationService.instance.clearNotificationHistory();
    await _loadRecords();
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sent':
        return _text(zh: '已送出', en: 'Sent', id: 'Terkirim');
      case 'scheduled':
        return _text(zh: '已排程', en: 'Scheduled', id: 'Terjadwal');
      case 'skipped_past':
        return _text(zh: '已過期', en: 'Past', id: 'Lewat');
      case 'schedule_failed':
        return _text(zh: '排程失敗', en: 'Failed', id: 'Gagal');
      default:
        return status;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'test':
        return _text(zh: '測試通知', en: 'Test Notification', id: 'Tes Notifikasi');
      case 'calculation_complete':
        return _text(
          zh: '計算完成',
          en: 'Calculation Complete',
          id: 'Perhitungan Selesai',
        );
      case 'caffeine_reminder':
        return _text(
          zh: '咖啡因提醒',
          en: 'Caffeine Reminder',
          id: 'Pengingat Kafein',
        );
      default:
        return type;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'sent':
        return _accentColor;
      case 'scheduled':
        return const Color(0xFFE9A93A);
      case 'skipped_past':
        return Colors.grey;
      case 'schedule_failed':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecordCard(WakeMateNotificationLogEntry record) {
    final statusColor = _statusColor(record.status);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active_outlined, color: _primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _typeLabel(record.type),
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.title,
                        style: TextStyle(
                          color: _primaryColor.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel(record.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              record.body,
              style: TextStyle(
                color: _primaryColor.withValues(alpha: 0.75),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${_text(zh: '建立時間', en: 'Created', id: 'Dibuat')}: '
              '${_formatDateTime(record.createdAt)}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            if (record.scheduledAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '${_text(zh: '提醒時間', en: 'Reminder Time', id: 'Waktu Pengingat')}: '
                '${_formatDateTime(record.scheduledAt!)}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: Text(
          _text(zh: '通知確認', en: 'Notifications', id: 'Notifikasi'),
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
        elevation: 1,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecords,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSendingTest ? null : _sendTestNotification,
                      icon:
                          _isSendingTest
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.notification_add_outlined),
                      label: Text(
                        _text(zh: '發送測試通知', en: 'Send Test', id: 'Kirim Tes'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: _loadRecords,
                    icon: const Icon(Icons.refresh),
                    tooltip: _text(zh: '重新整理', en: 'Refresh', id: 'Muat ulang'),
                  ),
                  IconButton.filledTonal(
                    onPressed: _records.isEmpty ? null : _clearRecords,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: _text(zh: '清除紀錄', en: 'Clear', id: 'Hapus'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_outlined, color: _accentColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _text(
                          zh: '手機目前實際排程中的咖啡因提醒',
                          en: 'Pending caffeine reminders on this phone',
                          id: 'Pengingat kafein tertunda di ponsel ini',
                        ),
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$_pendingReminderCount',
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_records.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 44),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none_outlined,
                        size: 56,
                        color: _primaryColor.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _text(
                          zh: '目前沒有通知紀錄',
                          en: 'No notification records yet.',
                          id: 'Belum ada catatan notifikasi.',
                        ),
                        style: TextStyle(
                          color: _primaryColor.withValues(alpha: 0.75),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._records.map(_buildRecordCard),
            ],
          ),
        ),
      ),
    );
  }
}
