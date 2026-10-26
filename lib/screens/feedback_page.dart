import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/config/app_release.dart';
import 'package:my_app/services/feedback_service.dart';
import 'package:my_app/utils/feedback_text.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, this.openEmail, this.copyReport});
  final Future<bool> Function(Uri)? openEmail;
  final Future<void> Function(String)? copyReport;
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  String _category = 'general';
  String? _status;
  bool _includeVersion = true, _busy = false, _allowPop = false;
  bool _confirmingLeave = false;
  String get _language => Localizations.localeOf(context).languageCode;
  String text(String key) => feedbackText(key, _language);
  bool get _dirty =>
      _subject.text.trim().isNotEmpty || _description.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _subject.addListener(_changed);
    _description.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() => _status = null);
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  FeedbackDraft get _draft => FeedbackDraft(
    description: _description.text,
    subject: _subject.text,
    category: _category,
    language: _language,
    includeVersion: _includeVersion,
  );

  Future<void> _openMail() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final uri = _draft.mailUri;
      final opened =
          await (widget.openEmail?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (mounted) {
        setState(() => _status = opened ? 'mailOpened' : 'mailUnavailable');
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'mailUnavailable');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final message = _draft.copyText;
      await (widget.copyReport?.call(message) ??
          Clipboard.setData(ClipboardData(text: message)));
      if (mounted) setState(() => _status = 'copied');
    } catch (_) {
      if (mounted) setState(() => _status = 'copyFailed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmLeave() async {
    if (_confirmingLeave) return;
    _confirmingLeave = true;
    final leave = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(text('discardTitle')),
            content: Text(text('discardBody')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(text('stay')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(text('leave')),
              ),
            ],
          ),
    );
    _confirmingLeave = false;
    if (leave != true || !mounted) return;
    _leave();
  }

  void _leave() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        if (_dirty) {
          _confirmLeave();
        } else {
          _leave();
        }
      }
    },
    child: Scaffold(
      appBar: AppBar(title: Text(text('title'))),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      text('recipient'),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    const SelectableText(FeedbackDraft.recipient),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('feedback-category'),
                      initialValue: _category,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: text('category'),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final value in FeedbackDraft.categories)
                          DropdownMenuItem(
                            value: value,
                            child: Text(text(value)),
                          ),
                      ],
                      onChanged:
                          _busy
                              ? null
                              : (value) => setState(() {
                                _category = value!;
                                _status = null;
                              }),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const ValueKey('feedback-subject'),
                      controller: _subject,
                      enabled: !_busy,
                      maxLength: 100,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: text('subject'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('feedback-description'),
                      controller: _description,
                      enabled: !_busy,
                      minLines: 6,
                      maxLines: 12,
                      maxLength: 4000,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: text('description'),
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? text('required')
                                  : null,
                    ),
                    Text(
                      text('privacy'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      key: const ValueKey('feedback-version'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _includeVersion,
                      title: Text(text('includeVersion')),
                      subtitle: Text('${text('version')}: ${AppRelease.label}'),
                      onChanged:
                          _busy
                              ? null
                              : (value) =>
                                  setState(() => _includeVersion = value!),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const ValueKey('feedback-open-mail'),
                      onPressed: _busy ? null : _openMail,
                      icon: const Icon(Icons.mail_outline),
                      label: Text(text('openMail')),
                    ),
                    TextButton.icon(
                      key: const ValueKey('feedback-copy'),
                      onPressed: _busy ? null : _copy,
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(text('copy')),
                    ),
                    if (_status != null) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          text(_status!),
                          key: const ValueKey('feedback-status'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
