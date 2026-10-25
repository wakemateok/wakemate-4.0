import 'dart:convert';

import 'package:my_app/api/api_config.dart';
import 'package:my_app/api/authenticated_http.dart' as http;
import 'package:my_app/api/taipei_time.dart';
import 'package:my_app/api/recommendation_failure.dart';
import 'package:my_app/utils/recommendation_deduplication.dart';

String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class DaySummary {
  const DaySummary({this.caffeineMg = 0, this.sleepHours = 0});
  final double caffeineMg;
  final double sleepHours;
}

class HomeSnapshot {
  HomeSnapshot({
    required this.sleeps,
    required this.wakes,
    required this.intakes,
    required this.recommendations,
    required this.hasProfile,
    this.hasTest = false,
    this.calculationFailed = false,
    this.recommendationFailure,
  }) {
    final caffeine = <String, double>{};
    final sleepPeriods = <String, List<(DateTime, DateTime)>>{};
    for (final row in intakes.where(activeRecord)) {
      final at = apiTimestampToTaipei(row['taking_timestamp']?.toString());
      final amount = (row['caffeine_amount'] as num?)?.toDouble();
      if (at == null || amount == null || !amount.isFinite || amount <= 0)
        continue;
      caffeine.update(
        dayKey(at),
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }
    for (final row in sleeps.where(activeRecord)) {
      final start = apiTimestampToTaipei(row['sleep_start_time']?.toString());
      final end = apiTimestampToTaipei(row['sleep_end_time']?.toString());
      if (start == null || end == null || !end.isAfter(start)) continue;
      sleepPeriods.putIfAbsent(dayKey(end), () => []).add((start, end));
    }
    for (final key in {...caffeine.keys, ...sleepPeriods.keys}) {
      final periods = sleepPeriods[key] ?? [];
      periods.sort((a, b) => a.$1.compareTo(b.$1));
      Duration duration = Duration.zero;
      DateTime? start, end;
      for (final period in periods) {
        if (start == null) {
          start = period.$1;
          end = period.$2;
        } else if (!period.$1.isAfter(end!)) {
          if (period.$2.isAfter(end)) end = period.$2;
        } else {
          duration += end.difference(start);
          start = period.$1;
          end = period.$2;
        }
      }
      if (start != null) duration += end!.difference(start);
      days[key] = DaySummary(
        caffeineMg: caffeine[key] ?? 0,
        sleepHours: duration.inMinutes / 60,
      );
    }
  }
  final List<Map<String, dynamic>> sleeps, wakes, intakes, recommendations;
  final bool hasProfile, hasTest, calculationFailed;
  final RecommendationFailure? recommendationFailure;
  final Map<String, DaySummary> days = {};
  bool get hasSleep => sleeps.any(activeRecord);
  bool get hasWake => wakes.any(activeRecord);
  DaySummary summary(DateTime day) => days[dayKey(day)] ?? const DaySummary();
  List<Map<String, dynamic>> recommendationsOn(DateTime day) =>
      filterRecommendationsForDate(recommendations, day);
  static bool activeRecord(Map<String, dynamic> row) =>
      row['is_active'] != false &&
      row['deleted_at'] == null &&
      row['invalidated_at'] == null;
}

class HomeRepository {
  HomeRepository({http.Client? client})
    : _client = client ?? http.authenticatedClient();
  final http.Client _client;

  Future<List<Map<String, dynamic>>> _read(
    String endpoint,
    String userId,
  ) async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/$endpoint/?user_id=$userId'))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) throw StateError('home_refresh_failed');
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! List) throw const FormatException('Expected records');
    final records =
        data.map((row) => Map<String, dynamic>.from(row as Map)).toList();
    if (records.any((row) => row['user_id']?.toString() != userId)) {
      throw StateError('unexpected_record_owner');
    }
    return records;
  }

  Future<HomeSnapshot> load(String userId, {bool recalculate = false}) async {
    final records = await Future.wait([
      _read('users_sleep', userId),
      _read('users_wake', userId),
      _read('users_intake', userId),
      _read('users_body_info', userId),
      _read('users_pvt', userId),
    ]);
    RecommendationFailure? failure = findSleepWakeConflict(
      records[0],
      records[1],
    );
    var calculationFailed = failure != null;
    if (recalculate &&
        failure == null &&
        records[0].any(HomeSnapshot.activeRecord) &&
        records[1].any(HomeSnapshot.activeRecord)) {
      try {
        final response = await _client
            .post(Uri.parse('${ApiConfig.baseUrl}/calculate/?user_id=$userId'))
            .timeout(const Duration(seconds: 120));
        calculationFailed = response.statusCode != 200;
        if (calculationFailed)
          failure = RecommendationFailure.fromBody(response.body);
        if (!calculationFailed) {
          final body = jsonDecode(response.body);
          calculationFailed =
              body is! Map || !['ok', 'success'].contains(body['status']);
          if (calculationFailed)
            failure = RecommendationFailure.fromBody(response.body);
        }
      } catch (_) {
        calculationFailed = true;
        failure = const RecommendationFailure('unavailable');
      }
    }
    List<Map<String, dynamic>> recommendations = [];
    try {
      final response =
          failure == null
              ? await _client
                  .get(
                    Uri.parse(
                      '${ApiConfig.baseUrl}/recommendations/?user_id=$userId',
                    ),
                  )
                  .timeout(const Duration(seconds: 60))
              : null;
      if (response != null && response.statusCode != 200) {
        failure = RecommendationFailure.fromBody(response.body);
        calculationFailed = true;
      }
      final serverRecommendations =
          response?.statusCode == 200
              ? recommendationMapsFrom(
                jsonDecode(utf8.decode(response!.bodyBytes)),
              )
              : <Map<String, dynamic>>[];
      if (serverRecommendations.any(
        (row) => row['user_id']?.toString() != userId,
      ))
        throw StateError('unexpected_record_owner');
      if (!calculationFailed &&
          records[0].any(HomeSnapshot.activeRecord) &&
          records[1].any(HomeSnapshot.activeRecord)) {
        recommendations =
            dedupeRecommendations(
              filterActiveRecommendations(serverRecommendations),
            ).where((row) {
              final amount = row['recommended_caffeine_amount'];
              return amount is num &&
                  amount.isFinite &&
                  amount > 0 &&
                  amount <= 500;
            }).toList();
      }
    } catch (_) {
      calculationFailed = true;
      failure = const RecommendationFailure('unavailable');
    }
    return HomeSnapshot(
      sleeps: records[0],
      wakes: records[1],
      intakes: records[2],
      recommendations: recommendations,
      hasProfile: records[3].isNotEmpty,
      hasTest: records[4].any(HomeSnapshot.activeRecord),
      calculationFailed: calculationFailed,
      recommendationFailure: failure,
    );
  }

  void close() => _client.close();
}
