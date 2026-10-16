import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/utils/auth_text.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, this.requiredChange = false, this.auth});
  final bool requiredChange;
  final AuthService? auth;
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  bool _obscure = true;
  String _error = '';
  AuthService get _auth => widget.auth ?? AuthService.instance;
  String text(String key) =>
      authText(key, Localizations.localeOf(context).languageCode);

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      await _auth.changePassword(_current.text, _next.text);
      if (mounted && !widget.requiredChange) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = text(e is AuthException ? e.code : 'server_unavailable'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_saving && !widget.requiredChange,
      child: Scaffold(
        appBar: AppBar(
          title: Text(text('changePassword')),
          automaticallyImplyLeading: !widget.requiredChange,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.requiredChange) ...[
                    Text(text('passwordChangeRequired')),
                    const SizedBox(height: 16),
                  ],
                  for (final entry in [
                    (_current, 'currentPassword'),
                    (_next, 'newPassword'),
                    (_confirm, 'confirmPassword'),
                  ]) ...[
                    TextFormField(
                      controller: entry.$1,
                      obscureText: _obscure,
                      enabled: !_saving,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: text(entry.$2),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: text('showPassword'),
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return text(entry.$2);
                        }
                        if (entry.$1 == _next &&
                            (value.runes.length < 12 ||
                                utf8.encode(value).length > 72)) {
                          return text('passwordPolicy');
                        }
                        if (entry.$1 == _confirm && value != _next.text) {
                          return text('passwordMismatch');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(text('passwordPolicy')),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.lock_reset),
                    label: Text(_saving ? l10n.saving : text('changePassword')),
                  ),
                  if (widget.requiredChange)
                    TextButton(
                      onPressed:
                          _saving
                              ? null
                              : () async {
                                setState(() => _saving = true);
                                try {
                                  await _auth.signOut();
                                } catch (_) {
                                  if (mounted) {
                                    setState(
                                      () => _error = text('server_unavailable'),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _saving = false);
                                }
                              },
                      child: Text(l10n.logout),
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
