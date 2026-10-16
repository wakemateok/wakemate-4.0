import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/api/home_data.dart';
import 'package:my_app/data/drink_matches.dart';
import 'package:my_app/utils/catalog_labels.dart';
import 'package:my_app/utils/review_text.dart';

Map<String, dynamic> intake(String time, num mg, {bool active = true}) => {
  'user_id': 'owner',
  'taking_timestamp': time,
  'caffeine_amount': mg,
  'is_active': active,
};
Map<String, dynamic> sleep(String start, String end) => {
  'user_id': 'owner',
  'sleep_start_time': start,
  'sleep_end_time': end,
};
Map<String, dynamic> rec(String time, num mg) => {
  'user_id': 'owner',
  'recommended_caffeine_intake_timing': time,
  'recommended_caffeine_amount': mg,
  'is_active': true,
};

void main() {
  test(
    'calendar totals use Taipei dates, active records and union of sleep intervals',
    () {
      final snapshot = HomeSnapshot(
        sleeps: [
          sleep('2026-10-19T15:00:00Z', '2026-10-20T00:00:00Z'),
          sleep('2026-10-19T16:00:00Z', '2026-10-19T23:00:00Z'),
          sleep('2026-10-20T04:00:00Z', '2026-10-20T05:00:00Z'),
          {
            ...sleep('2026-10-18T15:00:00Z', '2026-10-19T00:00:00Z'),
            'deleted_at': '2026-10-20T01:00:00Z',
          },
        ],
        wakes: [],
        hasProfile: true,
        intakes: [
          intake('2026-10-19T15:59:00Z', 100),
          intake('2026-10-19T16:00:00Z', 75),
          intake('2026-10-20T01:00:00Z', 50),
          intake('2026-10-20T02:00:00Z', 250, active: false),
          {
            ...intake('2026-10-20T02:00:00Z', 250),
            'invalidated_at': '2026-10-20T03:00:00Z',
          },
        ],
        recommendations: [rec('2026-10-19T16:00:00Z', 75)],
      );
      expect(snapshot.summary(DateTime(2026, 10, 19)).caffeineMg, 100);
      expect(snapshot.summary(DateTime(2026, 10, 20)).caffeineMg, 125);
      expect(snapshot.summary(DateTime(2026, 10, 20)).sleepHours, 10);
      expect(snapshot.summary(DateTime(2026, 10, 19)).sleepHours, 0);
      expect(snapshot.recommendationsOn(DateTime(2026, 10, 19)), isEmpty);
      expect(snapshot.recommendationsOn(DateTime(2026, 10, 20)), hasLength(1));
    },
  );

  Map<String, List<Map<String, dynamic>>> data() => {
    'users_sleep': [sleep('2026-10-19T15:00:00Z', '2026-10-20T00:00:00Z')],
    'users_wake': [
      {'user_id': 'owner'},
    ],
    'users_intake': [intake('2026-10-20T01:00:00Z', 50)],
    'users_body_info': [
      {'user_id': 'owner'},
    ],
    'users_pvt': [
      {'user_id': 'owner'},
    ],
    'recommendations': [
      rec('2026-10-20T04:00:00Z', 75),
      rec('2026-10-20T04:00:00Z', 75),
    ],
  };

  HomeRepository repository(
    Map<String, List<Map<String, dynamic>>> values,
    List<http.Request> calls, {
    int calculateStatus = 200,
    bool failRecommendations = false,
  }) => HomeRepository(
    client: MockClient((request) async {
      calls.add(request);
      expect(request.url.queryParameters['user_id'], 'owner');
      if (request.method == 'POST') {
        expect(request.url.path, '/calculate/');
        return http.Response('{"status":"ok"}', calculateStatus);
      }
      final path = request.url.path.split('/')[1];
      if (path == 'recommendations' && failRecommendations)
        return http.Response('unavailable', 503);
      return http.Response(jsonEncode(values[path] ?? []), 200);
    }),
  );

  test(
    'read-only home refresh is scoped and deduplicates server results',
    () async {
      final calls = <http.Request>[];
      final repo = repository(data(), calls);
      final snapshot = await repo.load('owner');
      expect(calls, hasLength(6));
      expect(calls.every((r) => r.method == 'GET'), isTrue);
      expect(snapshot.recommendations, hasLength(1));
      expect(snapshot.hasProfile && snapshot.hasTest, isTrue);
      repo.close();
    },
  );

  test(
    'saved input refresh calculates once before loading recommendations',
    () async {
      final calls = <http.Request>[];
      final repo = repository(data(), calls);
      final snapshot = await repo.load('owner', recalculate: true);
      expect(calls.where((r) => r.method == 'POST'), hasLength(1));
      expect(calls.last.url.path, '/recommendations/');
      expect(snapshot.calculationFailed, isFalse);
      repo.close();
    },
  );

  for (final missing in ['users_sleep', 'users_wake']) {
    test(
      'missing $missing does not send invalid automatic calculation',
      () async {
        final values = data()..[missing] = [];
        final calls = <http.Request>[];
        final repo = repository(values, calls);
        await repo.load('owner', recalculate: true);
        expect(calls.where((r) => r.method == 'POST'), isEmpty);
        repo.close();
      },
    );
  }

  test(
    'calculation failure retains saved records but never presents old recommendations as current',
    () async {
      final repo = repository(data(), [], calculateStatus: 503);
      final snapshot = await repo.load('owner', recalculate: true);
      expect(snapshot.calculationFailed, isTrue);
      expect(snapshot.summary(DateTime(2026, 10, 20)).caffeineMg, 50);
      expect(snapshot.recommendations, isEmpty);
      repo.close();
    },
  );

  test(
    'recommendation read failure does not hide saved calendar records',
    () async {
      final repo = repository(data(), [], failRecommendations: true);
      final snapshot = await repo.load('owner');
      expect(snapshot.calculationFailed, isTrue);
      expect(snapshot.hasSleep, isTrue);
      repo.close();
    },
  );

  test('home rejects data belonging to another participant', () async {
    final values =
        data()
          ..['users_intake'] = [
            {'user_id': 'another-owner'},
          ];
    final repo = repository(values, []);
    await expectLater(repo.load('owner'), throwsStateError);
    repo.close();
  });

  test(
    'new snapshot replaces deleted or edited records instead of keeping cached totals',
    () async {
      final values = data();
      final repo = repository(values, []);
      expect(
        (await repo.load('owner')).summary(DateTime(2026, 10, 20)).caffeineMg,
        50,
      );
      values['users_intake'] = [intake('2026-10-20T01:00:00Z', 25)];
      expect(
        (await repo.load('owner')).summary(DateTime(2026, 10, 20)).caffeineMg,
        25,
      );
      values['users_intake'] = [];
      expect(
        (await repo.load('owner')).summary(DateTime(2026, 10, 20)).caffeineMg,
        0,
      );
      repo.close();
    },
  );

  for (var i = 1; i <= 100; i++) {
    final target = i * 5.0;
    test(
      'drink conversion $i / 100: $target mg never exceeds the target or duplicates a product',
      () {
        final matches = matchDrinks(target);
        expect(
          matches.map((m) => m.item.id).toSet(),
          hasLength(matches.length),
        );
        for (final match in matches) {
          expect(match.item.isEstimate, isFalse);
          expect(match.caffeineMg, inInclusiveRange(1, target));
          expect([1.0, .75, .5, .25], contains(match.fraction));
        }
        for (var j = 1; j < matches.length; j++) {
          expect(
            matches[j - 1].caffeineMg,
            greaterThanOrEqualTo(matches[j].caffeineMg),
          );
        }
      },
    );
  }
  test('invalid target and unavailable brand produce no portions', () {
    for (final target in [0.0, -1.0, double.nan, double.infinity, 501.0]) {
      expect(matchDrinks(target), isEmpty);
    }
    expect(matchDrinks(75, brand: 'missing'), isEmpty);
    expect(
      matchDrinks(
        75,
        brand: 'Starbucks',
      ).every((m) => m.item.brand == 'Starbucks'),
      isTrue,
    );
  });
  test(
    'new interface copy and catalog names have complete English and Indonesian versions',
    () {
      for (final language in ['en', 'id']) {
        for (final key in [
          'firstSteps',
          'feedback',
          'testMeaning',
          'sleepyAdvice',
          'doseReference',
          'portion',
          'calculationFailed',
        ]) {
          expect(reviewText(key, language), isNot(key));
          expect(
            RegExp(r'[\u4e00-\u9fff]').hasMatch(reviewText(key, language)),
            isFalse,
          );
        }
        for (final match in matchDrinks(500)) {
          expect(
            RegExp(
              r'[\u4e00-\u9fff]',
            ).hasMatch(catalogProductName(match.item, language)),
            isFalse,
          );
          expect(
            RegExp(
              r'[\u4e00-\u9fff]',
            ).hasMatch(catalogSizeLabel(match.item, language)),
            isFalse,
          );
        }
      }
    },
  );
}
