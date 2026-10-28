import 'dart:async';
import 'dart:convert';
import 'package:my_app/utils/password_policy.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/api/api_config.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

class SecureSessionStore implements SessionStore {
  static const _storage = FlutterSecureStorage();
  static const _key = 'wakemate_authenticated_session_v1';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
  @override
  Future<void> delete() => _storage.delete(key: _key);
}

class AuthException implements Exception {
  const AuthException(this.code);
  final String code;
  @override
  String toString() => code;
}

class AuthService extends ChangeNotifier {
  AuthService({http.Client? client, SessionStore? store, Uri? baseUri})
    : _client = client ?? http.Client(),
      _store = store ?? SecureSessionStore(),
      baseUri = baseUri ?? Uri.parse(ApiConfig.baseUrl);

  static final instance = AuthService();
  final http.Client _client;
  final SessionStore _store;
  final Uri baseUri;
  static const _timeout = Duration(seconds: 60);
  Map<String, dynamic>? _session;
  Future<void>? _initialization;
  Future<bool>? _refreshing;
  Future<void> _credentialOperation = Future<void>.value();
  int generation = 0;

  String? get accessToken => _session?['access_token'] as String?;
  String? get userId => (_session?['user'] as Map?)?['user_id'] as String?;
  String get userName => (_session?['user'] as Map?)?['name']?.toString() ?? '';
  String get email => (_session?['user'] as Map?)?['email']?.toString() ?? '';
  bool get googleLinked =>
      (_session?['user'] as Map?)?['google_linked'] == true;
  bool get passwordLoginAvailable =>
      (_session?['user'] as Map?)?['password_login_available'] != false;
  bool get passwordChangeRequired =>
      _session?['password_change_required'] == true;

  Future<void> initialize({bool retry = false}) {
    if (retry) _initialization = null;
    return _initialization ??= _restore();
  }

