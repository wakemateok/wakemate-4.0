import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:my_app/api/api_config.dart';

enum QuestionnaireLinkKind {
  chineseBaseline,
  indonesianBaseline,
  chineseDaily,
  indonesianDaily,
}

class QuestionnaireLinkEntry {
  final QuestionnaireLinkKind kind;
  final String url;

  const QuestionnaireLinkEntry({required this.kind, required this.url});

  bool get hasUrl => url.trim().isNotEmpty;
}

class QuestionnaireLinkSet {
  final String chineseBaselineUrl;
  final String chineseDailyUrl;
  final String indonesianBaselineUrl;
  final String indonesianDailyUrl;
  final String version;

  const QuestionnaireLinkSet({
    required this.chineseBaselineUrl,
    required this.chineseDailyUrl,
    required this.indonesianBaselineUrl,
    required this.indonesianDailyUrl,
    required this.version,
  });

  bool get hasAnyLink => allEntries.any((entry) => entry.hasUrl);
  bool get hasBaselineLink => baselineEntries.any((entry) => entry.hasUrl);
  bool get hasDailyLink => dailyEntries.any((entry) => entry.hasUrl);

  List<QuestionnaireLinkEntry> get baselineEntries => [
    QuestionnaireLinkEntry(
      kind: QuestionnaireLinkKind.chineseBaseline,
      url: chineseBaselineUrl,
    ),
    QuestionnaireLinkEntry(
      kind: QuestionnaireLinkKind.indonesianBaseline,
      url: indonesianBaselineUrl,
    ),
  ];

  List<QuestionnaireLinkEntry> get dailyEntries => [
    QuestionnaireLinkEntry(
      kind: QuestionnaireLinkKind.chineseDaily,
      url: chineseDailyUrl,
    ),
    QuestionnaireLinkEntry(
      kind: QuestionnaireLinkKind.indonesianDaily,
      url: indonesianDailyUrl,
    ),
  ];

  List<QuestionnaireLinkEntry> get allEntries => [
    ...baselineEntries,
    ...dailyEntries,
  ];

  factory QuestionnaireLinkSet.fromJson(Map<String, dynamic> json) {
    return QuestionnaireLinkSet(
      chineseBaselineUrl:
          (json['chinese_baseline_url'] ?? json['chinese_url'] ?? '')
              .toString()
              .trim(),
      chineseDailyUrl: (json['chinese_daily_url'] ?? '').toString().trim(),
      indonesianBaselineUrl:
          (json['indonesian_baseline_url'] ?? json['indonesian_url'] ?? '')
              .toString()
              .trim(),
      indonesianDailyUrl:
          (json['indonesian_daily_url'] ?? '').toString().trim(),
      version: (json['version'] ?? 'v1').toString().trim(),
    );
  }

  QuestionnaireLinkSet mergeFallback(QuestionnaireLinkSet fallback) {
    return QuestionnaireLinkSet(
      chineseBaselineUrl:
          chineseBaselineUrl.isNotEmpty
              ? chineseBaselineUrl
              : fallback.chineseBaselineUrl,
      chineseDailyUrl:
          chineseDailyUrl.isNotEmpty
              ? chineseDailyUrl
              : fallback.chineseDailyUrl,
      indonesianBaselineUrl:
          indonesianBaselineUrl.isNotEmpty
              ? indonesianBaselineUrl
              : fallback.indonesianBaselineUrl,
      indonesianDailyUrl:
          indonesianDailyUrl.isNotEmpty
              ? indonesianDailyUrl
              : fallback.indonesianDailyUrl,
      version: version.isNotEmpty ? version : fallback.version,
    );
  }
}

class QuestionnaireLinks {
  static const fallback = QuestionnaireLinkSet(
    chineseBaselineUrl:
        'https://docs.google.com/forms/d/e/1FAIpQLSckT9vKtjdIVlUOE8Me4Ycxyp6pB7TGWbCdzQB9fs7Ra8Yb-g/viewform',
    chineseDailyUrl:
        'https://docs.google.com/forms/d/e/1FAIpQLSeQ4jpqR_cKy5FFA9KxSFQxYTimu03GVpuaeL7xO3Zc-nFlQA/viewform',
    indonesianBaselineUrl:
        'https://docs.google.com/forms/d/e/1FAIpQLSdSUK-r6DdsP2vUenKhr7PSuiv_XWcD-pe1cdjGq076ChlC9w/viewform',
    indonesianDailyUrl:
        'https://docs.google.com/forms/d/e/1FAIpQLSdhx0TmP3g-sgDQhbBAg_N5dGCjdGcvEJbA71IOiVEmh9soaQ/viewform',
    version: '20260708-split-v1',
  );

  static Future<QuestionnaireLinkSet> fetch() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/questionnaire_links/'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        return fallback;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return fallback;
      }

      return QuestionnaireLinkSet.fromJson(decoded).mergeFallback(fallback);
    } catch (_) {
      return fallback;
    }
  }
}
