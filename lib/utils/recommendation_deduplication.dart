import 'package:intl/intl.dart';
import 'package:my_app/api/taipei_time.dart';

List<Map<String, dynamic>> recommendationMapsFrom(dynamic data) {
  final rawEntries = data is List ? data : [data];
  return rawEntries
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

List<Map<String, dynamic>> filterRecommendationsForDate(
  Iterable<Map<String, dynamic>> entries,
  DateTime selectedDate,
) {
  final targetDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
  return entries
      .where((item) {
        final timing = recommendationTiming(item);
        if (timing == null) return false;
        return DateFormat('yyyy-MM-dd').format(timing) == targetDateStr;
      })
      .toList(growable: false);
}

List<Map<String, dynamic>> dedupeRecommendations(
  Iterable<Map<String, dynamic>> entries,
) {
  final byKey = <String, Map<String, dynamic>>{};

  for (final item in entries) {
    final key = _recommendationKey(item);
    if (key == null) continue;

    final existing = byKey[key];
    if (existing == null || _isNewer(item, existing)) {
      byKey[key] = item;
    }
  }

  final deduped = byKey.values.toList(growable: false);
  deduped.sort((a, b) {
    final aTime = recommendationTiming(a);
    final bTime = recommendationTiming(b);
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return aTime.compareTo(bTime);
  });
  return deduped;
}

DateTime? recommendationTiming(Map<String, dynamic> item) {
  return apiTimestampToTaipei(
    item['recommended_caffeine_intake_timing']?.toString(),
  );
}

String? _recommendationKey(Map<String, dynamic> item) {
  final timing = recommendationTiming(item);
  if (timing == null) return null;

  final normalizedTime =
      DateTime(
        timing.year,
        timing.month,
        timing.day,
        timing.hour,
        timing.minute,
      ).toIso8601String();
  final amount = item['recommended_caffeine_amount']?.toString() ?? '';
  return '$normalizedTime|$amount';
}

bool _isNewer(Map<String, dynamic> current, Map<String, dynamic> existing) {
  final currentTime = _versionTime(current);
  final existingTime = _versionTime(existing);
  if (currentTime == null && existingTime == null) return true;
  if (currentTime == null) return false;
  if (existingTime == null) return true;
  return currentTime.isAfter(existingTime);
}

DateTime? _versionTime(Map<String, dynamic> item) {
  for (final key in ['updated_at', 'source_data_latest_at', 'created_at']) {
    final parsed = DateTime.tryParse(item[key]?.toString() ?? '');
    if (parsed != null) return parsed.toUtc();
  }
  return null;
}
