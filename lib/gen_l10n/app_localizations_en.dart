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
      'Choose a product near NTU Hospital or estimate caffeine manually. Product details are shown in the selected app language when available.';

  @override
  String get loginWelcome => 'Welcome Back';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginSubtitle => 'Enter your Email and password';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginMissingCredentials => 'Please enter Email and password.';

  @override
  String get loginSuccessPrefix => 'Login successful';

  @override
  String get loginMissingUserId =>
      'Login succeeded, but user ID was not returned.';

  @override
  String get loginInvalidCredentials =>
      'Login failed: Email or password is incorrect.';

  @override
  String get loginFailedPrefix => 'Login failed';

  @override
  String get serverUnknownError => 'Unknown server error.';

  @override
  String get serverInvalidResponse =>
      'The server returned an invalid response.';

  @override
  String get serverConnectionError => 'Unable to connect to the server.';

  @override
  String get noAccountPrompt => 'No account yet?';

  @override
  String get registerLink => 'Register here';

  @override
  String get registerPageTitle => 'Create Account';

  @override
  String get registerTitle => 'Create a New Account';

  @override
  String get nameLabel => 'Name';

  @override
  String get registerButton => 'Register';

  @override
  String get registerMissingFields => 'Please fill in all fields.';

  @override
  String get invalidEmailFormat => 'Invalid Email format.';

  @override
  String get registerSuccessLogin => 'Registration successful. Please sign in.';

  @override
  String get registerEmailAlreadyRegistered =>
      'Registration failed: this Email is already registered.';

  @override
  String get registerFailedPrefix => 'Registration failed';

  @override
  String get bodySettingsTitle => 'Body Information';

  @override
  String get genderLabel => 'Gender';

  @override
  String get maleLabel => 'Male';

  @override
  String get femaleLabel => 'Female';

  @override
  String get ageLabel => 'Age';

  @override
  String get ageHint => 'Enter your age';

  @override
  String get ageRequired => 'Age is required.';

  @override
  String get invalidAge => 'Please enter a valid age.';

  @override
  String get heightLabel => 'Height (cm)';

  @override
  String get heightHint => 'Enter your height';

  @override
  String get heightRequired => 'Height is required.';

  @override
  String get invalidHeight => 'Please enter a valid height.';

  @override
  String get weightLabel => 'Weight (kg)';

  @override
  String get weightHint => 'Enter your weight';

  @override
  String get weightRequired => 'Weight is required.';

  @override
  String get invalidWeight => 'Please enter a valid weight.';

  @override
  String get bmiHint => 'BMI will be calculated automatically.';

  @override
  String get saving => 'Saving...';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get settingsSaved => 'Settings saved.';

  @override
  String get settingsSaveFailed => 'Failed to save settings';

  @override
  String get settingsLoadFailed => 'Failed to load data';

  @override
  String get settingsLoadError => 'Data loading error';

  @override
  String get completeRequiredFieldsAndGender =>
      'Please fill in all required fields and select gender.';

  @override
  String get baselineQuestionnaireTitle => 'Baseline Research Questionnaire';

  @override
  String get baselineQuestionnaireBody =>
      'This questionnaire only needs to be completed once at the beginning of the study. If you have already completed it or cannot fill it in now, you may skip it and enter WakeMate.';

  @override
  String get questionnaireReturnInstruction =>
      'After completing the questionnaire, close the browser window and switch back to the WakeMate app.';

  @override
  String get baselineQuestionnaireNotConfigured =>
      'Baseline questionnaire links are not configured yet. You may skip and enter the app for now, or update the links later.';

  @override
  String get skipEnterApp => 'Skip and Enter App';

  @override
  String get linkNotConfiguredSuffix => 'link is not configured yet.';

  @override
  String get unableToOpenPrefix => 'Unable to open';

  @override
  String get chineseBaselineQuestionnaire => 'Chinese Baseline Questionnaire';

  @override
  String get indonesianBaselineQuestionnaire =>
      'Indonesian Baseline Questionnaire';

  @override
  String get chineseDailyQuestionnaire => 'Chinese Daily Questionnaire';

  @override
  String get indonesianDailyQuestionnaire => 'Indonesian Daily Questionnaire';

  @override
  String get notificationCenterTitle => 'Notifications';

  @override
  String get alertnessTapToStart => 'Tap Start';

  @override
  String get alertnessWait => 'Please wait...';

  @override
  String get alertnessTapNow => 'Tap now!';

  @override
  String get alertnessTooEarly => 'Too early. Try again.';

  @override
  String get alertnessTrialPrefix => 'Trial';

  @override
  String get alertnessTrialSuffix => '';

  @override
  String get millisecondsUnit => 'ms';

  @override
  String get alertnessResultTitle => 'Test Result';

  @override
  String get alertnessEachReactionTime => 'Reaction time for each trial:';

  @override
  String get alertnessAverageReactionTime => 'Average reaction time';

  @override
  String get alertnessChooseKss => 'Select your current alertness level (KSS):';

  @override
  String get alertnessChooseKssHint => 'Select KSS score';

  @override
  String get alertnessRetest => 'Test Again';

  @override
  String get alertnessDoneClose => 'Done and Close';

  @override
  String get alertnessDataSent => 'Data submitted successfully.';

  @override
  String get alertnessSubmitFailedStatus => 'Submit failed. Status code:';

  @override
  String get alertnessNetworkSubmitFailed =>
      'Network error. Unable to submit data.';

  @override
  String get tapHere => 'Tap Here';

  @override
  String get startTest => 'Start Test';

  @override
  String get kss1 => 'Extremely alert';

  @override
  String get kss2 => 'Very alert';

  @override
  String get kss3 => 'Alert';

  @override
  String get kss4 => 'Rather alert';

  @override
  String get kss5 => 'Neither alert nor sleepy';

  @override
  String get kss6 => 'Some signs of sleepiness';

  @override
  String get kss7 => 'Sleepy, but no effort to stay awake';

  @override
  String get kss8 => 'Sleepy, some effort to stay awake';

  @override
  String get kss9 => 'Very sleepy, great effort to stay awake';

  @override
  String get notificationChannelName => 'WakeMate reminders';

  @override
  String get notificationChannelDescription =>
      'WakeMate caffeine recommendation and reminder notifications';
}
