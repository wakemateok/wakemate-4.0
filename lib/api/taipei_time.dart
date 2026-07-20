import 'package:intl/intl.dart';

const Duration taipeiUtcOffset = Duration(hours: 8);

DateTime taipeiNow() => DateTime.now().toUtc().add(taipeiUtcOffset);

DateTime taipeiDateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String taipeiTodayKey() => DateFormat('yyyy-MM-dd').format(taipeiNow());

DateTime parseTaipeiInput(String value) {
  return DateFormat('yyyy-MM-dd HH:mm').parseStrict(value.trim());
}

String taipeiInputToUtcIso(String value) {
  final taipeiTime = parseTaipeiInput(value);
  final utcTime = DateTime.utc(
    taipeiTime.year,
    taipeiTime.month,
    taipeiTime.day,
    taipeiTime.hour,
    taipeiTime.minute,
    taipeiTime.second,
    taipeiTime.millisecond,
    taipeiTime.microsecond,
  ).subtract(taipeiUtcOffset);

  return utcTime.toIso8601String();
}

DateTime? apiTimestampToTaipei(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  try {
    final parsed = DateTime.parse(value.trim());
    return parsed.toUtc().add(taipeiUtcOffset);
  } catch (_) {
    return null;
  }
}
