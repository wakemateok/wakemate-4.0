import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/api/day_record_replacement.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  Future<void> save(
    http.Client client, {
    Duration timeout = const Duration(seconds: 1),
  }) => replaceDayRecords(
    baseUrl: 'https://example.invalid',
    endpoint: 'users_wake',
    userId: 'test-user',
    selectedDate: DateTime(2026, 10, 20),
    periods: [
      {'start': '2026-10-20T01:00:00Z', 'end': '2026-10-20T02:00:00Z'},
    ],
    client: client,
    timeout: timeout,
  );

  test('atomic save uses one POST and never deletes old records', () async {
    var count = 0;
    await save(
      MockClient((request) async {
        count++;
        expect(request.method, 'POST');
        expect(request.url.path, '/users_wake/replace_day');
        expect(jsonDecode(request.body)['day'], '2026-10-20');
        return http.Response('{"status":"success","ids":[1]}', 200);
      }),
    );
    expect(count, 1);
  });

  test('lost response retries the identical idempotent payload', () async {
    final bodies = <String>[];
    await save(
      MockClient((request) async {
        bodies.add(request.body);
        if (bodies.length == 1) throw http.ClientException('connection reset');
        return http.Response(
          '{"status":"success","ids":[1],"changed":false}',
          200,
        );
      }),
    );
    expect(bodies.length, 2);
    expect(bodies[0], bodies[1]);
  });

  test('temporary gateway failure can retry without a delete', () async {
    var count = 0;
    await save(
      MockClient((request) async {
        expect(request.method, 'POST');
        count++;
        return count == 1
            ? http.Response('unavailable', 503)
            : http.Response('{"status":"success"}', 200);
      }),
    );
    expect(count, 2);
  });

  test(
    'validation failure is not retried or replaced with destructive fallback',
    () async {
      var count = 0;
      await expectLater(
        save(
          MockClient((request) async {
            count++;
            expect(request.method, 'POST');
            return http.Response('{"detail":"sleep_wake_overlap"}', 400);
          }),
        ),
        throwsA(
          isA<RecordSaveException>().having(
            (e) => e.code,
            'code',
            'sleep_wake_overlap',
          ),
        ),
      );
      expect(count, 1);
    },
  );

  test('old backend is refused safely rather than deleting data', () async {
    await expectLater(
      save(MockClient((request) async => http.Response('Not Found', 404))),
      throwsA(
        isA<RecordSaveException>().having(
          (e) => e.code,
          'code',
          'server_update_required',
        ),
      ),
    );
  });

  test('persistent network error reports unconfirmed state', () async {
    var count = 0;
    await expectLater(
      save(
        MockClient((request) async {
          count++;
          throw http.ClientException('offline');
        }),
      ),
      throwsA(
        isA<RecordSaveException>().having((e) => e.code, 'code', 'unconfirmed'),
      ),
    );
    expect(count, 2);
  });

  test('timeout retries once then preserves an unconfirmed result', () async {
    final pending = <Completer<http.Response>>[];
    final future = save(
      MockClient((request) {
        final result = Completer<http.Response>();
        pending.add(result);
        return result.future;
      }),
      timeout: const Duration(milliseconds: 2),
    );
    await expectLater(future, throwsA(isA<RecordSaveException>()));
    expect(pending.length, 2);
    for (final result in pending) {
      result.complete(http.Response('{"status":"success"}', 200));
    }
  });
}
