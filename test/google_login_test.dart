import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/screens/LoginPage.dart';
import 'package:my_app/screens/google_account_page.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/services/google_login_service.dart';
import 'package:my_app/utils/auth_text.dart';
import 'package:my_app/widgets/google_sign_in_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_security_test.dart' as fixtures;

const clientId = '1234567890-wakemate-test.apps.googleusercontent.com';
const configuration = GoogleLoginConfiguration(serverClientId: clientId);

class FakePicker implements GoogleIdentityPicker {
  int calls = 0;
  Future<String?> Function()? pick;
  @override
  Future<String?> selectAccount(String id) async {
    expect(id, clientId);
    calls++;
    return pick == null ? 'google-id-token-for-tests-only' : await pick!();
  }
}

http.Response response(Object value, [int code = 200]) => http.Response(
  jsonEncode(value),
  code,
  headers: {'content-type': 'application/json'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late fixtures.MemorySessionStore store;
  late FakePicker picker;
  late AuthService auth;
  late GoogleLoginService google;

  void prepare(
    FutureOr<http.Response> Function(http.Request) handle, {
    bool supported = true,
  }) {
    final client = MockClient((request) async => handle(request));
    auth = AuthService(
      client: client,
      store: store,
      baseUri: Uri.parse('https://api.example.com'),
    );
    google = GoogleLoginService(
      auth: auth,
      client: client,
      picker: picker,
      supported: supported,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = fixtures.MemorySessionStore();
    picker = FakePicker();
  });

  test('only explicit valid server configuration enables Google', () {
    for (final value in [
      null,
      {},
      {'enabled': false, 'server_client_id': clientId},
      {'enabled': true, 'server_client_id': 'placeholder'},
      {'enabled': true, 'server_client_id': 123},
    ]) {
      expect(GoogleLoginConfiguration.parse(value).enabled, false);
    }
    expect(
      GoogleLoginConfiguration.parse({
        'enabled': true,
        'server_client_id': clientId,
      }).enabled,
      true,
    );
  });

  test('unsupported platforms do not call the server or picker', () async {
    prepare((_) => throw StateError('No network expected'), supported: false);
    expect((await google.configuration()).enabled, false);
    await expectLater(
      google.signIn(configuration),
      throwsA(isA<AuthException>()),
    );
    expect(picker.calls, 0);
  });

  test(
    'old backend without Google config leaves password login available',
    () async {
      prepare(
        (request) =>
            request.url.path == '/auth/google/config'
                ? response({}, 404)
                : response(fixtures.pair()),
      );
      expect((await google.configuration()).enabled, false);
      await auth.login('test@example.com', 'existing-password');
      expect(auth.userId, 'user-one');
      expect(auth.passwordLoginAvailable, true);
    },
  );

  test('configuration failure cannot trigger native login', () async {
    prepare((_) => response({}, 503));
    await expectLater(google.configuration(), throwsA(isA<AuthException>()));
    await expectLater(
      google.signIn(const GoogleLoginConfiguration()),
      throwsA(isA<AuthException>()),
    );
    expect(picker.calls, 0);
  });

  test(
    'canceling account selection does not call the login endpoint',
    () async {
      prepare((_) => throw StateError('No API login expected'));
      picker.pick = () async => null;
      expect(await google.signIn(configuration), false);
      expect(auth.userId, null);
      expect(store.value, null);
    },
  );

  test(
    'verified backend pair creates session without caching Google token',
    () async {
      prepare((request) {
        expect(request.url.path, '/auth/google/login');
        expect(jsonDecode(request.body), {
          'id_token': 'google-id-token-for-tests-only',
        });
        final data = fixtures.pair();
        data['user'] = {
          ...data['user'],
          'google_linked': true,
          'password_login_available': false,
        };
        return response(data);
      });
      expect(await google.signIn(configuration), true);
      expect(auth.googleLinked, true);
      expect(auth.passwordLoginAvailable, false);
      expect(auth.userId, 'user-one');
      expect(store.value, isNot(contains('google-id-token')));
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        expect(prefs.get(key).toString(), isNot(contains('google-id-token')));
      }
    },
  );

  test('email collision never creates or replaces a local session', () async {
    prepare(
      (_) => response({'detail': 'google_existing_account_sign_in_first'}, 409),
    );
    await expectLater(
      google.signIn(configuration),
      throwsA(
        isA<AuthException>().having(
          (e) => e.code,
          'code',
          'google_existing_account_sign_in_first',
        ),
      ),
    );
    expect(auth.userId, null);
    expect(store.value, null);
  });

  test(
    'Google login refuses an existing identity instead of switching participants',
    () async {
      prepare((request) {
        expect(request.url.path, '/login/');
        return response(fixtures.pair());
      });
      await auth.login('test@example.com', 'password');
      await expectLater(
        auth.loginWithGoogleToken('token'),
        throwsA(isA<AuthException>()),
      );
      expect(auth.userId, 'user-one');
    },
  );

  test(
    'malformed server pair cannot authenticate or erase existing display data',
    () async {
      SharedPreferences.setMockInitialValues({'marker': 'keep'});
      prepare((_) => response({'access_token': 'forged'}));
      await expectLater(
        google.signIn(configuration),
        throwsA(isA<AuthException>()),
      );
      expect(auth.userId, null);
      expect(
        (await SharedPreferences.getInstance()).getString('marker'),
        'keep',
      );
    },
  );

  test(
    'link uses current bearer and password and preserves identity and local records',
    () async {
      prepare((request) {
        if (request.url.path == '/login/') return response(fixtures.pair());
        expect(request.url.path, '/auth/google/link');
        expect(request.headers['Authorization'], 'Bearer wma_1');
        expect(
          jsonDecode(request.body)['current_password'],
          ' password with spaces ',
        );
        return response({'google_linked': true, 'status': 'success'});
      });
      await auth.login('test@example.com', 'password');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sleep_cache', 'existing');
      final generation = auth.generation;
      expect(await google.link(configuration, ' password with spaces '), true);
      expect(auth.userId, 'user-one');
      expect(auth.googleLinked, true);
      expect(auth.passwordLoginAvailable, true);
      expect(auth.generation, generation);
      expect(prefs.getString('sleep_cache'), 'existing');
      expect(store.value, isNot(contains('password with spaces')));
    },
  );

  test(
    'link refreshes an expired WakeMate session but not an invalid Google token',
    () async {
      var attempts = 0;
      prepare((request) {
        switch (request.url.path) {
          case '/login/':
            return response(fixtures.pair());
          case '/auth/refresh':
            return response(fixtures.pair('2'));
          default:
            attempts++;
            if (attempts == 1) {
              return response({'detail': 'session_expired'}, 401);
            }
            expect(request.headers['Authorization'], 'Bearer wma_2');
            return response({'google_linked': true});
        }
      });
      await auth.login('test@example.com', 'password');
      expect(await google.link(configuration, 'password'), true);
      expect(attempts, 2);
    },
  );

  test(
    'failed link retains original login and leaves Google unlinked',
    () async {
      prepare(
        (request) =>
            request.url.path == '/login/'
                ? response(fixtures.pair())
                : response({'detail': 'invalid_google_token'}, 401),
      );
      await auth.login('test@example.com', 'password');
      await expectLater(
        google.link(configuration, 'password'),
        throwsA(isA<AuthException>()),
      );
      expect(auth.googleLinked, false);
      expect(auth.accessToken, 'wma_1');
    },
  );

  test('double tapping invokes only one native account picker', () async {
    prepare((_) => response(fixtures.pair()));
    final wait = Completer<String?>();
    picker.pick = () => wait.future;
    final first = google.signIn(configuration);
    await expectLater(
      google.signIn(configuration),
      throwsA(isA<AuthException>()),
    );
    expect(picker.calls, 1);
    wait.complete(null);
    expect(await first, false);
    picker.pick = () async => null;
    expect(await google.signIn(configuration), false);
    expect(picker.calls, 2);
  });

  for (final language in ['zh', 'en', 'id']) {
    Widget app(Widget page) => MaterialApp(
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.6),
              padding: const EdgeInsets.only(bottom: 64),
            ),
            child: child!,
          ),
      home: page,
    );

    testWidgets('$language Google login fits small screens with large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      prepare(
        (request) => response({'enabled': true, 'server_client_id': clientId}),
      );
      await tester.pumpWidget(app(LoginPage(auth: auth, google: google)));
      await tester.pumpAndSettle();
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(tester.takeException(), null);
      expect(find.text(authText('googleSignIn', language)), findsOneWidget);
    });

    testWidgets('$language account linking fits small screens', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      prepare(
        (request) =>
            request.url.path == '/login/'
                ? response(fixtures.pair())
                : response({'enabled': true, 'server_client_id': clientId}),
      );
      await auth.login('test@example.com', 'password');
      await tester.pumpWidget(
        app(GoogleAccountPage(auth: auth, google: google)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(tester.takeException(), null);
    });
  }

  testWidgets('unconfigured Google never shows a nonfunctional login button', (
    tester,
  ) async {
    prepare((_) => response({'enabled': false, 'server_client_id': null}));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginPage(auth: auth, google: google),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GoogleSignInButton), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets(
    'Google configuration outage offers retry without blocking password login',
    (tester) async {
      var calls = 0;
      prepare((request) {
        calls++;
        return calls == 1
            ? response({}, 503)
            : response({'enabled': true, 'server_client_id': clientId});
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginPage(auth: auth, google: google),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(GoogleSignInButton), findsNothing);
      final retry = find.text(authText('googleRetry', 'en'));
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(calls, 2);
    },
  );

  testWidgets('already linked page does not start an unused network request', (
    tester,
  ) async {
    prepare((request) {
      expect(request.url.path, '/login/');
      final data = fixtures.pair();
      data['user'] = {...data['user'], 'google_linked': true};
      return response(data);
    });
    await auth.login('test@example.com', 'password');
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GoogleAccountPage(auth: auth, google: google),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), null);
  });
}
