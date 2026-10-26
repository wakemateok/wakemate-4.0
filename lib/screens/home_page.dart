import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:intl/intl.dart';
import 'package:my_app/api/home_data.dart';
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/config/questionnaire_links.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/services/recommendation_invalidation.dart';
import 'package:my_app/utils/recommendation_deduplication.dart';
import 'package:my_app/utils/review_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'CaffeineLogPage.dart';
import 'CaffeineHistory.dart';
import 'SleepTimeLogPage.dart';
import 'UserInputHistoryPage.dart';
import 'WakeTimeLogPage.dart';
import 'alertness_test.dart';
import 'custom_drawer.dart';
import 'drink_match_page.dart';
import 'personalSettingsPage.dart';
import 'feedback_page.dart';
import 'package:my_app/utils/feedback_text.dart';

class HomePage extends StatefulWidget {
  final String userId, userName, email;
  final HomeRepository? repository;
  final bool showQuestionnaireReminder;
  const HomePage({
    super.key,
    required this.userId,
    this.userName = '',
    this.email = '',
    this.repository,
    this.showQuestionnaireReminder = true,
  });
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late DateTime _selectedDate, _focusedDate;
  late final HomeRepository _repository;
  HomeSnapshot? _snapshot;
  bool _loading = true, _showGuide = false;
  bool _recordsSaved = false;
  String? _error, _reminderSignature;
  String? _lastLanguage;
  int _requestEpoch = 0;
  final Color _primaryColor = const Color(0xFF24534E);
  final Color _accentColor = const Color(0xFF197F72);
  QuestionnaireLinkSet _questionnaireLinks = QuestionnaireLinks.fallback;
  bool _isLoadingQuestionnaireLinks = true,
      _showDailyQuestionnaireBadge = false;
  String get _language => Localizations.localeOf(context).languageCode;
  String text(String key) => reviewText(key, _language);
  bool get _pvtb =>
      const String.fromEnvironment('WAKEMATE_ALERTNESS_MODE') == 'pvtb' ||
      appFlavor == 'pvtb';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDate = taipeiDateOnly(taipeiNow());
    _focusedDate = _selectedDate;
    _repository = widget.repository ?? HomeRepository();
    _refreshData();
    _loadGuide();
    if (widget.showQuestionnaireReminder) {
      _loadQuestionnaireLinks();
    } else {
      _isLoadingQuestionnaireLinks = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = _language;
    final previous = _lastLanguage;
    _lastLanguage = language;
    if (previous != null && previous != language) {
      _reminderSignature = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshData();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.repository == null) _repository.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ModalRoute.of(context)?.isCurrent == true) {
      _reminderSignature = null;
      _refreshData();
      if (widget.showQuestionnaireReminder) _refreshDailyQuestionnaireBadge();
    }
  }

  Future<void> _loadGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted)
        setState(
          () =>
              _showGuide =
                  prefs.getBool('home_guide_seen_${widget.userId}') != true,
        );
    } catch (error) {
      debugPrint('Optional welcome-guide cache unavailable: $error');
    }
  }

  Future<void> _hideGuide() async {
    setState(() => _showGuide = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('home_guide_seen_${widget.userId}', true);
    } catch (error) {
      debugPrint('Optional welcome-guide cache could not be saved: $error');
    }
  }

  Future<void> _refreshData({
    bool recalculate = false,
    bool recordsSaved = false,
  }) async {
    if (!mounted) return;
    if (recalculate) _reminderSignature = null;
    final epoch = ++_requestEpoch;
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
        _recordsSaved = recordsSaved;
      });
    try {
      if (recalculate)
        await invalidateFutureRecommendations(userId: widget.userId);
      final snapshot = await _repository.load(
        widget.userId,
        recalculate: recalculate,
      );
      if (!mounted || epoch != _requestEpoch) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
        _error = snapshot.calculationFailed ? 'calculationFailed' : null;
      });
      final signature = jsonEncode(
        snapshot.recommendations
            .map(
              (row) => [
                row['recommended_caffeine_intake_timing'],
                row['recommended_caffeine_amount'],
                row['source_data_latest_at'],
              ],
            )
            .toList(),
      );
      if (_reminderSignature != signature) {
        unawaited(
          _syncRecommendations(
            snapshot,
            announce: recalculate && !snapshot.calculationFailed,
            epoch: epoch,
            signature: signature,
          ),
        );
      }
    } catch (_) {
      if (mounted && epoch == _requestEpoch)
        setState(() {
          _loading = false;
          _error = 'refreshFailed';
        });
    }
  }

  Future<void> _syncRecommendations(
    HomeSnapshot snapshot, {
    required bool announce,
    required int epoch,
    required String signature,
  }) async {
    if (!mounted || AuthService.instance.userId != widget.userId) return;
    try {
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = 'caffeine_recommendations_${widget.userId}';
        List<Map<String, dynamic>> previous;
        try {
          previous = recommendationMapsFrom(
            jsonDecode(prefs.getString(key) ?? '[]'),
          );
        } catch (_) {
          previous = [];
        }
        final now = taipeiNow();
        final history = previous.where(
          (row) => recommendationTiming(row)?.isBefore(now) == true,
        );
        if (!mounted ||
            epoch != _requestEpoch ||
            AuthService.instance.userId != widget.userId)
          return;
        await prefs.setString(
          key,
          jsonEncode(
            dedupeRecommendations([...history, ...snapshot.recommendations]),
          ),
        );
      } catch (error) {
        debugPrint(
          'Confirmed home recommendation cache could not be saved: $error',
        );
      }
      if (!mounted ||
          epoch != _requestEpoch ||
          AuthService.instance.userId != widget.userId)
        return;
      final scheduled = await NotificationService.instance
          .replaceCaffeineReminders(
            recommendations: snapshot.recommendations,
            languageCode: _language,
            userId: widget.userId,
          );
      if (!mounted ||
          epoch != _requestEpoch ||
          AuthService.instance.userId != widget.userId)
        return;
      _reminderSignature = signature;
      if (announce &&
          mounted &&
          epoch == _requestEpoch &&
          AuthService.instance.userId == widget.userId)
        await NotificationService.instance.showCalculationComplete(
          recommendationCount: snapshot.recommendations.length,
          scheduledCount: scheduled,
          languageCode: _language,
        );
    } catch (_) {
      if (epoch == _requestEpoch) _reminderSignature = null;
      // Recommendation data remains usable when a phone notification permission is unavailable.
    }
  }

  Future<void> _loadQuestionnaireLinks() async {
    final links = await QuestionnaireLinks.fetch();

    if (!mounted) return;
    setState(() {
      _questionnaireLinks = links;
      _isLoadingQuestionnaireLinks = false;
    });
    await _refreshDailyQuestionnaireBadge();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeShowDailyQuestionnaireReminder();
    });
  }

  String get _dailyQuestionnaireReminderKey =>
      'daily_questionnaire_reminder_${widget.userId}';

  Future<void> _maybeShowDailyQuestionnaireReminder() async {
    if (!_questionnaireLinks.hasDailyLink) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = taipeiTodayKey();
      if (prefs.getString(_dailyQuestionnaireReminderKey) == today) return;

      if (mounted) {
        _showDailyQuestionnaireDialog(markAsSeenOnClose: true);
      }
    } catch (error) {
      debugPrint('Optional questionnaire reminder cache unavailable: $error');
    }
  }

  Future<void> _refreshDailyQuestionnaireBadge() async {
    if (!_questionnaireLinks.hasDailyLink) {
      if (mounted) setState(() => _showDailyQuestionnaireBadge = false);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = taipeiTodayKey();
      final shouldShow =
          prefs.getString(_dailyQuestionnaireReminderKey) != today;

      if (mounted) setState(() => _showDailyQuestionnaireBadge = shouldShow);
    } catch (error) {
      debugPrint('Optional questionnaire badge cache unavailable: $error');
    }
  }

  Future<void> _markDailyQuestionnaireReminderSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dailyQuestionnaireReminderKey, taipeiTodayKey());
    } catch (error) {
      debugPrint(
        'Optional questionnaire badge cache could not be saved: $error',
      );
    }
    if (mounted) setState(() => _showDailyQuestionnaireBadge = false);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _questionnaireLabel(QuestionnaireLinkEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    switch (entry.kind) {
      case QuestionnaireLinkKind.chineseBaseline:
        return l10n.chineseBaselineQuestionnaire;
      case QuestionnaireLinkKind.indonesianBaseline:
        return l10n.indonesianBaselineQuestionnaire;
      case QuestionnaireLinkKind.chineseDaily:
        return l10n.chineseDailyQuestionnaire;
      case QuestionnaireLinkKind.indonesianDaily:
        return l10n.indonesianDailyQuestionnaire;
    }
  }

  Future<void> _openQuestionnaire(QuestionnaireLinkEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final label = _questionnaireLabel(entry);
    final uri = Uri.tryParse(entry.url.trim());

    if (uri == null || !uri.hasScheme) {
      _showMessage('$label: ${l10n.questionnaireNotConfigured}');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!launched) {
      _showMessage(l10n.openFailed);
      return;
    }

    _showMessage(l10n.questionnaireReturnInstruction);
  }

  Future<void> _showDailyQuestionnaireDialog({
    bool markAsSeenOnClose = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoadingQuestionnaireLinks) {
      _showMessage(l10n.questionnaireLoading);
      return;
    }

    final entries = _questionnaireLinks.dailyEntries
        .where((entry) => entry.hasUrl)
        .toList(growable: false);

    if (entries.isEmpty) {
      _showMessage(l10n.questionnaireNotConfigured);
      return;
    }

    final shouldMarkSeen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.dailyQuestionnaireReminder),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.dailyQuestionnaireMessage),
                const SizedBox(height: 8),
                Text(
                  l10n.questionnaireReturnInstruction,
                  style: TextStyle(
                    color: _primaryColor.withValues(alpha: 0.72),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                for (final entry in entries) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                      _openQuestionnaire(entry);
                    },
                    icon: const Icon(Icons.open_in_new_outlined),
                    label: Text(_questionnaireLabel(entry)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.remindLater),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.skipToday),
            ),
          ],
        );
      },
    );

    if (markAsSeenOnClose && shouldMarkSeen == true) {
      await _markDailyQuestionnaireReminderSeen();
    }
  }

  Future<void> _openPage(Widget page) async {
    final changed = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) {
      await _refreshData(
        recordsSaved: changed == true,
        recalculate:
            changed == true ||
            page is SettingsPage ||
            page is UserInputHistoryPage,
      );
    }
  }

  void _showAddOptions() {
    final day = taipeiDateOnly(_selectedDate);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder:
          (sheetContext) => SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('yyyy/MM/dd').format(day),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    for (final entry in <(String, IconData, Widget)>[
                      (
                        l10n.actualSleepPeriod,
                        Icons.bed_outlined,
                        ActualSleepTimePage(
                          userId: widget.userId,
                          selectedDate: day,
                        ),
                      ),
                      (
                        l10n.targetWakePeriod,
                        Icons.wb_sunny_outlined,
                        TargetWakeTimePage(
                          userId: widget.userId,
                          selectedDate: day,
                        ),
                      ),
                      (
                        l10n.addCaffeineRecord,
                        Icons.local_cafe_outlined,
                        CaffeineLogPage(
                          userId: widget.userId,
                          selectedDate: day,
                        ),
                      ),
                    ])
                      ListTile(
                        leading: Icon(entry.$2, color: _accentColor),
                        title: Text(entry.$1),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _openPage(entry.$3);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _guide() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text('firstSteps'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: _hideGuide,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          for (final task in <(String, bool, Widget)>[
            (
              text('profile'),
              _snapshot?.hasProfile == true,
              SettingsPage(userId: widget.userId),
            ),
            (
              text('sleep'),
              _snapshot?.hasSleep == true,
              ActualSleepTimePage(
                userId: widget.userId,
                selectedDate: _selectedDate,
              ),
            ),
            (
              text('wake'),
              _snapshot?.hasWake == true,
              TargetWakeTimePage(
                userId: widget.userId,
                selectedDate: _selectedDate,
              ),
            ),
            (
              text('test'),
              _snapshot?.hasTest == true,
              _pvtb
                  ? AlertnessTestPage.pvtb(userId: widget.userId)
                  : AlertnessTestPage(userId: widget.userId),
            ),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                task.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.$2 ? _accentColor : null,
              ),
              title: Text(task.$1),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openPage(task.$3),
            ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _calendarCell(
    DateTime day, {
    bool selected = false,
    bool outside = false,
  }) {
    final stats = _snapshot?.summary(day);
    final caffeine = stats?.caffeineMg ?? 0;
    final sleep = stats?.sleepHours ?? 0;
    var maxCaffeine = 1.0, maxSleep = 1.0;
    for (final entry
        in _snapshot?.days.entries ?? <MapEntry<String, DaySummary>>[]) {
      if (entry.key.startsWith(
        '${_focusedDate.year}-${_focusedDate.month.toString().padLeft(2, '0')}',
      )) {
        if (entry.value.caffeineMg > maxCaffeine)
          maxCaffeine = entry.value.caffeineMg;
        if (entry.value.sleepHours > maxSleep)
          maxSleep = entry.value.sleepHours;
      }
    }
    Widget amount(String value, Color color, double ratio) => Expanded(
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        color: color.withValues(
          alpha: ratio == 0 ? 0 : .12 + .4 * ratio.clamp(0, 1),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF20323B)),
          ),
        ),
      ),
    );
    return Semantics(
      label: [
        dayKey(day),
        if (stats?.hasSleepRecord == true)
          '${text('sleep')}: ${sleep.toStringAsFixed(1)} h',
        if (stats?.hasCaffeineRecord == true)
          '${text('caffeine')}: ${caffeine.round()} mg',
      ].join(', '),
      selected: selected,
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? _accentColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Opacity(
          opacity: outside ? .5 : 1,
          child: Column(
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              amount(
                stats?.hasCaffeineRecord == true
                    ? NumberFormat.compact(locale: _language).format(caffeine)
                    : '',
                const Color(0xFFE0A32A),
                caffeine / maxCaffeine,
              ),
              amount(
                stats?.hasSleepRecord == true ? sleep.toStringAsFixed(1) : '',
                const Color(0xFF329D8E),
                sleep / maxSleep,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recommendations() {
    final l10n = AppLocalizations.of(context)!;
    final rows =
        _loading || _error != null
            ? <Map<String, dynamic>>[]
            : _snapshot?.recommendationsOn(_selectedDate) ?? [];
    final snapshot = _snapshot;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${DateFormat('MM/dd').format(_selectedDate)} ${text('recommendations')}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.recommendationHistory,
                icon: const Icon(Icons.history),
                onPressed:
                    () => _openPage(
                      CaffeineHistoryPage(
                        userId: widget.userId,
                        selectedDate: _selectedDate,
                        confirmedEntries:
                            _error == null && !_loading
                                ? _snapshot?.recommendations
                                : const [],
                      ),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            LinearProgressIndicator(semanticsLabel: text('updating')),
          if (!_loading && snapshot != null && !snapshot.hasSleep)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bed_outlined),
              title: Text(text('missingSleep')),
              trailing: const Icon(Icons.add),
              onTap:
                  () => _openPage(
                    ActualSleepTimePage(
                      userId: widget.userId,
                      selectedDate: _selectedDate,
                    ),
                  ),
            ),
          if (!_loading && snapshot != null && !snapshot.hasWake)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wb_sunny_outlined),
              title: Text(text('missingWake')),
              trailing: const Icon(Icons.add),
              onTap:
                  () => _openPage(
                    TargetWakeTimePage(
                      userId: widget.userId,
                      selectedDate: _selectedDate,
                    ),
                  ),
            ),
          if (!_loading &&
              snapshot != null &&
              snapshot.hasSleep &&
              snapshot.hasWake &&
              !snapshot.calculationFailed &&
              rows.isEmpty)
            Text(text('noDose')),
          for (final row in rows) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(
                '${DateFormat('HH:mm').format(recommendationTiming(row)!)} · ${row['recommended_caffeine_amount']} mg',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(l10n.recommendedAmount),
              trailing: IconButton(
                tooltip: text('drinkOptions'),
                icon: const Icon(Icons.local_cafe_outlined),
                onPressed:
                    () => _openPage(
                      DrinkMatchPage(
                        userId: widget.userId,
                        targetMg:
                            (row['recommended_caffeine_amount'] as num)
                                .toDouble(),
                        recommendedAt: recommendationTiming(row)!,
                      ),
                    ),
              ),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _menuIcon() => Stack(
    clipBehavior: Clip.none,
    children: [
      const Icon(Icons.menu),
      if (_showDailyQuestionnaireBadge)
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = _snapshot?.summary(_selectedDate);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(
        userId: widget.userId,
        userName: widget.userName,
        userEmail: widget.email,
        onDataChanged: () => _refreshData(recalculate: true),
        onGuideTap: () => setState(() => _showGuide = !_showGuide),
        showDailyQuestionnaireBadge: _showDailyQuestionnaireBadge,
        onDailyQuestionnaireTap:
            _isLoadingQuestionnaireLinks || !_questionnaireLinks.hasDailyLink
                ? null
                : () => _showDailyQuestionnaireDialog(markAsSeenOnClose: true),
      ),
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 4,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'WakeMate',
            key: ValueKey('home-brand'),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        backgroundColor: const Color(0xFFEFF8F5),
        foregroundColor: _primaryColor,
        leading: Builder(
          builder:
              (context) => IconButton(
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                icon: _menuIcon(),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('home-feedback'),
            tooltip: feedbackText('title', _language),
            icon: const Icon(Icons.feedback_outlined),
            onPressed:
                () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const FeedbackPage())),
          ),
          IconButton(
            key: const ValueKey('home-refresh'),
            tooltip: l10n.retry,
            onPressed: _loading ? null : () => _refreshData(recalculate: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refreshData(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_showGuide) _guide(),
                      if (_error != null && _recordsSaved)
                        Text(
                          text('savedRecommendationPending'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            _error == 'calculationFailed' &&
                                    _snapshot?.recommendationFailure != null
                                ? _snapshot!.recommendationFailure!.message(
                                  _language,
                                )
                                : text(_error!),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      TableCalendar(
                        locale: _language == 'zh' ? 'zh_TW' : _language,
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2100, 12, 31),
                        focusedDay: _focusedDate,
                        rowHeight:
                            76 +
                            (MediaQuery.textScalerOf(context).scale(16) - 16)
                                    .clamp(0, 40) *
                                2,
                        daysOfWeekHeight: 36,
                        availableGestures: AvailableGestures.horizontalSwipe,
                        selectedDayPredicate:
                            (day) => isSameDay(day, _selectedDate),
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDate = taipeiDateOnly(selected);
                            _focusedDate = taipeiDateOnly(focused);
                          });
                          _showAddOptions();
                        },
                        onPageChanged:
                            (focused) => setState(
                              () => _focusedDate = taipeiDateOnly(focused),
                            ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          dowBuilder:
                              (context, day) => Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    DateFormat.E(
                                      _language == 'zh' ? 'zh_TW' : _language,
                                    ).format(day),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                          defaultBuilder:
                              (context, day, focused) => _calendarCell(day),
                          todayBuilder:
                              (context, day, focused) => _calendarCell(day),
                          selectedBuilder:
                              (context, day, focused) =>
                                  _calendarCell(day, selected: true),
                          outsideBuilder:
                              (context, day, focused) =>
                                  _calendarCell(day, outside: true),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_cafe,
                                color: Color(0xFFC28A13),
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Flexible(child: Text('mg · ${text('caffeine')}')),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bed, color: _accentColor, size: 20),
                              const SizedBox(width: 6),
                              Flexible(child: Text('h · ${text('sleep')}')),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        text('sleepByWakeDate'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF52636D),
                        ),
                      ),
                      const Divider(height: 28),
                      Text(
                        DateFormat('yyyy/MM/dd').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: [
                          if (summary?.hasCaffeineRecord == true)
                            Text(
                              '${text('caffeine')}: ${summary?.caffeineMg.round() ?? '-'} mg',
                              style: const TextStyle(fontSize: 17),
                            ),
                          if (summary?.hasSleepRecord == true)
                            Text(
                              '${text('sleep')}: ${summary?.sleepHours.toStringAsFixed(1) ?? '-'} h',
                              style: const TextStyle(fontSize: 17),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _showAddOptions,
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addRecord),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                () => _openPage(
                                  UserInputHistoryPage(
                                    userId: widget.userId,
                                    selectedDate: _selectedDate,
                                  ),
                                ),
                            icon: const Icon(Icons.edit_note),
                            label: Text(l10n.inputHistory),
                          ),
                        ],
                      ),
                      _recommendations(),
                    ],
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
