import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_app/services/notification_service.dart';

class NotificationPermissionGate extends StatefulWidget {
  const NotificationPermissionGate({
    super.key,
    required this.child,
    this.notifications,
  });
  final Widget child;
  final NotificationService? notifications;
  @override
  State<NotificationPermissionGate> createState() =>
      _NotificationPermissionGateState();
}

class _NotificationPermissionGateState
    extends State<NotificationPermissionGate> {
  bool _started = false;
  bool _loading = true;
  bool _showSetup = false;
  bool _finishing = false;
  NotificationSetupState? _status;
  bool _failed = false;
  NotificationService get _notifications =>
      widget.notifications ?? NotificationService.instance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load(Localizations.localeOf(context).languageCode);
    }
  }

  Future<void> _load(String language) async {
    if (!await _notifications.shouldOfferPermissionSetup().timeout(
      const Duration(seconds: 3),
      onTimeout: () => true,
    )) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    NotificationSetupState? status;
    var failed = false;
    try {
      status = await _notifications
          .preparePermissionSetup(languageCode: language)
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      failed = true;
    }
    if (!mounted || _finishing) return;
    if (status?.allReady == true) {
      await _finish();
      return;
    }
    setState(() {
      _status = status;
      _failed = failed;
      _loading = false;
      _showSetup = true;
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await _notifications.markPermissionSetupHandled();
    if (mounted) {
      setState(() {
        _loading = false;
        _showSetup = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      final later = switch (Localizations.localeOf(context).languageCode) {
        'en' => 'Later',
        'id' => 'Nanti',
        _ => '稍後設定',
      };
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                TextButton(
                  key: const ValueKey('defer-notification-permissions'),
                  onPressed: _finish,
                  child: Text(later),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_showSetup) return widget.child;
    return NotificationPermissionSetupPage(
      notifications: _notifications,
      initialStatus: _status,
      initialFailure: _failed,
      onComplete: _finish,
    );
  }
}

class NotificationPermissionSetupPage extends StatefulWidget {
  const NotificationPermissionSetupPage({
    super.key,
    required this.notifications,
    required this.onComplete,
    this.initialStatus,
    this.initialFailure = false,
  });
  final NotificationService notifications;
  final Future<void> Function() onComplete;
  final NotificationSetupState? initialStatus;
  final bool initialFailure;
  @override
  State<NotificationPermissionSetupPage> createState() =>
      _NotificationPermissionSetupPageState();
}

class _NotificationPermissionSetupPageState
    extends State<NotificationPermissionSetupPage>
    with WidgetsBindingObserver {
  NotificationSetupState? _status;
  bool _busy = false;
  bool _failed = false;
  int _generation = 0;
  static const _primary = Color(0xFF1F3D5B);

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _failed = widget.initialFailure;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _refresh();
  }

  String _text(String zh, String en, String id) =>
      switch (Localizations.localeOf(context).languageCode) {
        'en' => en,
        'id' => id,
        _ => zh,
      };

  Future<NotificationSetupState> _read() => widget.notifications
      .preparePermissionSetup(
        languageCode: Localizations.localeOf(context).languageCode,
      )
      .timeout(const Duration(seconds: 8));

  Future<void> _refresh() async {
    final generation = ++_generation;
    try {
      final status = await _read();
      if (!mounted || generation != _generation) return;
      setState(() {
        _status = status;
        _failed = false;
      });
      if (status.allReady) await widget.onComplete();
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _failed = true);
    }
  }

  Future<void> _configure() async {
    if (_busy) return;
    ++_generation;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      var status = await _read();
      if (!mounted) return;
      if (!status.notificationsReady) {
        await widget.notifications.requestNotificationAccessForSetup(
          sdk: status.sdk,
        );
        if (!mounted) return;
        status = await _read();
        if (!mounted) return;
        if (!status.notificationsReady) {
          setState(() => _status = status);
          return;
        }
      }
      if (!status.exactReady) {
        await widget.notifications.requestExactReminderPermission(
          languageCode: Localizations.localeOf(context).languageCode,
        );
        if (!mounted) return;
        status = await _read();
        if (!mounted) return;
        if (!status.exactReady) {
          setState(() => _status = status);
          return;
        }
      }
      if (!status.channelReady) {
        await widget.notifications.openCaffeineChannelSettings(
          languageCode: Localizations.localeOf(context).languageCode,
        );
        if (!mounted) return;
        status = await _read();
        if (!mounted) return;
      }
      setState(() => _status = status);
      if (status.allReady) await widget.onComplete();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _permission(
    IconData icon,
    String title,
    bool? allowed, {
    bool notRequired = false,
  }) {
    final label =
        notRequired
            ? _text(
              '此版本不需設定',
              'Not needed on this version',
              'Tidak diperlukan pada versi ini',
            )
            : allowed == null
            ? _text('未確認', 'Unknown', 'Belum dikonfirmasi')
            : allowed
            ? _text('已允許', 'Allowed', 'Diizinkan')
            : _text('待設定', 'Not enabled', 'Belum diaktifkan');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        allowed == true || notRequired
                            ? Colors.teal.shade700
                            : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/brand/wakemate_symbol.png',
                          width: 60,
                          height: 60,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _text(
                          '開啟咖啡因提醒',
                          'Enable caffeine reminders',
                          'Aktifkan pengingat kafein',
                        ),
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _text(
                          '用於推薦完成與飲用時間提醒。您也可以稍後到「通知確認」設定。',
                          'For recommendation-ready and intake-time alerts. You can also set these up later in Notifications.',
                          'Untuk notifikasi hasil rekomendasi dan waktu konsumsi. Anda juga dapat mengaturnya nanti di Notifikasi.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _permission(
                        Icons.notifications_outlined,
                        _text(
                          '手機通知',
                          'Phone notifications',
                          'Notifikasi ponsel',
                        ),
                        _status?.readiness.notificationsEnabled,
                      ),
                      _permission(
                        Icons.alarm_on_outlined,
                        _text(
                          '準時提醒',
                          'Exact reminders',
                          'Pengingat tepat waktu',
                        ),
                        _status?.readiness.exactAlarmsAllowed,
                      ),
                      _permission(
                        Icons.tune,
                        _text(
                          '咖啡因通知分類',
                          'Caffeine notification channel',
                          'Kategori notifikasi kafein',
                        ),
                        _status?.readiness.caffeineChannelEnabled,
                        notRequired: _status != null && _status!.sdk < 26,
                      ),
                      if (_failed)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _text(
                              '暫時無法確認設定，請重試或選擇稍後設定。',
                              'Settings could not be checked. Try again or choose Later.',
                              'Pengaturan belum dapat diperiksa. Coba lagi atau pilih Nanti.',
                            ),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      key: const ValueKey('setup-notification-permissions'),
                      onPressed: _busy ? null : _configure,
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(
                        _text('設定提醒', 'Set up reminders', 'Atur pengingat'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('defer-notification-permissions'),
                      onPressed: widget.onComplete,
                      child: Text(_text('稍後設定', 'Later', 'Nanti')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
