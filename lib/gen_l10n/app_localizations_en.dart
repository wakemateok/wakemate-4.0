// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageSettingsTitle => 'Language Settings';

  @override
  String get selectYourLanguage => 'Select your preferred language';

  @override
  String get caffeineIntake => 'Caffeine Intake';

  @override
  String get sleepDuration => 'Sleep Duration';

  @override
  String get addRecord => 'Add Record';

  @override
  String get caffeineIntakeToday => 'Today\'s Caffeine Intake';

  @override
  String get sleepDurationToday => 'Today\'s Sleep Duration';

  @override
  String get unitMg => ' mg';

  @override
  String get unitHours => ' hours';

  @override
  String get wakeTime => 'Wake Time';

  @override
  String get sleepTime => 'Sleep Time';

  @override
  String get caffeineLog => 'Caffeine Log';

  @override
  String get inputHistory => 'Input History';

  @override
  String get calculateRecommendation => 'Calculate';

  @override
  String get recommendationHistory => 'History';

  @override
  String get dailyQuestionnaire => 'Daily Questionnaire';

  @override
  String get personalSettings => 'Personal Settings';

  @override
  String get alertnessTest => 'Alertness Test';

  @override
  String get logout => 'Log Out';

  @override
  String get userFallback => 'User';

  @override
  String get addData => 'Add Data';

  @override
  String get targetWakePeriod => 'Target Wake Period';

  @override
  String get actualSleepPeriod => 'Actual Sleep Period';

  @override
  String get addCaffeineRecord => 'Add Caffeine Record';

  @override
  String get dailyQuestionnaireReminder => 'Daily Questionnaire Reminder';

  @override
  String get dailyQuestionnaireMessage =>
      'Please fill in today\'s daily questionnaire. If you have completed it or want to do it later, you can skip it for now.';

  @override
  String get remindLater => 'Remind Later';

  @override
  String get skipToday => 'Skip Today';

  @override
  String get questionnaireLoading =>
      'Questionnaire links are loading. Please try again later.';

  @override
  String get questionnaireNotConfigured =>
      'Questionnaire link is not configured yet.';

  @override
  String get openFailed => 'Unable to open the link.';

  @override
  String get allInputHistory => 'All Input History';

  @override
  String get allInputHistorySubtitle =>
      'Showing all active records. You can edit or delete old entries here.';

  @override
  String get historyLoading => 'Loading input history...';

  @override
  String get noInputRecords => 'No input records found.';

  @override
  String get noSleepRecords => 'No sleep records';

  @override
  String get noWakeRecords => 'No target wake periods';

  @override
  String get noCaffeineRecords => 'No caffeine records';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get drinkingTime => 'Drinking Time';

  @override
  String get drinkName => 'Drink Name';

  @override
  String get caffeineAmountMg => 'Caffeine Amount (mg)';

  @override
  String get duration => 'Duration';

  @override
  String get hours => 'hours';

  @override
  String get minutes => 'minutes';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get deleteConfirmMessage =>
      'Delete this record? The backend will recalculate after deletion.';

  @override
  String get chooseDateTime => 'Choose date and time';

  @override
  String get dateTimeHelper => 'You can type manually, e.g. 2026-06-23 19:30';

  @override
  String get invalidDateTimeFormat => 'Please use yyyy-MM-dd HH:mm format.';

  @override
  String get endAfterStart => 'End time must be later than start time.';

  @override
  String get updated => 'Updated.';

  @override
  String get deleted => 'Deleted.';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get networkError => 'Network error';

  @override
  String get wakePageTitle => 'Set Target Wake Period';

  @override
  String get wakeInstruction =>
      'Enter the time period when you need to stay awake or focused. Future periods can be used for recommendation testing.';

  @override
  String get wakeSlot => 'Wake Period';

  @override
  String get addWakeSlot => 'Add Period';

  @override
  String get saveWakeSlots => 'Save Target Wake Period';

  @override
  String get wakeSaveSuccess => 'Target wake period saved.';

  @override
  String get wakeSavePartial => 'Some target wake periods were not saved.';

  @override
  String get wakeSaveFailed => 'Failed to save target wake period.';

  @override
  String get deleteOldRecordsWarning =>
      'Old records could not be cleared, but the new record was still submitted. Please remove duplicates from input history if needed.';

  @override
  String get sleepPageTitle => 'Add Actual Sleep Period';

  @override
  String get sleepInstruction =>
      'Enter when you actually fell asleep and when you finally woke up.';

  @override
  String get sleepStart => 'Sleep Start';

  @override
  String get sleepEnd => 'Sleep End';

  @override
  String get saveSleep => 'Save Sleep Period';

  @override
  String get sleepTooLong => 'Sleep period cannot exceed 48 hours.';

  @override
  String get sleepSaveSuccess => 'Sleep period saved.';

  @override
  String get sleepSaveFailed => 'Failed to save sleep period.';

  @override
  String get recommendationTitle => 'Caffeine Recommendation';

  @override
  String get calculatingRecommendation =>
      'Calculating caffeine recommendation...';

  @override
  String get recommendationNote =>
      'This may take a moment if the server is waking up.';

  @override
  String get recommendationFetched => 'Recommendation updated.';

  @override
  String get recommendationFailed => 'Recommendation failed';

  @override
  String get noRecommendationTitle => 'No recommendation yet';

  @override
  String get noRecommendationBody =>
      'Make sure future target wake period and actual sleep period have been saved. If alertness is predicted to be acceptable, the model may return no caffeine recommendation.';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get recommendationItem => 'Caffeine Recommendation';

  @override
  String get recommendedTiming => 'Recommended Time';

  @override
  String get recommendedAmount => 'Recommended Amount';

  @override
  String get calculateAgain => 'Recalculate';

  @override
  String get noRecommendationsForDate => 'No recommendation for this date.';

  @override
  String get productCatalog => 'Product Catalog';

  @override
  String get manualEstimate => 'Manual Estimate';

  @override
  String get chooseStore => 'Choose Store';

  @override
  String get chooseProduct => 'Choose Product';

  @override
  String get source => 'Source';

  @override
  String get estimateCaffeine => 'Estimated Caffeine';

  @override
  String get chooseDrinkType => 'Choose Drink Type';

  @override
  String get chooseAmount => 'Choose Amount';

  @override
  String get strength => 'Strength';

  @override
  String get light => 'Light';

  @override
  String get normal => 'Normal';

  @override
  String get strong => 'Strong';

  @override
  String get uncertainAmount => 'The amount is uncertain';

  @override
  String get uncertainAmountHelp =>
      'Mark this when the serving size or concentration is only approximate.';

  @override
  String get otherDrink => 'Other Drink';

  @override
  String get manualInput => 'Manual Input';

  @override
  String get saveCaffeine => 'Save Caffeine Record';

  @override
  String get caffeineSaveSuccess => 'Caffeine record saved.';

  @override
  String get caffeineSaveFailed => 'Failed to save caffeine record.';

  @override
  String get enterDrinkingTime => 'Please enter drinking time.';

  @override
  String get enterPositiveCaffeine =>
      'Please enter a caffeine amount greater than 0.';

  @override
  String get caffeineIntro =>
      'Choose a product near NTU Hospital or estimate caffeine manually. Product names are kept as shown on the source label.';
}
