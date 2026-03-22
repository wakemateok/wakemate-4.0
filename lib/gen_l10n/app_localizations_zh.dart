// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get languageSettingsTitle => '语言设定';

  @override
  String get selectYourLanguage => '选择您的偏好语言';

  @override
  String get caffeineIntake => '咖啡因摄取量';

  @override
  String get sleepDuration => '睡眠时数';

  @override
  String get addRecord => '新增纪录';

  @override
  String get caffeineIntakeToday => '今日咖啡因摄取量';

  @override
  String get sleepDurationToday => '今日睡眠时数';

  @override
  String get unitMg => ' 毫克';

  @override
  String get unitHours => ' 小时';

  @override
  String get wakeTime => '清醒时段';

  @override
  String get sleepTime => '睡眠时段';

  @override
  String get caffeineLog => '咖啡因纪录';

  @override
  String get inputHistory => '输入历史';

  @override
  String get calculateRecommendation => '计算推荐';

  @override
  String get recommendationHistory => '推荐结果';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get languageSettingsTitle => '語言設定';

  @override
  String get selectYourLanguage => '選擇您的偏好語言';

  @override
  String get caffeineIntake => '咖啡因攝取量';

  @override
  String get sleepDuration => '睡眠時數';

  @override
  String get addRecord => '新增紀錄';

  @override
  String get caffeineIntakeToday => '今日咖啡因攝取量';

  @override
  String get sleepDurationToday => '今日睡眠時數';

  @override
  String get unitMg => ' 毫克';

  @override
  String get unitHours => ' 小時';

  @override
  String get wakeTime => '清醒時段';

  @override
  String get sleepTime => '睡眠時段';

  @override
  String get caffeineLog => '咖啡因紀錄';

  @override
  String get inputHistory => '輸入歷史';

  @override
  String get calculateRecommendation => '計算推薦';

  @override
  String get recommendationHistory => '推薦結果';
}
