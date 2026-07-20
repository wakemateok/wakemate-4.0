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
  /// **'Choose a product near NTU Hospital or estimate caffeine manually. Product names are kept as shown on the source label.'**
  String get caffeineIntro;
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
