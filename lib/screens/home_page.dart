import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/config/questionnaire_links.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'CaffeineHistory.dart';
import 'CaffeineLogPage.dart';
import 'CaffeineRecommendationPage.dart';
import 'SleepTimeLogPage.dart';
import 'UserInputHistoryPage.dart';
import 'WakeTimeLogPage.dart';
import 'custom_drawer.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String email;

  const HomePage({
    super.key,
    required this.userId,
    this.userName = "",
    this.email = "",
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;

  final Color _primaryColor = const Color(0xFF4B6B7A);
  final Color _accentColor = const Color(0xFF8BB9A1);
  final Color _bgLight = const Color(0xFFF9F9F7);
  final Color _cardColor = Colors.white;

  double _totalCaffeine = 0;
  double _totalSleep = 0;
  QuestionnaireLinkSet _questionnaireLinks = QuestionnaireLinks.fallback;
  bool _isLoadingQuestionnaireLinks = true;
  bool _showDailyQuestionnaireBadge = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = taipeiDateOnly(taipeiNow());
    _focusedDate = _selectedDate;
    _loadDailyStats();
    _loadQuestionnaireLinks();
  }

  Future<void> _loadDailyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (!mounted) return;
    setState(() {
      _totalCaffeine = prefs.getDouble('caffeine_$dateKey') ?? 0;
      _totalSleep = prefs.getDouble('sleep_$dateKey') ?? 0;
    });
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

    final prefs = await SharedPreferences.getInstance();
    final today = taipeiTodayKey();
    if (prefs.getString(_dailyQuestionnaireReminderKey) == today) return;

    if (mounted) {
      _showDailyQuestionnaireDialog(markAsSeenOnClose: true);
    }
  }

  Future<void> _refreshDailyQuestionnaireBadge() async {
    if (!_questionnaireLinks.hasDailyLink) {
      if (mounted) setState(() => _showDailyQuestionnaireBadge = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final today = taipeiTodayKey();
    final shouldShow = prefs.getString(_dailyQuestionnaireReminderKey) != today;

    if (mounted) setState(() => _showDailyQuestionnaireBadge = shouldShow);
  }

  Future<void> _markDailyQuestionnaireReminderSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyQuestionnaireReminderKey, taipeiTodayKey());
    if (mounted) setState(() => _showDailyQuestionnaireBadge = false);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _questionnaireReturnInstruction() {
    switch (Localizations.localeOf(context).languageCode) {
      case 'id':
        return 'Setelah selesai mengisi kuesioner, tutup jendela browser dan kembali ke aplikasi WakeMate.';
      case 'en':
        return 'After completing the questionnaire, close the browser window and switch back to the WakeMate app.';
      default:
        return '填寫完成後，請自行關閉問卷視窗，切換回 WakeMate App。';
    }
  }

  Future<void> _openQuestionnaire(QuestionnaireLinkEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(entry.url.trim());

    if (uri == null || !uri.hasScheme) {
      _showMessage('${entry.label}: ${l10n.questionnaireNotConfigured}');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!launched) {
      _showMessage(l10n.openFailed);
      return;
    }

    _showMessage(_questionnaireReturnInstruction());
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
                  _questionnaireReturnInstruction(),
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
                    label: Text(entry.label),
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

  Future<void> _navigateToRecommendationHistoryPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CaffeineHistoryPage(
              userId: widget.userId,
              selectedDate: _selectedDate,
            ),
      ),
    );
    _loadDailyStats();
  }

  void _navigateToUserInputHistoryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => UserInputHistoryPage(
              userId: widget.userId,
              selectedDate: _selectedDate,
            ),
      ),
    ).then((_) => _loadDailyStats());
  }

  void _showAddOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.addData,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const Divider(thickness: 0.8),
                _buildOptionTile(
                  title: l10n.targetWakePeriod,
                  icon: Icons.wb_sunny_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TargetWakeTimePage(
                              userId: widget.userId,
                              selectedDate: _selectedDate,
                            ),
                      ),
                    ).then((_) => _loadDailyStats());
                  },
                ),
                _buildOptionTile(
                  title: l10n.actualSleepPeriod,
                  icon: Icons.bed_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ActualSleepTimePage(
                              userId: widget.userId,
                              selectedDate: _selectedDate,
                            ),
                      ),
                    ).then((_) => _loadDailyStats());
                  },
                ),
                _buildOptionTile(
                  title: l10n.addCaffeineRecord,
                  icon: Icons.local_cafe_outlined,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CaffeineLogPage(
                              userId: widget.userId,
                              selectedDate: _selectedDate,
                            ),
                      ),
                    ).then((_) => _loadDailyStats());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _accentColor, size: 26),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          color: _primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: _accentColor, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildMenuIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.menu, size: 30, color: _primaryColor),
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bgLight,
      drawer: CustomDrawer(
        userId: widget.userId,
        userName: widget.userName,
        userEmail: widget.email,
        showDailyQuestionnaireBadge: _showDailyQuestionnaireBadge,
        onDailyQuestionnaireTap:
            _isLoadingQuestionnaireLinks || !_questionnaireLinks.hasDailyLink
                ? null
                : () => _showDailyQuestionnaireDialog(markAsSeenOnClose: true),
      ),
      appBar: AppBar(
        title: Text(
          "WakeMate",
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 3,
        shadowColor: Colors.black12,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: _buildMenuIcon(),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.caffeineIntakeToday,
                          style: TextStyle(
                            color: _primaryColor.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_totalCaffeine.toStringAsFixed(0)}${l10n.unitMg}",
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.sleepDurationToday,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: _primaryColor.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_totalSleep.toStringAsFixed(1)}${l10n.unitHours}",
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDate,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDate = selected;
                    _focusedDate = focused;
                  });
                  _loadDailyStats();
                },
                calendarStyle: CalendarStyle(
                  cellMargin: const EdgeInsets.all(2),
                  selectedDecoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(color: _primaryColor),
                  weekendTextStyle: TextStyle(color: _primaryColor),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  headerPadding: const EdgeInsets.symmetric(vertical: 15),
                  titleTextStyle: TextStyle(
                    color: _primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: _accentColor,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: _accentColor,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: _primaryColor.withValues(alpha: 0.8),
                  ),
                  weekendStyle: TextStyle(color: _accentColor),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () => _showAddOptions(context),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(
                      l10n.addRecord,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: BorderSide(color: _primaryColor, width: 1.8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _navigateToUserInputHistoryPage,
                    icon: const Icon(Icons.edit_note),
                    label: Text(
                      l10n.inputHistory,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CaffeineRecommendationPage(
                                userId: widget.userId,
                                selectedDate: _selectedDate,
                              ),
                        ),
                      ).then((_) => _loadDailyStats());
                    },
                    icon: const Icon(Icons.auto_graph, size: 22),
                    label: Text(
                      l10n.calculateRecommendation,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accentColor,
                      side: BorderSide(color: _accentColor, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _navigateToRecommendationHistoryPage,
                    icon: const Icon(Icons.history, size: 22),
                    label: Text(
                      l10n.recommendationHistory,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
