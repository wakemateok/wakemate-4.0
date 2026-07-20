import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_app/config/questionnaire_links.dart';

const baselineQuestionnairePromptSeenKey = 'baseline_questionnaire_prompt_seen';

class QuestionnaireGate extends StatefulWidget {
  final Widget child;

  const QuestionnaireGate({super.key, required this.child});

  @override
  State<QuestionnaireGate> createState() => _QuestionnaireGateState();
}

class _QuestionnaireGateState extends State<QuestionnaireGate> {
  bool _isLoading = true;
  bool _showPrompt = false;

  @override
  void initState() {
    super.initState();
    _loadPromptState();
  }

  Future<void> _loadPromptState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenPrompt =
        prefs.getBool(baselineQuestionnairePromptSeenKey) ?? false;

    if (!mounted) return;
    setState(() {
      _showPrompt = !hasSeenPrompt;
      _isLoading = false;
    });
  }

  Future<void> _markPromptSeenAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(baselineQuestionnairePromptSeenKey, true);

    if (!mounted) return;
    setState(() => _showPrompt = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_showPrompt) {
      return widget.child;
    }

    return QuestionnairePromptPage(onComplete: _markPromptSeenAndContinue);
  }
}

class QuestionnairePromptPage extends StatefulWidget {
  final Future<void> Function() onComplete;

  const QuestionnairePromptPage({super.key, required this.onComplete});

  @override
  State<QuestionnairePromptPage> createState() =>
      _QuestionnairePromptPageState();
}

class _QuestionnairePromptPageState extends State<QuestionnairePromptPage> {
  final Color _primaryColor = const Color(0xFF4B6B7A);
  final Color _accentColor = const Color(0xFF8BB9A1);
  final Color _bgLight = const Color(0xFFF9F9F7);

  QuestionnaireLinkSet _links = QuestionnaireLinks.fallback;
  bool _isLoadingLinks = true;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    final links = await QuestionnaireLinks.fetch();

    if (!mounted) return;
    setState(() {
      _links = links;
      _isLoadingLinks = false;
    });
  }

  Future<void> _openQuestionnaire(QuestionnaireLinkEntry entry) async {
    final uri = Uri.tryParse(entry.url.trim());

    if (uri == null || !uri.hasScheme) {
      _showMessage('${entry.label} 連結尚未設定');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;
    if (!launched) {
      _showMessage('無法開啟 ${entry.label}');
      return;
    }

    _showMessage(_questionnaireReturnInstruction());
    await widget.onComplete();
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final entries = _links.baselineEntries;

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 58,
                    color: _accentColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '研究初始問卷',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '此問卷只需要在參與研究初期填寫一次。若您已填寫過，或目前不方便填寫，可以略過並進入 WakeMate。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _primaryColor.withValues(alpha: 0.82),
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _questionnaireReturnInstruction(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _primaryColor.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_isLoadingLinks) ...[
                    LinearProgressIndicator(color: _accentColor),
                    const SizedBox(height: 16),
                  ],
                  for (final entry in entries) ...[
                    _QuestionnaireButton(
                      label: entry.label,
                      enabled: !_isLoadingLinks && entry.hasUrl,
                      onPressed: () => _openQuestionnaire(entry),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!_isLoadingLinks && !_links.hasBaselineLink) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9C46A)),
                      ),
                      child: Text(
                        '目前尚未設定初始問卷連結。請先略過進入 App，或稍後由後台更新問卷連結。',
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: widget.onComplete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: BorderSide(
                        color: _primaryColor.withValues(alpha: 0.55),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '略過，進入 App',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionnaireButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _QuestionnaireButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.open_in_new_outlined),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4B6B7A),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
