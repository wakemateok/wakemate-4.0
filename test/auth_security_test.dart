import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/api/authenticated_http.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/utils/auth_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemorySessionStore implements SessionStore {
  String? value;
  bool failWrite = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String data) async {
    if (failWrite) throw StateError('Storage unavailable');
    value = data;
  }

  @override
  Future<void> delete() async => value = null;
}

Map<String, dynamic> pair([String suffix = '1', bool changeRequired = false]) =>
    {
      'access_token': 'wma_$suffix',
      'refresh_token': 'wmr_$suffix',
      'password_change_required': changeRequired,
      'user': {
        'user_id': 'user-one',
        'name': 'Research participant',
        'email': 'test@example.com',
      },
    };

http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final baseUri = Uri.parse('https://api.example.com');
  late MemorySessionStore store;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = MemorySessionStore();
  });
  AuthService authWith(
    FutureOr<http.Response> Function(http.Request) handler,
  ) => AuthService(
    client: MockClient((request) async => handler(request)),
    store: store,
    baseUri: baseUri,
  );

  test('login stores credentials only in secure session storage', () async {
    final auth = authWith((request) {
      expect(jsonDecode(request.body)['password'], 'Password with spaces ');
      return jsonResponse(pair());
    });
    await auth.login(' Test@example.com ', 'Password with spaces ');
    expect(auth.userId, 'user-one');
    expect(auth.generation, 1);
    expect(store.value, contains('wmr_1'));
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      expect(prefs.get(key).toString(), isNot(contains('wmr_')));
      expect(prefs.get(key).toString(), isNot(contains('wma_')));
      expect(
        prefs.get(key).toString(),
        isNot(contains('Password with spaces')),
      );
    }
  });

  test('a SharedPreferences login flag cannot authenticate', () async {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
      'userId': 'forged',
    });
    final auth = authWith((_) => throw StateError('No network expected'));
    await auth.initialize();
    expect(auth.accessToken, isNull);
    expect(auth.userId, isNull);
    expect((await SharedPreferences.getInstance()).getString('userId'), isNull);
  });

  test('secure storage failure does not create an in-memory login', () async {
    store.failWrite = true;
    final auth = authWith((_) => jsonResponse(pair()));
    await expectLater(
      auth.login('test@example.com', 'Password-2026!'),
      throwsStateError,
    );
    expect(auth.userId, isNull);
  });

  test('restore validates the session with the server', () async {
    store.value = jsonEncode(pair());
    final auth = authWith((request) {
      expect(request.url.path, '/auth/me');
      expect(request.headers['Authorization'], 'Bearer wma_1');
      return jsonResponse({
        ...pair()['user'],
        'password_change_required': false,
      });
    });
    await auth.initialize();
    expect(auth.userId, 'user-one');
  });

  test('invalid restored identity fails closed', () async {
    store.value = jsonEncode(pair());
    final auth = authWith((_) => jsonResponse({'user_id': 'different'}));
    await expectLater(auth.initialize(), throwsA(isA<AuthException>()));
    expect(auth.userId, isNull);
    expect(store.value, isNull);
  });

  test('100 concurrent refresh attempts use a single token rotation', () async {
    var rotations = 0;
    final gate = Completer<void>();
    final auth = authWith((request) async {
      if (request.url.path == '/login/') return jsonResponse(pair());
      rotations++;
      await gate.future;
      return jsonResponse(pair('2'));
    });
    await auth.login('test@example.com', 'Password-2026!');
    final requests = List.generate(
      100,
      (_) => auth.refresh(expectedAccess: 'wma_1'),
    );
    gate.complete();
    expect(await Future.wait(requests), everyElement(isTrue));
    expect(rotations, 1);
    expect(auth.accessToken, 'wma_2');
    expect(await auth.refresh(expectedAccess: 'wma_1'), isTrue);
    expect(rotations, 1);
  });

  test(
    'refresh denial removes credentials instead of retaining a login',
    () async {
      final auth = authWith(
        (request) =>
            request.url.path == '/login/'
                ? jsonResponse(pair())
                : jsonResponse({'detail': 'session_expired'}, 401),
      );
      await auth.login('test@example.com', 'Password-2026!');
      expect(await auth.refresh(), isFalse);
      expect(auth.userId, isNull);
      expect(store.value, isNull);
    },
  );

  test(
    'network failure during refresh retains credentials for retry',
    () async {
      final auth = authWith(
        (request) =>
            request.url.path == '/login/'
                ? jsonResponse(pair())
                : throw http.ClientException('Offline'),
      );
      await auth.login('test@example.com', 'Password-2026!');
      await expectLater(auth.refresh(), throwsA(isA<http.ClientException>()));
      expect(auth.accessToken, 'wma_1');
    },
  );

  test(
    'logout revokes server session and clears local participant data',
    () async {
      final auth = authWith(
        (request) =>
            request.url.path == '/login/'
                ? jsonResponse(pair())
                : jsonResponse({'status': 'success'}),
      );
      await auth.login('test@example.com', 'Password-2026!');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('caffeine_recommendations_user-one', 'private');
      await prefs.setString('appLanguage', 'id');
      await prefs.setBool('baseline_questionnaire_prompt_seen_v2', true);
      await prefs.setBool(notificationPermissionSetupSeenKey, true);
      await auth.signOut();
      expect(auth.userId, isNull);
      expect(store.value, isNull);
      expect(prefs.getString('caffeine_recommendations_user-one'), isNull);
      expect(prefs.getString('appLanguage'), 'id');
      expect(prefs.getBool('baseline_questionnaire_prompt_seen_v2'), isTrue);
      expect(prefs.getBool(notificationPermissionSetupSeenKey), isTrue);
    },
  );

  test('weak legacy password flag requires password change', () async {
    final auth = authWith((_) => jsonResponse(pair('1', true)));
    await auth.login('test@example.com', '12345678');
    expect(auth.passwordChangeRequired, isTrue);
    await expectLater(
      auth.changePassword('12345678', '   '),
      throwsA(isA<AuthException>()),
    );
  });

  test('password change rotates credentials without a second login', () async {
    final auth = authWith(
      (request) => jsonResponse(
        request.url.path == '/login/' ? pair('1', true) : pair('2'),
      ),
    );
    await auth.login('test@example.com', '12345678');
    await auth.changePassword('12345678', 'New-password-2026!');
    expect(auth.passwordChangeRequired, isFalse);
    expect(auth.accessToken, 'wma_2');
    expect(auth.generation, 2);
  });

  test(
    'a short new password reaches the authenticated password endpoint unchanged',
    () async {
      final auth = authWith((request) {
        if (request.url.path == '/login/') return jsonResponse(pair('1'));
        expect(request.url.path, '/auth/change_password');
        expect(request.headers['Authorization'], 'Bearer wma_1');
        expect(jsonDecode(request.body)['new_password'], 'a');
        return jsonResponse(pair('2'));
      });
      await auth.login('test@example.com', 'Old-password-2026!');
      await auth.changePassword('Old-password-2026!', 'a');
      expect(auth.accessToken, 'wma_2');
    },
  );

  test(
    'authenticated requests reject foreign origins before sending tokens',
    () async {
      final auth = authWith((_) => jsonResponse(pair()));
      await auth.login('test@example.com', 'Password-2026!');
      var sent = false;
      final client = AuthenticatedClient(
        auth: auth,
        transport: MockClient((_) async {
          sent = true;
          return jsonResponse({});
        }),
      );
      await expectLater(
        client.get(Uri.parse('https://other.example.com/users/')),
        throwsA(isA<AuthException>()),
      );
      expect(sent, isFalse);
    },
  );

  test(
    '401 retries once with refreshed bearer and identical request body',
    () async {
      final auth = authWith(
        (request) =>
            jsonResponse(request.url.path == '/login/' ? pair() : pair('2')),
      );
      await auth.login('test@example.com', 'Password-2026!');
      var attempts = 0;
      final client = AuthenticatedClient(
        auth: auth,
        transport: MockClient((request) async {
          attempts++;
          expect(request.body, '{"data":1}');
          expect(request.followRedirects, isFalse);
          expect(request.headers['Authorization'], 'Bearer wma_$attempts');
          return jsonResponse({}, attempts == 1 ? 401 : 200);
        }),
      );
      expect(
        (await client.post(
          baseUri.resolve('/users_sleep/'),
          body: '{"data":1}',
        )).statusCode,
        200,
      );
      expect(attempts, 2);
    },
  );

  test('second unauthorized response expires the session', () async {
    final auth = authWith(
      (request) =>
          jsonResponse(request.url.path == '/login/' ? pair() : pair('2')),
    );
    await auth.login('test@example.com', 'Password-2026!');
    final client = AuthenticatedClient(
      auth: auth,
      transport: MockClient((_) async => jsonResponse({}, 401)),
    );
    await expectLater(
      client.get(baseUri.resolve('/users/')),
      throwsA(isA<AuthException>()),
    );
    expect(auth.userId, isNull);
  });

  test('in-flight old account responses are discarded after logout', () async {
    final auth = authWith(
      (request) =>
          request.url.path == '/login/'
              ? jsonResponse(pair())
              : jsonResponse({'status': 'success'}),
    );
    await auth.login('test@example.com', 'Password-2026!');
    final sent = Completer<void>();
    final result = Completer<http.Response>();
    final client = AuthenticatedClient(
      auth: auth,
      transport: MockClient((_) {
        sent.complete();
        return result.future;
      }),
    );
    final pending = client.get(baseUri.resolve('/users/'));
    final assertion = expectLater(pending, throwsA(isA<AuthException>()));
    await sent.future;
    await auth.signOut();
    result.complete(jsonResponse({'sensitive': true}));
    await assertion;
  });

  test('new security UI text covers all three languages', () {
    for (final key in [
      'passwordPolicy',
      'changePassword',
      'passwordMismatch',
      'invalid_credentials',
      'session_expired',
    ]) {
      final translations =
          ['zh', 'en', 'id'].map((lang) => authText(key, lang)).toSet();
      expect(translations.length, 3, reason: key);
      expect(translations, isNot(contains(key)), reason: key);
    }
  });
}
