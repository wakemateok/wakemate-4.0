import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/services/notification_service.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key, this.notifications});
  final NotificationService? notifications;

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage>
    with WidgetsBindingObserver {
  final Color _primaryColor = const Color(0xFF1F3D5B);
  final Color _accentColor = const Color(0xFF4DB6AC);
  final Color _bgLight = const Color(0xFFF7F9FC);

  List<WakeMateNotificationLogEntry> _records = [];
  int? _pendingReminderCount;
  bool _isLoading = true;
  bool _isSendingTest = false;
  bool _isSchedulingTest = false;
  bool _isRequestingExact = false;
  int _loadGeneration = 0;
  NotificationReadiness _readiness = const NotificationReadiness();
  String? _loadError;
  NotificationService get _notifications =>
      widget.notifications ?? NotificationService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecords();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadRecords();
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
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _pendingReminderCount = null;
      });
    }
    List<WakeMateNotificationLogEntry> records = [];
    int? pendingReminderCount;
    var readiness = const NotificationReadiness();
    Object? failure;
    try {
      await _notifications.reconcileVisibleNotifications();
      if (!mounted) return;
      readiness = await _notifications.notificationReadiness(
        languageCode: Localizations.localeOf(context).languageCode,
      );
    } catch (error) {
      failure = error;
    }
    try {
      records = await _notifications.loadNotificationHistory();
    } catch (error) {
      failure = error;
    }
    try {
      pendingReminderCount =
          await _notifications.pendingCaffeineReminderCount();
    } catch (error) {
      failure ??= error;
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _records = records;
      _pendingReminderCount = pendingReminderCount;
      _readiness = readiness;
      _isLoading = false;
      _loadError = failure == null ? null : _notificationFailure(failure);
    });
  }

  String _notificationFailure(Object error) {
    var code =
        error is PlatformException
            ? error.code
            : error is MissingPluginException
            ? 'notification_plugin_missing'
            : 'notification_state_unavailable';
    if (!RegExp(r'^[a-zA-Z0-9_\-]{1,64}$').hasMatch(code)) {
      code = 'notification_error';
    }
    if (code == 'invalid_icon') {
      return _text(
        zh: '通知元件初始化失敗（invalid_icon）。請更新 App 後重新開啟並重試。',
        en:
            'Notification initialization failed (invalid_icon). Update the app, reopen it and retry.',
        id:
            'Inisialisasi notifikasi gagal (invalid_icon). Perbarui aplikasi, buka kembali, lalu coba lagi.',
      );
    }
    return _text(
      zh: '通知功能尚未確認，請重新整理；若仍失敗，請回報此畫面。錯誤代碼：$code',
      en:
          'Notification status is unconfirmed. Refresh and report this screen if it still fails. Error code: $code',
      id:
          'Status notifikasi belum dikonfirmasi. Muat ulang dan laporkan layar ini jika masih gagal. Kode kesalahan: $code',
    );
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isSendingTest = true);

    final languageCode = Localizations.localeOf(context).languageCode;
    var message = '';
    try {
      final sent = await _notifications.showTestNotification(
        languageCode: languageCode,
      );
      if (!mounted) return;
      message =
          sent
              ? _text(
                zh: '已交給手機系統發送，請確認通知列是否出現。',
                en:
                    'Submitted to the phone system. Please check the notification tray.',
                id: 'Dikirim ke sistem ponsel. Periksa bilah notifikasi.',
              )
              : _text(
                zh: '此裝置不支援 App 內通知測試',
                en: 'Notification test is not supported on this device.',
                id: 'Tes notifikasi tidak didukung di perangkat ini.',
              );
    } on NotificationPermissionException {
      if (!mounted) return;
      message = _text(
        zh: '通知未開啟。請到手機「設定 → 應用程式 → WakeMate → 通知」允許通知後重試。',
        en:
            'Notifications are disabled. Allow notifications in phone Settings > Apps > WakeMate > Notifications, then try again.',
        id:
            'Notifikasi dinonaktifkan. Izinkan melalui Setelan > Aplikasi > WakeMate > Notifikasi, lalu coba lagi.',
      );
    } catch (error) {
      if (!mounted) return;
      message = _notificationFailure(error);
    } finally {
      if (mounted) setState(() => _isSendingTest = false);
    }
    await _loadRecords();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _clearRecords() async {
    await _notifications.clearNotificationHistory();
    await _loadRecords();
  }

  Future<void> _scheduleTest() async {
    setState(() => _isSchedulingTest = true);
    String message;
    try {
      final precision = await _notifications.scheduleOneMinuteTest(
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      message = switch (precision) {
        ReminderSchedulePrecision.exact => _text(
          zh: '已設定一分鐘後的測試提醒。請回到手機桌面或鎖屏後等待，並確認通知欄。',
          en:
              'Test scheduled for one minute from now. Go to the home screen or lock the phone, then check the notification tray.',
          id:
              'Tes dijadwalkan satu menit lagi. Kembali ke layar utama atau kunci ponsel, lalu periksa bilah notifikasi.',
        ),
        ReminderSchedulePrecision.inexact => _text(
          zh: '已設定測試，但目前不是準時排程，可能延遲。請先開啟準時提醒權限。',
          en:
              'Test scheduled with possible delay. Enable exact reminder permission first.',
          id:
              'Tes dijadwalkan tetapi bisa terlambat. Aktifkan izin pengingat tepat waktu terlebih dahulu.',
        ),
        null => _text(
          zh: '定時測試排程失敗，請回報此畫面。',
          en: 'Scheduled test failed. Please report this screen.',
          id: 'Tes terjadwal gagal. Laporkan layar ini.',
        ),
      };
    } on NotificationPermissionException {
      if (!mounted) return;
      message = _text(
        zh: '請先到手機設定開啟 WakeMate 通知。',
        en: 'Enable WakeMate notifications in phone settings first.',
        id: 'Aktifkan notifikasi WakeMate di setelan ponsel terlebih dahulu.',
      );
    } catch (error) {
      if (!mounted) return;
      message = _notificationFailure(error);
    } finally {
      if (mounted) setState(() => _isSchedulingTest = false);
    }
    await _loadRecords();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestExact() async {
    setState(() => _isRequestingExact = true);
    String message;
    try {
      final allowed = await _notifications.requestExactReminderPermission(
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      message =
          allowed
              ? _text(
                zh: '已允許準時排程，尚未到期的提醒已重新嘗試排程。請再執行一分鐘測試。',
                en:
                    'Exact scheduling allowed. Future reminders were retried. Run the one-minute test again.',
                id:
                    'Penjadwalan tepat waktu diizinkan. Pengingat mendatang dijadwalkan ulang. Jalankan tes satu menit lagi.',
              )
              : _text(
                zh: '尚未允許準時排程，提醒可能延遲。',
                en: 'Exact scheduling is not allowed; reminders may be delayed.',
                id:
                    'Penjadwalan tepat waktu belum diizinkan; pengingat bisa terlambat.',
              );
    } catch (error) {
      if (!mounted) return;
      message = _notificationFailure(error);
    } finally {
      if (mounted) setState(() => _isRequestingExact = false);
    }
    await _loadRecords();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _permissionValue(bool? value) =>
      value == null
          ? _text(zh: '未確認', en: 'Unknown', id: 'Belum dikonfirmasi')
          : value
          ? _text(zh: '已允許', en: 'Allowed', id: 'Diizinkan')
          : _text(zh: '未允許', en: 'Not allowed', id: 'Tidak diizinkan');

  Widget _buildReadiness() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${_text(zh: '手機通知權限', en: 'Notification permission', id: 'Izin notifikasi')}: ${_permissionValue(_readiness.notificationsEnabled)}',
      ),
      const SizedBox(height: 6),
      if (_readiness.caffeineChannelEnabled != null) ...[
        Text(
          '${_text(zh: '咖啡因通知分類', en: 'Caffeine notification channel', id: 'Kategori notifikasi kafein')}: ${_permissionValue(_readiness.caffeineChannelEnabled)}',
          style: TextStyle(
            color:
                _readiness.caffeineChannelEnabled == false
                    ? Colors.deepOrange
                    : null,
          ),
        ),
        const SizedBox(height: 6),
      ],
      Text(
        '${_text(zh: '準時提醒權限', en: 'Exact reminder permission', id: 'Izin pengingat tepat waktu')}: ${_permissionValue(_readiness.exactAlarmsAllowed)}',
        style: TextStyle(
          color:
              _readiness.exactAlarmsAllowed == false ? Colors.deepOrange : null,
        ),
      ),
      if (_readiness.exactAlarmsAllowed != true)
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            style: _diagnosticButtonStyle(),
            key: const ValueKey('enable-exact-reminders'),
            onPressed: _isRequestingExact ? null : _requestExact,
            icon: const Icon(Icons.alarm_on),
            label: Text(
              _text(
                zh: '開啟準時提醒',
                en: 'Enable exact reminders',
                id: 'Aktifkan pengingat tepat waktu',
              ),
            ),
          ),
        ),
      OutlinedButton.icon(
        style: _diagnosticButtonStyle(),
        key: const ValueKey('schedule-one-minute-test'),
        onPressed: _isSchedulingTest ? null : _scheduleTest,
        icon: const Icon(Icons.timer_outlined),
        label: Text(
          _text(
            zh: '一分鐘後提醒測試',
            en: 'Test reminder in one minute',
            id: 'Tes pengingat satu menit lagi',
          ),
        ),
      ),
    ],
  );

  ButtonStyle _diagnosticButtonStyle() => OutlinedButton.styleFrom(
    foregroundColor: _primaryColor,
    side: BorderSide(color: _primaryColor.withValues(alpha: 0.5)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  String _formatDateTime(DateTime value) {
    return DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(apiTimestampToTaipei(value.toUtc().toIso8601String())!);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sent':
        return _text(zh: '已送出', en: 'Sent', id: 'Terkirim');
      case 'posted':
        return _text(
          zh: '通知列已確認',
          en: 'Confirmed in notification tray',
          id: 'Dikonfirmasi di bilah notifikasi',
        );
      case 'scheduled':
        return _text(zh: '已排程', en: 'Scheduled', id: 'Terjadwal');
      case 'scheduled_inexact':
        return _text(
          zh: '已排程・可能延遲',
          en: 'Scheduled - may be delayed',
          id: 'Terjadwal - bisa terlambat',
        );
      case 'skipped_past':
        return _text(zh: '已過期', en: 'Past', id: 'Lewat');
      case 'schedule_failed':
        return _text(zh: '排程失敗', en: 'Failed', id: 'Gagal');
      case 'cancelled':
        return _text(zh: '已取消', en: 'Cancelled', id: 'Dibatalkan');
      case 'due_unconfirmed':
        return _text(
          zh: '時間已到・未確認送達',
          en: 'Due - delivery unconfirmed',
          id: 'Jatuh tempo - pengiriman belum dikonfirmasi',
        );
      default:
        return status;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'test':
        return _text(zh: '測試通知', en: 'Test Notification', id: 'Tes Notifikasi');
      case 'scheduled_test':
        return _text(
          zh: '定時通知測試',
          en: 'Scheduled notification test',
          id: 'Tes notifikasi terjadwal',
        );
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
      case 'posted':
        return _accentColor;
      case 'scheduled':
      case 'scheduled_inexact':
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
    final status =
        ['scheduled', 'scheduled_inexact'].contains(record.status) &&
                record.scheduledAt != null &&
                !record.scheduledAt!.isAfter(DateTime.now())
            ? 'due_unconfirmed'
            : record.status;
    final statusColor = _statusColor(status);

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
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
              if (_loadError != null)
                Text(_loadError!, style: const TextStyle(color: Colors.red)),
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
                          zh: 'App 登記的待發送咖啡因提醒',
                          en: 'Registered pending caffeine reminders',
                          id: 'Pengingat kafein tertunda yang terdaftar',
                        ),
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _pendingReminderCount?.toString() ?? '?',
                      key: const ValueKey('pending-reminder-count'),
                      semanticsLabel:
                          _pendingReminderCount == null
                              ? _text(
                                zh: '提醒數量未知',
                                en: 'Reminder count unknown',
                                id: 'Jumlah pengingat tidak diketahui',
                              )
                              : null,
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
              _buildReadiness(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_records.isEmpty && _loadError == null)
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
