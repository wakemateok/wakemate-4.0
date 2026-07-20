import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_app/api/taipei_time.dart';

bool isSameWakeMateDate(DateTime value, DateTime selectedDate) {
  return value.year == selectedDate.year &&
      value.month == selectedDate.month &&
      value.day == selectedDate.day;
}

Future<int> deleteExistingDayRecords({
  required String baseUrl,
  required String endpoint,
  required String userId,
  required DateTime selectedDate,
  required String dateField,
}) async {
  final response = await http
      .get(Uri.parse('$baseUrl/$endpoint/?user_id=$userId'))
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception('讀取舊資料失敗：${response.statusCode}');
  }

  final decoded = json.decode(utf8.decode(response.bodyBytes));
  if (decoded is! List) {
    throw Exception('讀取舊資料失敗：回傳格式不正確');
  }

  final idsToDelete = decoded
      .whereType<Map<String, dynamic>>()
      .where((item) {
        final recordDate = apiTimestampToTaipei(item[dateField]?.toString());
        return recordDate != null &&
            isSameWakeMateDate(recordDate, selectedDate);
      })
      .map((item) => item['id'])
      .whereType<num>()
      .map((id) => id.toInt())
      .toList(growable: false);

  for (final id in idsToDelete) {
    final deleteResponse = await http
        .delete(Uri.parse('$baseUrl/$endpoint/$id'))
        .timeout(const Duration(seconds: 15));

    if (deleteResponse.statusCode != 200) {
      final dateLabel = DateFormat('yyyy-MM-dd').format(selectedDate);
      throw Exception('覆蓋 $dateLabel 舊資料失敗：${deleteResponse.statusCode}');
    }
  }

  return idsToDelete.length;
}
