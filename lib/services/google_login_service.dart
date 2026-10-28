import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/services/auth_service.dart';

class GoogleLoginConfiguration {
  const GoogleLoginConfiguration({this.serverClientId});
  final String? serverClientId;
  bool get enabled => serverClientId != null;

  factory GoogleLoginConfiguration.parse(dynamic value) {
    final id = value is Map ? value['server_client_id'] : null;
    if (value is Map &&
        value['enabled'] == true &&
        id is String &&
        RegExp(
          r'^[0-9]+-[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$',
        ).hasMatch(id)) {
      return GoogleLoginConfiguration(serverClientId: id);
    }
    return const GoogleLoginConfiguration();
  }
}

abstract class GoogleIdentityPicker {
  Future<String?> selectAccount(String serverClientId);
}

class NativeGoogleIdentityPicker implements GoogleIdentityPicker {
  static Future<void>? _initializing;
  static String? _clientId;

  @override
  Future<String?> selectAccount(String serverClientId) async {
    final google = GoogleSignIn.instance;
    if (_clientId != null && _clientId != serverClientId) {
      throw const AuthException('google_configuration_changed');
    }
    _clientId = serverClientId;
    _initializing ??= google.initialize(serverClientId: serverClientId);
    try {
      await _initializing;
      if (!google.supportsAuthenticate()) {
        throw const AuthException('google_platform_unavailable');
      }
      // Explicit account selection prevents silently signing in as the last participant.
      await google.signOut();
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw const AuthException('invalid_google_token');
      }
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw const AuthException('google_not_configured');
      }
      if (error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const AuthException('google_services_unavailable');
      }
      throw const AuthException('google_temporarily_unavailable');
    }
  }
}

class GoogleLoginService {
  GoogleLoginService({
    AuthService? auth,
    http.Client? client,
    GoogleIdentityPicker? picker,
    bool? supported,
  }) : _auth = auth ?? AuthService.instance,
       _client = client ?? http.Client(),
       _picker = picker ?? NativeGoogleIdentityPicker(),
       supported =
           supported ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  static final instance = GoogleLoginService();
  final AuthService _auth;
  final http.Client _client;
  final GoogleIdentityPicker _picker;
  final bool supported;
  bool _busy = false;

  Future<GoogleLoginConfiguration> configuration() async {
    if (!supported) return const GoogleLoginConfiguration();
    final response = await _client
        .get(_auth.baseUri.resolve('/auth/google/config'))
        .timeout(const Duration(seconds: 6));
    if (response.statusCode == 404) return const GoogleLoginConfiguration();
    if (response.statusCode != 200) {
      throw const AuthException('google_temporarily_unavailable');
    }
    return GoogleLoginConfiguration.parse(jsonDecode(response.body));
  }

  Future<bool> signIn(GoogleLoginConfiguration config) =>
      _select(config, (token) => _auth.loginWithGoogleToken(token));

  Future<bool> link(GoogleLoginConfiguration config, String password) =>
      _select(config, (token) => _auth.linkGoogleToken(token, password));

  Future<bool> _select(
    GoogleLoginConfiguration config,
    Future<void> Function(String) accept,
  ) async {
    if (!supported) throw const AuthException('google_platform_unavailable');
    if (!config.enabled) throw const AuthException('google_not_configured');
    if (_busy) throw const AuthException('auth_flow_in_progress');
    _busy = true;
    try {
      final token = await _picker.selectAccount(config.serverClientId!);
      if (token == null) return false;
      await accept(token);
      return true;
    } finally {
      _busy = false;
    }
  }
}
