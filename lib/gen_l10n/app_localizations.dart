import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @languageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettingsTitle;

  /// No description provided for @selectYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectYourLanguage;

  /// No description provided for @caffeineIntake.
  ///
  /// In en, this message translates to:
  /// **'Caffeine Intake'**
  String get caffeineIntake;

  /// No description provided for @sleepDuration.
  ///
  /// In en, this message translates to:
  /// **'Sleep Duration'**
  String get sleepDuration;

  /// No description provided for @addRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get addRecord;

  /// No description provided for @caffeineIntakeToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Caffeine Intake'**
  String get caffeineIntakeToday;

  /// No description provided for @sleepDurationToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sleep Duration'**
  String get sleepDurationToday;

  /// No description provided for @unitMg.
  ///
  /// In en, this message translates to:
  /// **' mg'**
  String get unitMg;

  /// No description provided for @unitHours.
  ///
  /// In en, this message translates to:
  /// **' hours'**
  String get unitHours;

  /// No description provided for @wakeTime.
  ///
  /// In en, this message translates to:
  /// **'Wake Time'**
  String get wakeTime;

  /// No description provided for @sleepTime.
  ///
  /// In en, this message translates to:
  /// **'Sleep Time'**
  String get sleepTime;

  /// No description provided for @caffeineLog.
  ///
  /// In en, this message translates to:
  /// **'Caffeine Log'**
  String get caffeineLog;

  /// No description provided for @inputHistory.
  ///
  /// In en, this message translates to:
  /// **'Input History'**
  String get inputHistory;

  /// No description provided for @calculateRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculateRecommendation;

  /// No description provided for @recommendationHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get recommendationHistory;

  /// No description provided for @dailyQuestionnaire.
  ///
  /// In en, this message translates to:
  /// **'Daily Questionnaire'**
  String get dailyQuestionnaire;

  /// No description provided for @personalSettings.
  ///
  /// In en, this message translates to:
  /// **'Personal Settings'**
  String get personalSettings;

  /// No description provided for @alertnessTest.
  ///
  /// In en, this message translates to:
  /// **'Alertness Test'**
  String get alertnessTest;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @userFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userFallback;

  /// No description provided for @addData.
  ///
  /// In en, this message translates to:
  /// **'Add Data'**
  String get addData;

  /// No description provided for @targetWakePeriod.
  ///
  /// In en, this message translates to:
  /// **'Target Wake Period'**
  String get targetWakePeriod;

  /// No description provided for @actualSleepPeriod.
  ///
  /// In en, this message translates to:
  /// **'Actual Sleep Period'**
  String get actualSleepPeriod;

  /// No description provided for @addCaffeineRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Caffeine Record'**
  String get addCaffeineRecord;

  /// No description provided for @dailyQuestionnaireReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Questionnaire Reminder'**
  String get dailyQuestionnaireReminder;

  /// No description provided for @dailyQuestionnaireMessage.
  ///
  /// In en, this message translates to:
  /// **'Please fill in today\'s daily questionnaire. If you have completed it or want to do it later, you can skip it for now.'**
  String get dailyQuestionnaireMessage;

  /// No description provided for @remindLater.
  ///
  /// In en, this message translates to:
  /// **'Remind Later'**
  String get remindLater;

  /// No description provided for @skipToday.
  ///
  /// In en, this message translates to:
  /// **'Skip Today'**
  String get skipToday;

  /// No description provided for @questionnaireLoading.
  ///
  /// In en, this message translates to:
  /// **'Questionnaire links are loading. Please try again later.'**
  String get questionnaireLoading;

  /// No description provided for @questionnaireNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Questionnaire link is not configured yet.'**
  String get questionnaireNotConfigured;

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the link.'**
  String get openFailed;

  /// No description provided for @allInputHistory.
  ///
  /// In en, this message translates to:
  /// **'All Input History'**
  String get allInputHistory;

  /// No description provided for @allInputHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Showing all active records. You can edit or delete old entries here.'**
  String get allInputHistorySubtitle;

  /// No description provided for @historyLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading input history...'**
  String get historyLoading;

  /// No description provided for @noInputRecords.
  ///
  /// In en, this message translates to:
  /// **'No input records found.'**
  String get noInputRecords;

  /// No description provided for @noSleepRecords.
  ///
  /// In en, this message translates to:
  /// **'No sleep records'**
  String get noSleepRecords;

  /// No description provided for @noWakeRecords.
  ///
  /// In en, this message translates to:
  /// **'No target wake periods'**
  String get noWakeRecords;

  /// No description provided for @noCaffeineRecords.
  ///
  /// In en, this message translates to:
  /// **'No caffeine records'**
  String get noCaffeineRecords;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @drinkingTime.
  ///
  /// In en, this message translates to:
  /// **'Drinking Time'**
  String get drinkingTime;

  /// No description provided for @drinkName.
  ///
  /// In en, this message translates to:
  /// **'Drink Name'**
  String get drinkName;

  /// No description provided for @caffeineAmountMg.
  ///
  /// In en, this message translates to:
  /// **'Caffeine Amount (mg)'**
  String get caffeineAmountMg;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this record? The backend will recalculate after deletion.'**
  String get deleteConfirmMessage;

  /// No description provided for @chooseDateTime.
  ///
  /// In en, this message translates to:
  /// **'Choose date and time'**
  String get chooseDateTime;

  /// No description provided for @dateTimeHelper.
  ///
  /// In en, this message translates to:
  /// **'You can type manually, e.g. 2026-06-23 19:30'**
  String get dateTimeHelper;

  /// No description provided for @invalidDateTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Please use yyyy-MM-dd HH:mm format.'**
  String get invalidDateTimeFormat;

  /// No description provided for @endAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be later than start time.'**
  String get endAfterStart;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated.'**
  String get updated;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get deleted;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @wakePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Target Wake Period'**
  String get wakePageTitle;

  /// No description provided for @wakeInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter the time period when you need to stay awake or focused. Future periods can be used for recommendation testing.'**
  String get wakeInstruction;

  /// No description provided for @wakeSlot.
  ///
  /// In en, this message translates to:
  /// **'Wake Period'**
  String get wakeSlot;

  /// No description provided for @addWakeSlot.
  ///
  /// In en, this message translates to:
  /// **'Add Period'**
  String get addWakeSlot;

  /// No description provided for @saveWakeSlots.
  ///
  /// In en, this message translates to:
  /// **'Save Target Wake Period'**
  String get saveWakeSlots;

  /// No description provided for @wakeSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Target wake period saved.'**
  String get wakeSaveSuccess;

  /// No description provided for @wakeSavePartial.
  ///
  /// In en, this message translates to:
  /// **'Some target wake periods were not saved.'**
  String get wakeSavePartial;

  /// No description provided for @wakeSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save target wake period.'**
  String get wakeSaveFailed;

  /// No description provided for @deleteOldRecordsWarning.
  ///
  /// In en, this message translates to:
  /// **'Old records could not be cleared, but the new record was still submitted. Please remove duplicates from input history if needed.'**
  String get deleteOldRecordsWarning;

  /// No description provided for @sleepPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Actual Sleep Period'**
  String get sleepPageTitle;

  /// No description provided for @sleepInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter when you actually fell asleep and when you finally woke up.'**
  String get sleepInstruction;

  /// No description provided for @sleepStart.
  ///
  /// In en, this message translates to:
  /// **'Sleep Start'**
  String get sleepStart;

  /// No description provided for @sleepEnd.
  ///
  /// In en, this message translates to:
  /// **'Sleep End'**
  String get sleepEnd;

  /// No description provided for @saveSleep.
  ///
  /// In en, this message translates to:
  /// **'Save Sleep Period'**
  String get saveSleep;

  /// No description provided for @sleepTooLong.
  ///
  /// In en, this message translates to:
  /// **'Sleep period cannot exceed 48 hours.'**
  String get sleepTooLong;

  /// No description provided for @sleepSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sleep period saved.'**
  String get sleepSaveSuccess;

  /// No description provided for @sleepSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save sleep period.'**
  String get sleepSaveFailed;

  /// No description provided for @recommendationTitle.
  ///
  /// In en, this message translates to:
  /// **'Caffeine Recommendation'**
  String get recommendationTitle;

  /// No description provided for @calculatingRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Calculating caffeine recommendation...'**
  String get calculatingRecommendation;

  /// No description provided for @recommendationNote.
  ///
  /// In en, this message translates to:
  /// **'This may take a moment if the server is waking up.'**
  String get recommendationNote;

  /// No description provided for @recommendationFetched.
  ///
  /// In en, this message translates to:
  /// **'Recommendation updated.'**
  String get recommendationFetched;

  /// No description provided for @recommendationFailed.
  ///
  /// In en, this message translates to:
  /// **'Recommendation failed'**
  String get recommendationFailed;

  /// No description provided for @noRecommendationTitle.
  ///
  /// In en, this message translates to:
  /// **'No recommendation yet'**
  String get noRecommendationTitle;

  /// No description provided for @noRecommendationBody.
  ///
  /// In en, this message translates to:
  /// **'Make sure future target wake period and actual sleep period have been saved. If alertness is predicted to be acceptable, the model may return no caffeine recommendation.'**
  String get noRecommendationBody;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @recommendationItem.
  ///
  /// In en, this message translates to:
  /// **'Caffeine Recommendation'**
  String get recommendationItem;

  /// No description provided for @recommendedTiming.
  ///
  /// In en, this message translates to:
  /// **'Recommended Time'**
  String get recommendedTiming;

  /// No description provided for @recommendedAmount.
  ///
  /// In en, this message translates to:
  /// **'Recommended Amount'**
  String get recommendedAmount;

  /// No description provided for @calculateAgain.
  ///
  /// In en, this message translates to:
  /// **'Recalculate'**
  String get calculateAgain;

  /// No description provided for @noRecommendationsForDate.
  ///
  /// In en, this message translates to:
  /// **'No recommendation for this date.'**
  String get noRecommendationsForDate;

  /// No description provided for @productCatalog.
  ///
  /// In en, this message translates to:
  /// **'Product Catalog'**
  String get productCatalog;

  /// No description provided for @manualEstimate.
  ///
  /// In en, this message translates to:
  /// **'Manual Estimate'**
  String get manualEstimate;

  /// No description provided for @chooseStore.
  ///
  /// In en, this message translates to:
  /// **'Choose Store'**
  String get chooseStore;

  /// No description provided for @chooseProduct.
  ///
  /// In en, this message translates to:
  /// **'Choose Product'**
  String get chooseProduct;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @estimateCaffeine.
  ///
  /// In en, this message translates to:
  /// **'Estimated Caffeine'**
  String get estimateCaffeine;

  /// No description provided for @chooseDrinkType.
  ///
  /// In en, this message translates to:
  /// **'Choose Drink Type'**
  String get chooseDrinkType;

  /// No description provided for @chooseAmount.
  ///
  /// In en, this message translates to:
  /// **'Choose Amount'**
  String get chooseAmount;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get strength;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @uncertainAmount.
  ///
  /// In en, this message translates to:
  /// **'The amount is uncertain'**
  String get uncertainAmount;

  /// No description provided for @uncertainAmountHelp.
  ///
  /// In en, this message translates to:
  /// **'Mark this when the serving size or concentration is only approximate.'**
  String get uncertainAmountHelp;

  /// No description provided for @otherDrink.
  ///
  /// In en, this message translates to:
  /// **'Other Drink'**
  String get otherDrink;

  /// No description provided for @manualInput.
  ///
  /// In en, this message translates to:
  /// **'Manual Input'**
  String get manualInput;

  /// No description provided for @saveCaffeine.
  ///
  /// In en, this message translates to:
  /// **'Save Caffeine Record'**
  String get saveCaffeine;

  /// No description provided for @caffeineSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Caffeine record saved.'**
  String get caffeineSaveSuccess;

  /// No description provided for @caffeineSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save caffeine record.'**
  String get caffeineSaveFailed;

  /// No description provided for @enterDrinkingTime.
  ///
  /// In en, this message translates to:
  /// **'Please enter drinking time.'**
  String get enterDrinkingTime;

  /// No description provided for @enterPositiveCaffeine.
  ///
  /// In en, this message translates to:
  /// **'Please enter a caffeine amount greater than 0.'**
  String get enterPositiveCaffeine;

  /// No description provided for @caffeineIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a product near NTU Hospital or estimate caffeine manually. Product details are shown in the selected app language when available.'**
  String get caffeineIntro;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcome;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your Email and password'**
  String get loginSubtitle;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @loginMissingCredentials.
  ///
  /// In en, this message translates to:
  /// **'Please enter Email and password.'**
  String get loginMissingCredentials;

  /// No description provided for @loginSuccessPrefix.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessPrefix;

  /// No description provided for @loginMissingUserId.
  ///
  /// In en, this message translates to:
  /// **'Login succeeded, but user ID was not returned.'**
  String get loginMissingUserId;

  /// No description provided for @loginInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Login failed: Email or password is incorrect.'**
  String get loginInvalidCredentials;

  /// No description provided for @loginFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailedPrefix;

  /// No description provided for @serverUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown server error.'**
  String get serverUnknownError;

  /// No description provided for @serverInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The server returned an invalid response.'**
  String get serverInvalidResponse;

  /// No description provided for @serverConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the server.'**
  String get serverConnectionError;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'No account yet?'**
  String get noAccountPrompt;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register here'**
  String get registerLink;

  /// No description provided for @registerPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerPageTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a New Account'**
  String get registerTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @registerMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get registerMissingFields;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid Email format.'**
  String get invalidEmailFormat;

  /// No description provided for @registerSuccessLogin.
  ///
  /// In en, this message translates to:
  /// **'Registration successful. Please sign in.'**
  String get registerSuccessLogin;

  /// No description provided for @registerEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registration failed: this Email is already registered.'**
  String get registerEmailAlreadyRegistered;

  /// No description provided for @registerFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registerFailedPrefix;

  /// No description provided for @bodySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Body Information'**
  String get bodySettingsTitle;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @maleLabel.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get maleLabel;

  /// No description provided for @femaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get femaleLabel;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @ageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your age'**
  String get ageHint;

  /// No description provided for @ageRequired.
  ///
  /// In en, this message translates to:
  /// **'Age is required.'**
  String get ageRequired;

  /// No description provided for @invalidAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid age.'**
  String get invalidAge;

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightLabel;

  /// No description provided for @heightHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your height'**
  String get heightHint;

  /// No description provided for @heightRequired.
  ///
  /// In en, this message translates to:
  /// **'Height is required.'**
  String get heightRequired;

  /// No description provided for @invalidHeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid height.'**
  String get invalidHeight;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightLabel;

  /// No description provided for @weightHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your weight'**
  String get weightHint;

  /// No description provided for @weightRequired.
  ///
  /// In en, this message translates to:
  /// **'Weight is required.'**
  String get weightRequired;

  /// No description provided for @invalidWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight.'**
  String get invalidWeight;

  /// No description provided for @bmiHint.
  ///
  /// In en, this message translates to:
  /// **'BMI will be calculated automatically.'**
  String get bmiHint;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get settingsSaved;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings'**
  String get settingsSaveFailed;

  /// No description provided for @settingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get settingsLoadFailed;

  /// No description provided for @settingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Data loading error'**
  String get settingsLoadError;

  /// No description provided for @completeRequiredFieldsAndGender.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields and select gender.'**
  String get completeRequiredFieldsAndGender;

  /// No description provided for @baselineQuestionnaireTitle.
  ///
  /// In en, this message translates to:
  /// **'Baseline Research Questionnaire'**
  String get baselineQuestionnaireTitle;

  /// No description provided for @baselineQuestionnaireBody.
  ///
  /// In en, this message translates to:
  /// **'This questionnaire only needs to be completed once at the beginning of the study. If you have already completed it or cannot fill it in now, you may skip it and enter WakeMate.'**
  String get baselineQuestionnaireBody;

  /// No description provided for @questionnaireReturnInstruction.
  ///
  /// In en, this message translates to:
  /// **'After completing the questionnaire, close the browser window and switch back to the WakeMate app.'**
  String get questionnaireReturnInstruction;

  /// No description provided for @baselineQuestionnaireNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Baseline questionnaire links are not configured yet. You may skip and enter the app for now, or update the links later.'**
  String get baselineQuestionnaireNotConfigured;

  /// No description provided for @skipEnterApp.
  ///
  /// In en, this message translates to:
  /// **'Skip and Enter App'**
  String get skipEnterApp;

  /// No description provided for @linkNotConfiguredSuffix.
  ///
  /// In en, this message translates to:
  /// **'link is not configured yet.'**
  String get linkNotConfiguredSuffix;

  /// No description provided for @unableToOpenPrefix.
  ///
  /// In en, this message translates to:
  /// **'Unable to open'**
  String get unableToOpenPrefix;

  /// No description provided for @chineseBaselineQuestionnaire.
  ///
  /// In en, this message translates to:
  /// **'Chinese Baseline Questionnaire'**
  String get chineseBaselineQuestionnaire;

  /// No description provided for @indonesianBaselineQuestionnaire.
  ///
  /// In en, this message translates to:
  /// **'Indonesian Baseline Questionnaire'**
  String get indonesianBaselineQuestionnaire;

  /// No description provided for @chineseDailyQuestionnaire.
  ///
  /// In en, this message translates to:
  /// **'Chinese Daily Questionnaire'**
  String get chineseDailyQuestionnaire;

  /// No description provided for @indonesianDailyQuestionnaire.
  ///
  /// In en, this message translates to:
  /// **'Indonesian Daily Questionnaire'**
  String get indonesianDailyQuestionnaire;

  /// No description provided for @notificationCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationCenterTitle;

  /// No description provided for @alertnessTapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap Start'**
  String get alertnessTapToStart;

  /// No description provided for @alertnessWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get alertnessWait;

  /// No description provided for @alertnessTapNow.
  ///
  /// In en, this message translates to:
  /// **'Tap now!'**
  String get alertnessTapNow;

  /// No description provided for @alertnessTooEarly.
  ///
  /// In en, this message translates to:
  /// **'Too early. Try again.'**
  String get alertnessTooEarly;

  /// No description provided for @alertnessTrialPrefix.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get alertnessTrialPrefix;

  /// No description provided for @alertnessTrialSuffix.
  ///
  /// In en, this message translates to:
  /// **''**
  String get alertnessTrialSuffix;

  /// No description provided for @millisecondsUnit.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get millisecondsUnit;

  /// No description provided for @alertnessResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Result'**
  String get alertnessResultTitle;

  /// No description provided for @alertnessEachReactionTime.
  ///
  /// In en, this message translates to:
  /// **'Reaction time for each trial:'**
  String get alertnessEachReactionTime;

  /// No description provided for @alertnessAverageReactionTime.
  ///
  /// In en, this message translates to:
  /// **'Average reaction time'**
  String get alertnessAverageReactionTime;

  /// No description provided for @alertnessChooseKss.
  ///
  /// In en, this message translates to:
  /// **'Select your current alertness level (KSS):'**
  String get alertnessChooseKss;

  /// No description provided for @alertnessChooseKssHint.
  ///
  /// In en, this message translates to:
  /// **'Select KSS score'**
  String get alertnessChooseKssHint;

  /// No description provided for @alertnessRetest.
  ///
  /// In en, this message translates to:
  /// **'Test Again'**
  String get alertnessRetest;

  /// No description provided for @alertnessDoneClose.
  ///
  /// In en, this message translates to:
  /// **'Done and Close'**
  String get alertnessDoneClose;

  /// No description provided for @alertnessDataSent.
  ///
  /// In en, this message translates to:
  /// **'Data submitted successfully.'**
  String get alertnessDataSent;

  /// No description provided for @alertnessSubmitFailedStatus.
  ///
  /// In en, this message translates to:
  /// **'Submit failed. Status code:'**
  String get alertnessSubmitFailedStatus;

  /// No description provided for @alertnessNetworkSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Network error. Unable to submit data.'**
  String get alertnessNetworkSubmitFailed;

  /// No description provided for @tapHere.
  ///
  /// In en, this message translates to:
  /// **'Tap Here'**
  String get tapHere;

  /// No description provided for @startTest.
  ///
  /// In en, this message translates to:
  /// **'Start Test'**
  String get startTest;

  /// No description provided for @kss1.
  ///
  /// In en, this message translates to:
  /// **'Extremely alert'**
  String get kss1;

  /// No description provided for @kss2.
  ///
  /// In en, this message translates to:
  /// **'Very alert'**
  String get kss2;

  /// No description provided for @kss3.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get kss3;

  /// No description provided for @kss4.
  ///
  /// In en, this message translates to:
  /// **'Rather alert'**
  String get kss4;

  /// No description provided for @kss5.
  ///
  /// In en, this message translates to:
  /// **'Neither alert nor sleepy'**
  String get kss5;

  /// No description provided for @kss6.
  ///
  /// In en, this message translates to:
  /// **'Some signs of sleepiness'**
  String get kss6;

  /// No description provided for @kss7.
  ///
  /// In en, this message translates to:
  /// **'Sleepy, but no effort to stay awake'**
  String get kss7;

  /// No description provided for @kss8.
  ///
  /// In en, this message translates to:
  /// **'Sleepy, some effort to stay awake'**
  String get kss8;

  /// No description provided for @kss9.
  ///
  /// In en, this message translates to:
  /// **'Very sleepy, great effort to stay awake'**
  String get kss9;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'WakeMate reminders'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'WakeMate caffeine recommendation and reminder notifications'**
  String get notificationChannelDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
