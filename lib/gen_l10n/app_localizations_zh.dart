// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get languageSettingsTitle => '语言设置';

  @override
  String get selectYourLanguage => '选择您的偏好语言';

  @override
  String get caffeineIntake => '咖啡因摄取';

  @override
  String get sleepDuration => '睡眠时数';

  @override
  String get addRecord => '新增记录';

  @override
  String get caffeineIntakeToday => '今日咖啡因摄取';

  @override
  String get sleepDurationToday => '今日睡眠时数';

  @override
  String get unitMg => ' mg';

  @override
  String get unitHours => ' 小时';

  @override
  String get wakeTime => '清醒时段';

  @override
  String get sleepTime => '睡眠时段';

  @override
  String get caffeineLog => '咖啡因记录';

  @override
  String get inputHistory => '输入历史';

  @override
  String get calculateRecommendation => '计算推荐';

  @override
  String get recommendationHistory => '推荐记录';

  @override
  String get dailyQuestionnaire => '每日问卷';

  @override
  String get personalSettings => '个人设置';

  @override
  String get alertnessTest => '清醒度测试';

  @override
  String get logout => '登出';

  @override
  String get userFallback => '用户';

  @override
  String get addData => '新增资料';

  @override
  String get targetWakePeriod => '目标清醒时段';

  @override
  String get actualSleepPeriod => '实际睡眠周期';

  @override
  String get addCaffeineRecord => '新增咖啡因记录';

  @override
  String get dailyQuestionnaireReminder => '每日问卷提醒';

  @override
  String get dailyQuestionnaireMessage => '请依照今天的状况填写每日问卷。已填过或想晚点填，可以先略过。';

  @override
  String get remindLater => '稍后提醒';

  @override
  String get skipToday => '今天先略过';

  @override
  String get questionnaireLoading => '每日问卷链接载入中，请稍后再试';

  @override
  String get questionnaireNotConfigured => '尚未设置问卷链接';

  @override
  String get openFailed => '无法打开链接';

  @override
  String get allInputHistory => '全部输入历史';

  @override
  String get allInputHistorySubtitle => '目前显示所有有效记录，可在这里编辑或删除旧资料。';

  @override
  String get historyLoading => '正在读取输入历史...';

  @override
  String get noInputRecords => '目前没有输入记录';

  @override
  String get noSleepRecords => '尚无睡眠记录';

  @override
  String get noWakeRecords => '尚无目标清醒时段';

  @override
  String get noCaffeineRecords => '尚无咖啡因记录';

  @override
  String get startTime => '开始时间';

  @override
  String get endTime => '结束时间';

  @override
  String get drinkingTime => '饮用时间';

  @override
  String get drinkName => '饮品名称';

  @override
  String get caffeineAmountMg => '咖啡因含量 mg';

  @override
  String get duration => '总时长';

  @override
  String get hours => '小时';

  @override
  String get minutes => '分钟';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get deleteConfirmMessage => '确定要删除这笔资料吗？删除后后端会重新计算。';

  @override
  String get chooseDateTime => '选择日期时间';

  @override
  String get dateTimeHelper => '可手动输入，例如 2026-06-23 19:30';

  @override
  String get invalidDateTimeFormat => '请使用 yyyy-MM-dd HH:mm 格式';

  @override
  String get endAfterStart => '结束时间必须晚于开始时间';

  @override
  String get updated => '资料已更新';

  @override
  String get deleted => '资料已删除';

  @override
  String get updateFailed => '更新失败';

  @override
  String get deleteFailed => '删除失败';

  @override
  String get networkError => '网络错误';

  @override
  String get wakePageTitle => '设置目标清醒时段';

  @override
  String get wakeInstruction => '请输入希望保持清醒或专注的时段。若要测试推荐，可输入未来时段。';

  @override
  String get wakeSlot => '清醒时段';

  @override
  String get addWakeSlot => '新增时段';

  @override
  String get saveWakeSlots => '保存目标清醒时段';

  @override
  String get wakeSaveSuccess => '目标清醒时段已保存';

  @override
  String get wakeSavePartial => '部分目标清醒时段未成功保存';

  @override
  String get wakeSaveFailed => '目标清醒时段保存失败';

  @override
  String get deleteOldRecordsWarning => '旧资料清除失败，但新资料仍已尝试送出。如有重复，请到输入历史删除。';

  @override
  String get sleepPageTitle => '新增实际睡眠周期';

  @override
  String get sleepInstruction => '请输入实际入睡时间与最后起床时间。';

  @override
  String get sleepStart => '入睡时间';

  @override
  String get sleepEnd => '起床时间';

  @override
  String get saveSleep => '保存睡眠周期';

  @override
  String get sleepTooLong => '睡眠周期不可超过 48 小时';

  @override
  String get sleepSaveSuccess => '睡眠周期已保存';

  @override
  String get sleepSaveFailed => '睡眠周期保存失败';

  @override
  String get recommendationTitle => '咖啡因推荐';

  @override
  String get calculatingRecommendation => '正在计算咖啡因推荐...';

  @override
  String get recommendationNote => '如果 Render 服务正在唤醒，可能需要等一下。';

  @override
  String get recommendationFetched => '推荐结果已更新';

  @override
  String get recommendationFailed => '推荐计算失败';

  @override
  String get noRecommendationTitle => '目前没有推荐结果';

  @override
  String get noRecommendationBody =>
      '请确认已保存未来的目标清醒时段与实际睡眠周期。如果模型判断清醒度已足够，也可能不产生咖啡因推荐。';

  @override
  String get retry => '重试';

  @override
  String get back => '返回';

  @override
  String get recommendationItem => '咖啡因推荐';

  @override
  String get recommendedTiming => '推荐时间';

  @override
  String get recommendedAmount => '推荐剂量';

  @override
  String get calculateAgain => '重新计算';

  @override
  String get noRecommendationsForDate => '这一天没有推荐结果';

  @override
  String get productCatalog => '商品清单';

  @override
  String get manualEstimate => '手动估算';

  @override
  String get chooseStore => '选择店家';

  @override
  String get chooseProduct => '选择商品';

  @override
  String get source => '资料来源';

  @override
  String get estimateCaffeine => '估算咖啡因';

  @override
  String get chooseDrinkType => '选择饮品类型';

  @override
  String get chooseAmount => '选择份量';

  @override
  String get strength => '浓淡';

  @override
  String get light => '较淡';

  @override
  String get normal => '一般';

  @override
  String get strong => '较浓';

  @override
  String get uncertainAmount => '份量不确定';

  @override
  String get uncertainAmountHelp => '若容量或浓淡只是约略估算，请开启此选项。';

  @override
  String get otherDrink => '其他饮品';

  @override
  String get manualInput => '手动输入';

  @override
  String get saveCaffeine => '保存咖啡因记录';

  @override
  String get caffeineSaveSuccess => '咖啡因记录已保存';

  @override
  String get caffeineSaveFailed => '咖啡因记录保存失败';

  @override
  String get enterDrinkingTime => '请输入饮用时间';

  @override
  String get enterPositiveCaffeine => '请输入大于 0 的咖啡因含量';

  @override
  String get caffeineIntro => '可选择台大医院附近商品，或手动估算咖啡因。商品名称会保留原始标示。';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get languageSettingsTitle => '語言設定';

  @override
  String get selectYourLanguage => '選擇您的偏好語言';

  @override
  String get caffeineIntake => '咖啡因攝取';

  @override
  String get sleepDuration => '睡眠時數';

  @override
  String get addRecord => '新增紀錄';

  @override
  String get caffeineIntakeToday => '今日咖啡因攝取';

  @override
  String get sleepDurationToday => '今日睡眠時數';

  @override
  String get unitMg => ' mg';

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
  String get recommendationHistory => '推薦紀錄';

  @override
  String get dailyQuestionnaire => '每日問卷';

  @override
  String get personalSettings => '個人設定';

  @override
  String get alertnessTest => '清醒度測試';

  @override
  String get logout => '登出';

  @override
  String get userFallback => '用戶';

  @override
  String get addData => '新增資料';

  @override
  String get targetWakePeriod => '目標清醒時段';

  @override
  String get actualSleepPeriod => '實際睡眠週期';

  @override
  String get addCaffeineRecord => '新增咖啡因紀錄';

  @override
  String get dailyQuestionnaireReminder => '每日問卷提醒';

  @override
  String get dailyQuestionnaireMessage => '請依照今天的狀況填寫每日問卷。已填過或想晚點填，可以先略過。';

  @override
  String get remindLater => '稍後提醒';

  @override
  String get skipToday => '今天先略過';

  @override
  String get questionnaireLoading => '每日問卷連結載入中，請稍後再試';

  @override
  String get questionnaireNotConfigured => '尚未設定問卷連結';

  @override
  String get openFailed => '無法開啟連結';

  @override
  String get allInputHistory => '全部輸入歷史';

  @override
  String get allInputHistorySubtitle => '目前顯示所有有效紀錄，可在這裡編輯或刪除舊資料。';

  @override
  String get historyLoading => '正在讀取輸入歷史...';

  @override
  String get noInputRecords => '目前沒有輸入紀錄';

  @override
  String get noSleepRecords => '尚無睡眠紀錄';

  @override
  String get noWakeRecords => '尚無目標清醒時段';

  @override
  String get noCaffeineRecords => '尚無咖啡因紀錄';

  @override
  String get startTime => '開始時間';

  @override
  String get endTime => '結束時間';

  @override
  String get drinkingTime => '飲用時間';

  @override
  String get drinkName => '飲品名稱';

  @override
  String get caffeineAmountMg => '咖啡因含量 mg';

  @override
  String get duration => '總時長';

  @override
  String get hours => '小時';

  @override
  String get minutes => '分鐘';

  @override
  String get edit => '編輯';

  @override
  String get delete => '刪除';

  @override
  String get save => '儲存';

  @override
  String get cancel => '取消';

  @override
  String get confirmDelete => '確認刪除';

  @override
  String get deleteConfirmMessage => '確定要刪除這筆資料嗎？刪除後後端會重新計算。';

  @override
  String get chooseDateTime => '選擇日期時間';

  @override
  String get dateTimeHelper => '可手動輸入，例如 2026-06-23 19:30';

  @override
  String get invalidDateTimeFormat => '請使用 yyyy-MM-dd HH:mm 格式';

  @override
  String get endAfterStart => '結束時間必須晚於開始時間';

  @override
  String get updated => '資料已更新';

  @override
  String get deleted => '資料已刪除';

  @override
  String get updateFailed => '更新失敗';

  @override
  String get deleteFailed => '刪除失敗';

  @override
  String get networkError => '網路錯誤';

  @override
  String get wakePageTitle => '設定目標清醒時段';

  @override
  String get wakeInstruction => '請輸入希望保持清醒或專注的時段。若要測試推薦，可輸入未來時段。';

  @override
  String get wakeSlot => '清醒時段';

  @override
  String get addWakeSlot => '新增時段';

  @override
  String get saveWakeSlots => '儲存目標清醒時段';

  @override
  String get wakeSaveSuccess => '目標清醒時段已儲存';

  @override
  String get wakeSavePartial => '部分目標清醒時段未成功儲存';

  @override
  String get wakeSaveFailed => '目標清醒時段儲存失敗';

  @override
  String get deleteOldRecordsWarning => '舊資料清除失敗，但新資料仍已嘗試送出。如有重複，請到輸入歷史刪除。';

  @override
  String get sleepPageTitle => '新增實際睡眠週期';

  @override
  String get sleepInstruction => '請輸入實際入睡時間與最後起床時間。';

  @override
  String get sleepStart => '入睡時間';

  @override
  String get sleepEnd => '起床時間';

  @override
  String get saveSleep => '儲存睡眠週期';

  @override
  String get sleepTooLong => '睡眠週期不可超過 48 小時';

  @override
  String get sleepSaveSuccess => '睡眠週期已儲存';

  @override
  String get sleepSaveFailed => '睡眠週期儲存失敗';

  @override
  String get recommendationTitle => '咖啡因推薦';

  @override
  String get calculatingRecommendation => '正在計算咖啡因推薦...';

  @override
  String get recommendationNote => '如果 Render 服務正在喚醒，可能需要等一下。';

  @override
  String get recommendationFetched => '推薦結果已更新';

  @override
  String get recommendationFailed => '推薦計算失敗';

  @override
  String get noRecommendationTitle => '目前沒有推薦結果';

  @override
  String get noRecommendationBody =>
      '請確認已儲存未來的目標清醒時段與實際睡眠週期。如果模型判斷清醒度已足夠，也可能不產生咖啡因推薦。';

  @override
  String get retry => '重試';

  @override
  String get back => '返回';

  @override
  String get recommendationItem => '咖啡因推薦';

  @override
  String get recommendedTiming => '推薦時間';

  @override
  String get recommendedAmount => '推薦劑量';

  @override
  String get calculateAgain => '重新計算';

  @override
  String get noRecommendationsForDate => '這一天沒有推薦結果';

  @override
  String get productCatalog => '商品清單';

  @override
  String get manualEstimate => '手動估算';

  @override
  String get chooseStore => '選擇店家';

  @override
  String get chooseProduct => '選擇商品';

  @override
  String get source => '資料來源';

  @override
  String get estimateCaffeine => '估算咖啡因';

  @override
  String get chooseDrinkType => '選擇飲品類型';

  @override
  String get chooseAmount => '選擇份量';

  @override
  String get strength => '濃淡';

  @override
  String get light => '較淡';

  @override
  String get normal => '一般';

  @override
  String get strong => '較濃';

  @override
  String get uncertainAmount => '份量不確定';

  @override
  String get uncertainAmountHelp => '若容量或濃淡只是約略估算，請開啟此選項。';

  @override
  String get otherDrink => '其他飲品';

  @override
  String get manualInput => '手動輸入';

  @override
  String get saveCaffeine => '儲存咖啡因紀錄';

  @override
  String get caffeineSaveSuccess => '咖啡因紀錄已儲存';

  @override
  String get caffeineSaveFailed => '咖啡因紀錄儲存失敗';

  @override
  String get enterDrinkingTime => '請輸入飲用時間';

  @override
  String get enterPositiveCaffeine => '請輸入大於 0 的咖啡因含量';

  @override
  String get caffeineIntro => '可選擇台大醫院附近商品，或手動估算咖啡因。商品名稱會保留原始標示。';
}
