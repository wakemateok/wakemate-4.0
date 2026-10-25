import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/api/home_data.dart';
import 'package:my_app/api/recommendation_failure.dart';

void main() {
  test(
    '100 expired conflicts cannot mask current overlaps or adjacent boundaries',
    () {
      final now = DateTime.utc(2026, 10, 25, 5);
      for (var index = 0; index < 100; index++) {
        final old = now.subtract(Duration(days: 10 + index));
        final current = now.add(Duration(hours: 3, minutes: index));
        final sleeps = <Map<String, dynamic>>[
          {
            'id': 1,
            'sleep_start_time': old.toIso8601String(),
            'sleep_end_time':
                old.add(const Duration(hours: 8)).toIso8601String(),
          },
          {
            'id': 2,
            'sleep_start_time':
                current.subtract(const Duration(hours: 6)).toIso8601String(),
            'sleep_end_time': current.toIso8601String(),
          },
        ];
        final wakes = <Map<String, dynamic>>[
          {
            'id': 3,
            'target_start_time':
                old.add(const Duration(hours: 7)).toIso8601String(),
            'target_end_time':
                old.add(const Duration(hours: 9)).toIso8601String(),
          },
          {
            'id': 4,
            'target_start_time': current.toIso8601String(),
            'target_end_time':
                current.add(const Duration(hours: 2)).toIso8601String(),
          },
        ];
        expect(findSleepWakeConflict(sleeps, wakes, now: now), isNull);
        sleeps[1]['sleep_end_time'] =
            current.add(const Duration(seconds: 1)).toIso8601String();
        final conflict = findSleepWakeConflict(sleeps, wakes, now: now)!;
        expect((conflict.detail!['conflicts'] as List).first['sleep']['id'], 2);
        expect((conflict.detail!['conflicts'] as List).first['wake']['id'], 4);
      }
    },
  );

  test(
    'ongoing cross-midnight periods use instants rather than calendar dates',
    () {
      final now = DateTime.utc(2026, 10, 25, 16);
      final sleeps = <Map<String, dynamic>>[
        {
          'sleep_start_time': '2026-10-26T01:00:00+08:00',
          'sleep_end_time': '2026-10-26T08:00:00+08:00',
        },
      ];
      final wakes = <Map<String, dynamic>>[
        {
          'target_start_time': '2026-10-25T22:00:00+08:00',
          'target_end_time': '2026-10-26T02:00:00+08:00',
        },
      ];
      expect(findSleepWakeConflict(sleeps, wakes, now: now), isNotNull);
      wakes[0]['target_end_time'] = '2026-10-26T00:00:00+08:00';
      expect(findSleepWakeConflict(sleeps, wakes, now: now), isNull);
    },
  );

  test(
    'expired historical overlap cannot block valid future home results',
    () async {
      final future = DateTime.now().toUtc().add(const Duration(days: 2));
      final earlier = future.subtract(const Duration(days: 100));
      final sleeps = [
        {
          'user_id': 'owner',
          'sleep_start_time': earlier.toIso8601String(),
          'sleep_end_time':
              earlier.add(const Duration(hours: 8)).toIso8601String(),
        },
        {
          'user_id': 'owner',
          'sleep_start_time': future.toIso8601String(),
          'sleep_end_time':
              future.add(const Duration(hours: 8)).toIso8601String(),
        },
      ];
      final wakes = [
        {
          'user_id': 'owner',
          'target_start_time':
              earlier.add(const Duration(hours: 7)).toIso8601String(),
          'target_end_time':
              earlier.add(const Duration(hours: 9)).toIso8601String(),
        },
        {
          'user_id': 'owner',
          'target_start_time':
              future.add(const Duration(hours: 12)).toIso8601String(),
          'target_end_time':
              future.add(const Duration(hours: 14)).toIso8601String(),
        },
      ];
      final recommendation = {
        'user_id': 'owner',
        'recommended_caffeine_amount': 50,
        'recommended_caffeine_intake_timing':
            future.add(const Duration(hours: 12)).toIso8601String(),
      };
      final calls = <String>[];
      final repo = HomeRepository(
        client: MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          final data = switch (request.url.path) {
            '/users_sleep/' => sleeps,
            '/users_wake/' => wakes,
            '/recommendations/' => [recommendation],
            '/calculate/' => {'status': 'ok'},
            _ => [],
          };
          return http.Response(jsonEncode(data), 200);
        }),
      );
      addTearDown(repo.close);
      for (final recalculate in [false, true]) {
        final snapshot = await repo.load('owner', recalculate: recalculate);
        expect(snapshot.calculationFailed, isFalse);
        expect(snapshot.recommendationFailure, isNull);
        expect(snapshot.recommendations, hasLength(1));
        expect(snapshot.sleeps, hasLength(2));
        expect(snapshot.wakes, hasLength(2));
      }
      expect(calls, contains('POST /calculate/'));
      expect(
        calls.where((call) => call == 'GET /recommendations/'),
        hasLength(2),
      );
    },
  );
}
