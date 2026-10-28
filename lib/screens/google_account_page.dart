import 'package:flutter/material.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/services/google_login_service.dart';
import 'package:my_app/utils/auth_text.dart';
import 'package:my_app/widgets/google_sign_in_button.dart';

class GoogleAccountPage extends StatefulWidget {
  const GoogleAccountPage({super.key, this.auth, this.google});
  final AuthService? auth;
  final GoogleLoginService? google;
  @override
  State<GoogleAccountPage> createState() => _GoogleAccountPageState();
}

class _GoogleAccountPageState extends State<GoogleAccountPage> {
  final _password = TextEditingController();
  late Future<GoogleLoginConfiguration> _configuration;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  AuthService get _auth => widget.auth ?? AuthService.instance;
  GoogleLoginService get _google =>
      widget.google ?? GoogleLoginService.instance;
  String text(String key) =>
      authText(key, Localizations.localeOf(context).languageCode);

  @override
  void initState() {
    super.initState();
    _configuration =
        _auth.googleLinked
            ? Future.value(const GoogleLoginConfiguration())
            : _google.configuration();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _link(GoogleLoginConfiguration configuration) async {
    if (_busy) return;
    if (_password.text.isEmpty) {
      setState(() => _error = 'invalid_current_password');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final linked = await _google.link(configuration, _password.text);
      if (mounted && linked) {
        _password.clear();
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _error =
                  error is AuthException
                      ? error.code
                      : 'google_temporarily_unavailable',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: Text(text('googleAccount'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_auth.email, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              if (_auth.googleLinked)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.teal,
                  ),
                  title: Text(text('googleLinked')),
                )
              else
                FutureBuilder<GoogleLoginConfiguration>(
                  future: _configuration,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          Text(text('google_temporarily_unavailable')),
                          TextButton(
                            onPressed:
                                () => setState(() {
                                  _configuration = _google.configuration();
                                }),
                            child: Text(text('retry')),
                          ),
                        ],
                      );
                    }
                    final config =
                        snapshot.data ?? const GoogleLoginConfiguration();
                    if (!config.enabled) {
                      return Text(text('google_not_configured'));
                    }
                    if (!_auth.passwordLoginAvailable) {
                      return Text(text('password_login_not_available'));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(text('googleLinkHint')),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          enabled: !_busy,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: text('currentPassword'),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: text('showPassword'),
                              onPressed:
                                  _busy
                                      ? null
                                      : () =>
                                          setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GoogleSignInButton(
                          linking: true,
                          busy: _busy,
                          onPressed: _busy ? null : () => _link(config),
                        ),
                      ],
                    );
                  },
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  text(_error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
}
