import 'package:my_app/config/app_release.dart';
import 'package:my_app/utils/feedback_text.dart';

class FeedbackDraft {
  static const recipient = String.fromEnvironment(
    'WAKEMATE_FEEDBACK_EMAIL',
    defaultValue: 'wakemateok@gmail.com',
  );
  static const categories = [
    'general',
    'recommendation',
    'notification',
    'account',
    'suggestion',
  ];

  const FeedbackDraft({
    required this.description,
    this.subject = '',
    this.category = 'general',
    this.language = 'zh',
    this.includeVersion = true,
  });
  final String description, subject, category, language;
  final bool includeVersion;

  String get categoryLabel => feedbackText(
    categories.contains(category) ? category : 'general',
    language,
  );
  String get emailSubject {
    final title = subject.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    return '[WakeMate] $categoryLabel${title.isEmpty ? '' : ' - $title'}';
  }

  String get emailBody => [
    '${feedbackText('category', language)}: $categoryLabel',
    '',
    description.trim(),
    if (includeVersion) ...[
      '',
      '---',
      'App: WakeMate',
      'Version: ${AppRelease.label}',
      'Protocol: ${AppRelease.protocol}',
      'Language: $language',
    ],
  ].join('\n');
  String get copyText => '$recipient\n$emailSubject\n\n$emailBody';
  Uri get mailUri => Uri(
    scheme: 'mailto',
    path: recipient,
    // Non-HTTP mail clients require percent-encoded spaces rather than '+'.
    query: {'subject': emailSubject, 'body': emailBody}.entries
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&'),
  );
}
