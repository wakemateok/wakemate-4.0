import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:my_app/api/taipei_time.dart';

class RecommendationFailure {
  const RecommendationFailure(this.code, [this.detail]);
  final String code;
  final Map<String, dynamic>? detail;

  factory RecommendationFailure.fromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      final value = decoded is Map ? decoded['detail'] ?? decoded : decoded;
      if (value is Map) {
        final detail = Map<String, dynamic>.from(value);
        return RecommendationFailure(
          detail['type']?.toString() ??
              (detail['missing_fields'] != null
                  ? 'missing_inputs'
                  : 'unavailable'),
          detail,
        );
      }
      return RecommendationFailure(
        value == 'sleep_wake_overlap' ? 'sleep_wake_overlap' : 'unavailable',
      );
    } catch (_) {
      return const RecommendationFailure('unavailable');
    }
  }

  String message(String language) {
    String text(String zh, String en, String id) =>
        language.startsWith('id')
            ? id
            : language.startsWith('en')
            ? en
            : zh;
    if (code == 'sleep_wake_overlap') {
      final conflicts = detail?['conflicts'];
      final conflict =
          conflicts is List && conflicts.isNotEmpty && conflicts.first is Map
              ? conflicts.first as Map
              : null;
      String range(dynamic period) {
        if (period is! Map) return '';
        final start = apiTimestampToTaipei(period['start']?.toString());
        final end = apiTimestampToTaipei(period['end']?.toString());
        if (start == null || end == null) return '';
        return '${DateFormat('yyyy/MM/dd HH:mm').format(start)} - ${DateFormat('yyyy/MM/dd HH:mm').format(end)}';
      }

      final sleep = range(conflict?['sleep']), wake = range(conflict?['wake']);
      return [
        text(
          '睡眠與目標清醒時段重疊，推薦尚未更新。這不是清醒時段重複。',
          'Sleep and the target wake period overlap. Recommendations were not updated. This is not a duplicate wake entry.',
          'Waktu tidur dan target terjaga bertumpang tindih. Rekomendasi belum diperbarui. Ini bukan catatan terjaga ganda.',
        ),
        if (sleep.isNotEmpty)
          '${text('睡眠（台北時間）', 'Sleep (Taipei time)', 'Tidur (waktu Taipei)')}: $sleep',
        if (wake.isNotEmpty)
          '${text('清醒（台北時間）', 'Wake period (Taipei time)', 'Terjaga (waktu Taipei)')}: $wake',
        text(
          '請到「輸入歷史」核對並修正；衝突也可能來自之前日期的紀錄。',
          'Check and correct these entries in Input history. A conflict may come from an earlier date.',
          'Periksa dan perbaiki catatan di Riwayat input. Konflik dapat berasal dari tanggal sebelumnya.',
        ),
      ].join('\n');
    }
    if (code == 'missing_inputs')
      return text(
        '缺少睡眠紀錄或目標清醒時段，請補齊後再計算。',
        'Add sleep records and a target wake period before calculating.',
        'Lengkapi catatan tidur dan target terjaga sebelum menghitung.',
      );
    return text(
      '目前無法確認最新推薦，已暫停顯示與提醒。請檢查網路後重新整理；不必重複新增紀錄。',
      'Current recommendations could not be confirmed and are not shown or scheduled. Check your connection and refresh; do not add the same records again.',
      'Rekomendasi terbaru belum dapat dikonfirmasi dan tidak ditampilkan atau dijadwalkan. Periksa koneksi dan muat ulang; jangan menambah catatan yang sama lagi.',
    );
  }
}

RecommendationFailure? findSleepWakeConflict(
  List<Map<String, dynamic>> sleeps,
  List<Map<String, dynamic>> wakes,
) {
  bool active(Map row) =>
      row['is_active'] != false &&
      row['deleted_at'] == null &&
      row['invalidated_at'] == null;
  for (final sleep in sleeps.where(active)) {
    final start = apiTimestampToTaipei(sleep['sleep_start_time']?.toString());
    final end = apiTimestampToTaipei(sleep['sleep_end_time']?.toString());
    if (start == null || end == null) continue;
    for (final wake in wakes.where(active)) {
      final ws = apiTimestampToTaipei(wake['target_start_time']?.toString());
      final we = apiTimestampToTaipei(wake['target_end_time']?.toString());
      if (ws == null || we == null || !ws.isBefore(end) || !we.isAfter(start))
        continue;
      return RecommendationFailure('sleep_wake_overlap', {
        'conflicts': [
          {
            'sleep': {
              'id': sleep['id'],
              'start': sleep['sleep_start_time'],
              'end': sleep['sleep_end_time'],
            },
            'wake': {
              'id': wake['id'],
              'start': wake['target_start_time'],
              'end': wake['target_end_time'],
            },
          },
        ],
      });
    }
  }
  return null;
}