  Future<void> _restore() async {
    final raw = await _store.read();
    if (raw == null) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('isLoggedIn') == true) await _clearLocalData();
      return;
    }
    try {
      _session = _parsePair(jsonDecode(raw));
    } catch (_) {
      await _expire();
      return;
    }
    final response = await _client
        .get(
          baseUri.resolve('/auth/me'),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(_timeout);
    if (response.statusCode == 401) {
      await refresh(expectedAccess: accessToken);
    } else if (response.statusCode == 200) {
      final user = jsonDecode(response.body) as Map<String, dynamic>;
      if (user['user_id'] != userId) {
        await _expire();
        throw const AuthException('invalid_session');
      }
      _session!['user'] = user;
      _session!['password_change_required'] =
          user['password_change_required'] == true;
      await _store.write(jsonEncode(_session));
    } else {
      throw const AuthException('server_unavailable');
    }
  }

  Map<String, dynamic> _parsePair(dynamic data) {
    if (data is! Map<String, dynamic> ||
        data['access_token'] is! String ||
        data['refresh_token'] is! String ||
        data['user'] is! Map ||
        data['user']['user_id'] is! String ||
        data['user']['email'] is! String ||
        !data['access_token'].startsWith('wma_') ||
        !data['refresh_token'].startsWith('wmr_')) {
      throw const AuthException('invalid_session');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<void> _acceptPair(dynamic data, {bool newIdentity = false}) async {
    final parsed = _parsePair(data);
    if (!newIdentity && userId != null && parsed['user']['user_id'] != userId) {
      throw const AuthException('invalid_session');
    }
    await _store.write(jsonEncode(parsed));
    _session = parsed;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId!);
      await prefs.setString('userName', userName);
      await prefs.setString('userEmail', email);
      await prefs.setBool('isLoggedIn', true);
    } catch (error) {
      // Secure storage is authoritative; optional display caches are not authentication.
      debugPrint('Optional account cache could not be updated: $error');
    }
    if (newIdentity) generation++;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final response = await _client
        .post(
          baseUri.resolve('/login/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) throw AuthException(_errorCode(response));
    if (userId != null) await _clearLocalData();
    await _acceptPair(jsonDecode(response.body), newIdentity: true);
    _initialization = Future<void>.value();
  }

  Future<bool> refresh({String? expectedAccess}) async {
    if (_session == null) return false;
    if (expectedAccess != null && accessToken != expectedAccess) return true;
    return _refreshing ??= _serialize(() async {
      if (_session == null) return false;
      if (expectedAccess != null && accessToken != expectedAccess) return true;
      return _doRefresh();
    }).whenComplete(() => _refreshing = null);
  }

  Future<void> loginWithGoogleToken(String idToken) => _serialize(() async {
    if (userId != null) throw const AuthException('invalid_session');
    final response = await _client
        .post(
          baseUri.resolve('/auth/google/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_token': idToken}),
        )
        .timeout(_timeout);
    if (response.statusCode != 200) throw AuthException(_errorCode(response));
    final parsed = _parsePair(jsonDecode(response.body));
    await _clearLocalData();
    await _acceptPair(parsed, newIdentity: true);
    _initialization = Future<void>.value();
  });

  Future<void> linkGoogleToken(String idToken, String currentPassword) =>
      _serialize(() async {
        if (userId == null) throw const AuthException('session_expired');
        final owner = userId;
        final epoch = generation;
        Future<http.Response> request() => _client
            .post(
              baseUri.resolve('/auth/google/link'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
              body: jsonEncode({
                'id_token': idToken,
                'current_password': currentPassword,
              }),
            )
            .timeout(_timeout);
        var response = await request();
        if (response.statusCode == 401 &&
            _errorCode(response) == 'session_expired' &&
            await _doRefresh()) {
          response = await request();
        }
        if (userId != owner || generation != epoch || _session == null) {
          throw const AuthException('session_expired');
        }
        if (response.statusCode != 200) {
          throw AuthException(_errorCode(response));
        }
        if (jsonDecode(response.body)['google_linked'] != true) {
          throw const AuthException('invalid_session');
        }
        await _acceptPair({
          ..._session!,
          'user': {
            ...Map<String, dynamic>.from(_session!['user'] as Map),
            'google_linked': true,
          },
        });
      });

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _credentialOperation.then((_) => operation());
    _credentialOperation = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<bool> _doRefresh() async {
    final identity = userId;
    final epoch = generation;
    final response = await _client
        .post(
          baseUri.resolve('/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': _session!['refresh_token']}),
        )
        .timeout(_timeout);
    if (userId != identity || generation != epoch || _session == null) {
      return false;
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      await _expire();
      return false;
    }
    if (response.statusCode != 200) throw AuthException(_errorCode(response));
    await _acceptPair(jsonDecode(response.body));
    return true;
  }

  Future<void> changePassword(String currentPassword, String newPassword) =>
      _serialize(() async {
        if (!acceptsNewPassword(newPassword)) {
          throw const AuthException(passwordPolicyError);
        }
        var response = await _passwordRequest(currentPassword, newPassword);
        if (response.statusCode == 401 && await _doRefresh()) {
          response = await _passwordRequest(currentPassword, newPassword);
        }
        if (response.statusCode != 200) {
          throw AuthException(_errorCode(response));
        }
        await _acceptPair(jsonDecode(response.body));
        generation++;
        notifyListeners();
      });

  Future<http.Response> _passwordRequest(String current, String next) => _client
      .post(
        baseUri.resolve('/auth/change_password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'current_password': current, 'new_password': next}),
      )
      .timeout(_timeout);

  Future<void> signOut() => _serialize(() async {
    if (_session != null) {
      var response = await _client
          .post(
            baseUri.resolve('/auth/logout'),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(_timeout);
      if (response.statusCode == 401 && await _doRefresh()) {
        response = await _client
            .post(
              baseUri.resolve('/auth/logout'),
              headers: {'Authorization': 'Bearer $accessToken'},
            )
            .timeout(_timeout);
      }
      if (response.statusCode != 200 && response.statusCode != 401) {
        throw AuthException(_errorCode(response));
      }
    }
    await _expire();
  });

  Future<void> expire() => _expire();

  Future<void> _expire() async {
    _session = null;
    await _store.delete();
    await _clearLocalData();
    generation++;
    _initialization = Future<void>.value();
    notifyListeners();
  }

  Future<void> _clearLocalData() async {
    try {
      await NotificationService.instance.cancelCaffeineReminders();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    final preserved = <String, Object>{};
    for (final key in [
      'baseline_questionnaire_prompt_seen_v2',
      notificationPermissionSetupSeenKey,
      'appLanguage',
    ]) {
      final value = prefs.get(key);
      if (value != null) preserved[key] = value;
    }
    await prefs.clear();
    for (final entry in preserved.entries) {
      if (entry.value is bool) {
        await prefs.setBool(entry.key, entry.value as bool);
      }
      if (entry.value is String) {
        await prefs.setString(entry.key, entry.value as String);
      }
    }
  }

  String _errorCode(http.Response response) {
    if (response.statusCode == 429) return 'too_many_attempts';
    try {
      final detail = jsonDecode(response.body)['detail'];
      if (detail is String) return detail;
    } catch (_) {}
    return 'server_unavailable';
  }
}
