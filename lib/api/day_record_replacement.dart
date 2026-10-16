import 'dart:async';
import 'dart:convert';

import 'package:my_app/api/authenticated_http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_app/gen_l10n/app_localizations.dart';
import 'package:my_app/services/recommendation_invalidation.dart';

class RecordSaveException implements Exception {
  const RecordSaveException(this.code);
  final String code;
}

Future<void> replaceDayRecords({
  required String baseUrl,
  required String endpoint,
  required String userId,
  required DateTime selectedDate,
  required List<Map<String, String>> periods,
  http.Client? client,
  Duration timeout = const Duration(seconds: 90),
}) async {
  final transport = client ?? http.authenticatedClient();
  final body = jsonEncode({
    'user_id': userId,
    'day': DateFormat('yyyy-MM-dd').format(selectedDate),
    'periods': periods,
  });
  try {
    // This endpoint is idempotent. Never fall back to deleting records locally.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await transport
            .post(
              Uri.parse('$baseUrl/$endpoint/replace_day'),
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(timeout);
        if ([502, 503, 504].contains(response.statusCode) && attempt == 0) {
          continue;
        }
        if (response.statusCode == 404 || response.statusCode == 405) {
          throw const RecordSaveException('server_update_required');
        }
        Map<String, dynamic> decoded;
        try {
          decoded =
              jsonDecode(utf8.decode(response.bodyBytes))
                  as Map<String, dynamic>;
        } catch (_) {
          throw const RecordSaveException('server_unavailable');
        }
        if (response.statusCode != 200 || decoded['status'] != 'success') {
          throw RecordSaveException(
            decoded['detail']?.toString() ?? 'save_failed',
          );
        }
        if (decoded['changed'] != false) {
          await invalidateFutureRecommendations(userId: userId);
        }
        return;
      } on TimeoutException {
        if (attempt == 1) throw const RecordSaveException('unconfirmed');
      } on http.ClientException {
        if (attempt == 1) throw const RecordSaveException('unconfirmed');
      }
    }
  } finally {
    if (client == null) transport.close();
  }
}

String recordSaveErrorText(Object error, AppLocalizations l10n) {
  final language = l10n.localeName.split('_').first;
  String text(String zh, String en, String id) =>
      language == 'id'
          ? id
          : language == 'en'
          ? en
          : zh;
  final code = error is RecordSaveException ? error.code : 'unconfirmed';
  switch (code) {
    case 'sleep_wake_overlap':
    case 'periods_overlap':
      return text(
        '時段與其他紀錄重疊，請調整後再儲存。原紀錄未變更。',
        'Periods overlap with another record. Adjust the times and save again. Existing records were not changed.',
        'Waktu bertumpang tindih dengan catatan lain. Sesuaikan lalu simpan lagi. Catatan lama tidak diubah.',
      );
    case 'record_date_mismatch':
      return text(
        '清醒時段的開始日期需與選取日期一致。跨日結束時間可以填在隔天。',
        'The wake period must start on the selected date. It can end on the next day.',
        'Waktu terjaga harus dimulai pada tanggal yang dipilih. Waktu selesai boleh pada hari berikutnya.',
      );
    case 'server_update_required':
      return text(
        '伺服器尚未更新完成，請稍後再試。原紀錄未變更。',
        'The server update is not ready. Please try later. Existing records were not changed.',
        'Pembaruan server belum siap. Coba lagi nanti. Catatan lama tidak diubah.',
      );
    case 'invalid_time_range':
      return l10n.endAfterStart;
    default:
      return text(
        '尚未確認儲存成功，已保留輸入內容。請確認網路後再次儲存；相同內容不會重複新增。',
        'Saving could not be confirmed. Your input is preserved. Check the connection and save again; the same data will not be duplicated.',
        'Penyimpanan belum dapat dikonfirmasi. Isian tetap tersimpan di layar. Periksa koneksi lalu simpan lagi; data yang sama tidak akan digandakan.',
      );
  }
}
