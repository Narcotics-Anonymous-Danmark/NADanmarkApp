import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('da'),
    Locale('en'),
  ];

  /// Legacy key MENU
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// Legacy key HOME
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Legacy key LOCATIONSEARCH
  ///
  /// In en, this message translates to:
  /// **'Meetings nearby'**
  String get locationsearch;

  /// Legacy key LOADINGMAP
  ///
  /// In en, this message translates to:
  /// **'Loading map...'**
  String get loadingmap;

  /// Legacy key LOCATION
  ///
  /// In en, this message translates to:
  /// **''**
  String get location;

  /// Legacy key NO_LOCATION
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get noLocation;

  /// Legacy key LOCATING
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get locating;

  /// Legacy key FINDING_MTGS
  ///
  /// In en, this message translates to:
  /// **'Finding Meetings ...'**
  String get findingMtgs;

  /// Legacy key LISTFULL
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get listfull;

  /// Legacy key TAGS
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// Legacy key CATEGORY
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Legacy key MENUS
  ///
  /// In en, this message translates to:
  /// **'Menus'**
  String get menus;

  /// Legacy key MAP_SEARCH
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapSearch;

  /// Legacy key MAP_SEARCH_DESC
  ///
  /// In en, this message translates to:
  /// **' meetings nearest the red marker. Drag the red marker to move the search.'**
  String get mapSearchDesc;

  /// Legacy key MEETINGS
  ///
  /// In en, this message translates to:
  /// **' meetings'**
  String get meetings;

  /// Legacy key KM
  ///
  /// In en, this message translates to:
  /// **' km'**
  String get km;

  /// Legacy key MAP
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get map;

  /// Legacy key SETTINGS
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Legacy key SEARCHRANGESETTING
  ///
  /// In en, this message translates to:
  /// **'Default search range'**
  String get searchrangesetting;

  /// Legacy key FIRSTDAYOFWEEKSETTING
  ///
  /// In en, this message translates to:
  /// **'First day of week'**
  String get firstdayofweeksetting;

  /// Legacy key SHOWOWNREGIONONTOPSETTING
  ///
  /// In en, this message translates to:
  /// **'Show Denmark at the top of the full meeting list'**
  String get showownregionontopsetting;

  /// Legacy key HOME_TITLE
  ///
  /// In en, this message translates to:
  /// **'Narcotics Anonymous Denmark'**
  String get homeTitle;

  /// Legacy key HOME_MESSAGE
  ///
  /// In en, this message translates to:
  /// **'Helpline: 70 20 01 85'**
  String get homeMessage;

  /// Legacy key CONTACT
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get contact;

  /// Legacy key LANGUAGE
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Legacy key ENGLISH
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Legacy key ITALIAN
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get italian;

  /// Legacy key SPANISH
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// Legacy key DANISH
  ///
  /// In en, this message translates to:
  /// **'Dansk'**
  String get danish;

  /// Legacy key POLISH
  ///
  /// In en, this message translates to:
  /// **'Polskie'**
  String get polish;

  /// Legacy key PORTUGUESE
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get portuguese;

  /// Legacy key RUSSIAN
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// Legacy key ADDRESSSEARCH
  ///
  /// In en, this message translates to:
  /// **'Address Search'**
  String get addresssearch;

  /// Legacy key DOIHAVETHEBMLT
  ///
  /// In en, this message translates to:
  /// **'Do I have the BMLT?'**
  String get doihavethebmlt;

  /// Legacy key MAPRANGE
  ///
  /// In en, this message translates to:
  /// **'Default Search Range'**
  String get maprange;

  /// Legacy key TIMEDISPLAY
  ///
  /// In en, this message translates to:
  /// **'Time format'**
  String get timedisplay;

  /// Legacy key 24HR
  ///
  /// In en, this message translates to:
  /// **'24 hr clock'**
  String get twentyFourHour;

  /// Legacy key 12HR
  ///
  /// In en, this message translates to:
  /// **'12 hr clock'**
  String get twelveHour;

  /// Legacy key SUNDAY
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// Legacy key MONDAY
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// Legacy key TUESDAY
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// Legacy key WEDNESDAY
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// Legacy key THURSDAY
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// Legacy key FRIDAY
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// Legacy key SATURDAY
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// Legacy key DISTANCE
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Legacy key FORMATS
  ///
  /// In en, this message translates to:
  /// **'Formats'**
  String get formats;

  /// Legacy key DIRECTIONS
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// Legacy key MILES
  ///
  /// In en, this message translates to:
  /// **'miles'**
  String get miles;

  /// Legacy key KMS
  ///
  /// In en, this message translates to:
  /// **'kms'**
  String get kms;

  /// Legacy key MEETINGS_NEAREST
  ///
  /// In en, this message translates to:
  /// **'meetings nearest'**
  String get meetingsNearest;

  /// Legacy key MARKER_INSTR
  ///
  /// In en, this message translates to:
  /// **'Drag marker to set position'**
  String get markerInstr;

  /// Legacy key NOTHING_FOUND
  ///
  /// In en, this message translates to:
  /// **'Nothing Found'**
  String get nothingFound;

  /// Legacy key BUS
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get bus;

  /// Legacy key TRAIN
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get train;

  /// Legacy key SRC_CODE
  ///
  /// In en, this message translates to:
  /// **'App Source Code'**
  String get srcCode;

  /// Legacy key BUG_REPORT
  ///
  /// In en, this message translates to:
  /// **'Open a bug report/enhancement request'**
  String get bugReport;

  /// Legacy key FIND_OUT_MORE
  ///
  /// In en, this message translates to:
  /// **'How do I find out more about the BMLT?'**
  String get findOutMore;

  /// Legacy key JOIN_FB_GROUP
  ///
  /// In en, this message translates to:
  /// **'Join the Facebook Group'**
  String get joinFbGroup;

  /// Legacy key VISIT_WEBSITE
  ///
  /// In en, this message translates to:
  /// **'Visit the website'**
  String get visitWebsite;

  /// Legacy key IS_BMLT
  ///
  /// In en, this message translates to:
  /// **'Is my location covered by the BMLT?'**
  String get isBmlt;

  /// Legacy key YES
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Legacy key NO
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Legacy key AWAY
  ///
  /// In en, this message translates to:
  /// **'away'**
  String get away;

  /// Legacy key IS_BMLT_YES_1
  ///
  /// In en, this message translates to:
  /// **'On the BMLT worldwide DB, the nearest meeting to your current location is'**
  String get isBmltYes1;

  /// Legacy key IS_BMLT_YES_2
  ///
  /// In en, this message translates to:
  /// **'So it looks like your local service body'**
  String get isBmltYes2;

  /// Legacy key IS_BMLT_YES_3
  ///
  /// In en, this message translates to:
  /// **'has implemented the BMLT for their meetings list.'**
  String get isBmltYes3;

  /// Legacy key IS_BMLT_NO_1
  ///
  /// In en, this message translates to:
  /// **'On the BMLT worldwide DB, it looks like the nearest meeting to your current location is'**
  String get isBmltNo1;

  /// Legacy key IS_BMLT_NO_2
  ///
  /// In en, this message translates to:
  /// **'So, it looks like your local service body has not implemented the BMLT for their meetings list.'**
  String get isBmltNo2;

  /// Legacy key CLOSE
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Legacy key MEETING_DETAILS
  ///
  /// In en, this message translates to:
  /// **'Meeting Details'**
  String get meetingDetails;

  /// Legacy key MEETING_FORMATS
  ///
  /// In en, this message translates to:
  /// **'Meeting Formats'**
  String get meetingFormats;

  /// Legacy key CANCEL
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Legacy key VIRTUAL_LINK
  ///
  /// In en, this message translates to:
  /// **'Virtual Link'**
  String get virtualLink;

  /// Legacy key PHONE_MEETING
  ///
  /// In en, this message translates to:
  /// **'Phone Meeting Dial-in'**
  String get phoneMeeting;

  /// Legacy key TEMP_CLOSED
  ///
  /// In en, this message translates to:
  /// **'Temporarily Closed'**
  String get tempClosed;

  /// Legacy key VIRTUAL_MEETINGS
  ///
  /// In en, this message translates to:
  /// **'virtual-na.org'**
  String get virtualMeetings;

  /// Legacy key LIST
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// Legacy key SEARCH
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Legacy key VISIT
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get visit;

  /// Legacy key WEEKDAYS
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get weekdays;

  /// Legacy key VIRTUAL_NA
  ///
  /// In en, this message translates to:
  /// **'Virtual NA is an international service resource whose main purpose is to run a search engine for NA meetings. It covers both online and phone meetings from different countries around the world.'**
  String get virtualNa;

  /// Legacy key HOME_MESSAGE_2
  ///
  /// In en, this message translates to:
  /// **'If you have a problem with substances,'**
  String get homeMessage2;

  /// Legacy key HOME_MESSAGE_3
  ///
  /// In en, this message translates to:
  /// **'we can perhaps help.'**
  String get homeMessage3;

  /// Legacy key NEWS
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news;

  /// Legacy key EVENTS
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// Legacy key BASIC_TEXT
  ///
  /// In en, this message translates to:
  /// **'Basic Text'**
  String get basicText;

  /// Legacy key HOW_AND_WHY
  ///
  /// In en, this message translates to:
  /// **'It Works: How and Why'**
  String get howAndWhy;

  /// Legacy key STEP_WORKING_GUIDES
  ///
  /// In en, this message translates to:
  /// **'The NA Step Working Guides'**
  String get stepWorkingGuides;

  /// Legacy key SPEAKS
  ///
  /// In en, this message translates to:
  /// **'Speaks'**
  String get speaks;

  /// Legacy key JFT
  ///
  /// In en, this message translates to:
  /// **'Just for today'**
  String get jft;

  /// Legacy key AUDIOBOOKS
  ///
  /// In en, this message translates to:
  /// **'Audiobooks'**
  String get audiobooks;

  /// Legacy key NACC
  ///
  /// In en, this message translates to:
  /// **'Cleantime calculator'**
  String get nacc;

  /// Legacy key GRC
  ///
  /// In en, this message translates to:
  /// **'Group readings'**
  String get grc;

  /// Legacy key COMING_SOON
  ///
  /// In en, this message translates to:
  /// **'Coming soon.'**
  String get comingSoon;

  /// Legacy key COMING_SOON_BODY
  ///
  /// In en, this message translates to:
  /// **'We are working on it ..'**
  String get comingSoonBody;

  /// Legacy key LANGUAGE(S)
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// Legacy key CONVENTION
  ///
  /// In en, this message translates to:
  /// **'Convention'**
  String get convention;

  /// Legacy key OPENING_SPEAKER
  ///
  /// In en, this message translates to:
  /// **'Opening speak'**
  String get openingSpeaker;

  /// Legacy key MAIN_SPEAKER
  ///
  /// In en, this message translates to:
  /// **'Main speak'**
  String get mainSpeaker;

  /// Legacy key CLOSING_SPEAKER
  ///
  /// In en, this message translates to:
  /// **'Closing speak'**
  String get closingSpeaker;

  /// Legacy key STEPS
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// Legacy key TRADITIONS
  ///
  /// In en, this message translates to:
  /// **'Traditions'**
  String get traditions;

  /// Legacy key NA_HISTORY
  ///
  /// In en, this message translates to:
  /// **'NA\'s history'**
  String get naHistory;

  /// Legacy key mapsearch.search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get mapsearchSearch;

  /// Legacy key CLEANTIME
  ///
  /// In en, this message translates to:
  /// **'Cleantime'**
  String get cleantime;

  /// Legacy key DATETIME
  ///
  /// In en, this message translates to:
  /// **'Cleantime counter'**
  String get datetime;

  /// Legacy key ENTERCLEANDATE
  ///
  /// In en, this message translates to:
  /// **'First clean day'**
  String get entercleandate;

  /// Legacy key CLEANTIMEINDAYS
  ///
  /// In en, this message translates to:
  /// **'Clean days'**
  String get cleantimeindays;

  /// Legacy key DAY
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// Legacy key DAYS
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// Legacy key CLEANTIMEINWEEKS
  ///
  /// In en, this message translates to:
  /// **'Clean weeks'**
  String get cleantimeinweeks;

  /// Legacy key WEEK
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get week;

  /// Legacy key WEEKS
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get weeks;

  /// Legacy key CLEANTIMEINYEARS
  ///
  /// In en, this message translates to:
  /// **'Clean years'**
  String get cleantimeinyears;

  /// Legacy key YEAR
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get year;

  /// Legacy key YEARS
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// Legacy key CLEANTIMEINMONTHS
  ///
  /// In en, this message translates to:
  /// **'Clean months'**
  String get cleantimeinmonths;

  /// Legacy key MONTH
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// Legacy key MONTHS
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// Legacy key BIRTHDAY
  ///
  /// In en, this message translates to:
  /// **'Cleanday'**
  String get birthday;

  /// Legacy key DAYCLEAN
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get dayclean;

  /// Legacy key DAYSCLEAN
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysclean;

  /// Legacy key MONTHCLEAN
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get monthclean;

  /// Legacy key MONTHSCLEAN
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get monthsclean;

  /// Legacy key YEARCLEAN
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get yearclean;

  /// Legacy key YEARSCLEAN
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get yearsclean;

  /// Legacy key CLEANTIMEUNITSORT
  ///
  /// In en, this message translates to:
  /// **'Cleantime sorting'**
  String get cleantimeunitsort;

  /// Legacy key DMY
  ///
  /// In en, this message translates to:
  /// **'days - months - years'**
  String get dmy;

  /// Legacy key YMD
  ///
  /// In en, this message translates to:
  /// **'years - months - days'**
  String get ymd;

  /// Legacy key OR
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// Legacy key BACK
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Legacy key NEWPROFILE
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get newprofile;

  /// Legacy key NEWPROFILENAMEHERE
  ///
  /// In en, this message translates to:
  /// **'New profile name here'**
  String get newprofilenamehere;

  /// Legacy key CANCELBUTTON
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelbutton;

  /// Legacy key ADDBUTTON
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get addbutton;

  /// Legacy key RENAMEPROFILE
  ///
  /// In en, this message translates to:
  /// **'Rename profile'**
  String get renameprofile;

  /// Legacy key RENAME
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Legacy key AREYOUSURE
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areyousure;

  /// Legacy key DELETE
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Legacy key PLAYER_CONTINUE
  ///
  /// In en, this message translates to:
  /// **'Continue playing'**
  String get playerContinue;

  /// Legacy key PLAYER_PLAY
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// Legacy key PLAYER_PAUSE
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// Legacy key PLAYER_CLOSE
  ///
  /// In en, this message translates to:
  /// **'Close player'**
  String get playerClose;

  /// Legacy key PLAYER_PREVIOUS
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get playerPrevious;

  /// Legacy key PLAYER_NEXT
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get playerNext;

  /// Legacy key PLAYER_REWIND
  ///
  /// In en, this message translates to:
  /// **'Rewind 15 seconds'**
  String get playerRewind;

  /// Legacy key PLAYER_FORWARD
  ///
  /// In en, this message translates to:
  /// **'Forward 30 seconds'**
  String get playerForward;

  /// Legacy key SPEAK_SEARCH_PLACEHOLDER
  ///
  /// In en, this message translates to:
  /// **'Search name, convention, city, year …'**
  String get speakSearchPlaceholder;

  /// Legacy key SPEAK_FILTERS
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get speakFilters;

  /// Legacy key SPEAK_ALL
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get speakAll;

  /// Legacy key SPEAK_SORT
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get speakSort;

  /// Legacy key SPEAK_SORT_NEWEST
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get speakSortNewest;

  /// Legacy key SPEAK_SORT_OLDEST
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get speakSortOldest;

  /// Legacy key SPEAK_SORT_NAME
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get speakSortName;

  /// Legacy key SPEAK_YEAR
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get speakYear;

  /// Legacy key SPEAK_ONLY_STARTED
  ///
  /// In en, this message translates to:
  /// **'Only started'**
  String get speakOnlyStarted;

  /// Legacy key CHAPTERS
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// Legacy key PLAYER_CONTINUE_LISTENING
  ///
  /// In en, this message translates to:
  /// **'Continue listening'**
  String get playerContinueListening;

  /// Legacy key PLAYER_CONTINUE_FROM
  ///
  /// In en, this message translates to:
  /// **'Continue from {time}'**
  String playerContinueFrom(String time);

  /// Legacy key PLAYER_TIME_LEFT
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String playerTimeLeft(String time);

  /// Legacy key PLAYER_NOW_PLAYING
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get playerNowPlaying;

  /// Legacy key BOOK_CHAPTER_OF
  ///
  /// In en, this message translates to:
  /// **'Chapter {index} of {count}'**
  String bookChapterOf(String index, String count);

  /// Legacy key SPEAK_COUNT
  ///
  /// In en, this message translates to:
  /// **'{count} speaks'**
  String speakCount(String count);

  /// Legacy key SPEAK_NONE_FOUND
  ///
  /// In en, this message translates to:
  /// **'No speaks found'**
  String get speakNoneFound;

  /// Legacy key SPEAK_NONE_FOUND_BODY
  ///
  /// In en, this message translates to:
  /// **'Try another search word, or reset the filters.'**
  String get speakNoneFoundBody;

  /// Legacy key SPEAK_RESET_FILTERS
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get speakResetFilters;

  /// Legacy key SPEAK_LOAD_ERROR
  ///
  /// In en, this message translates to:
  /// **'Could not load the speaks'**
  String get speakLoadError;

  /// Legacy key SPEAK_LOAD_ERROR_BODY
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get speakLoadErrorBody;

  /// Legacy key SPEAK_RETRY
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get speakRetry;

  /// Legacy key SPEAK_FORGET
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get speakForget;

  /// Legacy key PLAYER_CAST
  ///
  /// In en, this message translates to:
  /// **'Play on Chromecast'**
  String get playerCast;

  /// Legacy key PLAYER_CAST_CONNECTED
  ///
  /// In en, this message translates to:
  /// **'Casting — tap for options'**
  String get playerCastConnected;

  /// Legacy key PLAYER_PLAYING_ON
  ///
  /// In en, this message translates to:
  /// **'Playing on {device}'**
  String playerPlayingOn(String device);

  /// Legacy key PLAYER_CONNECTING_TO_CAST
  ///
  /// In en, this message translates to:
  /// **'Connecting to Chromecast…'**
  String get playerConnectingToCast;

  /// Legacy key PLAYER_AIRPLAY
  ///
  /// In en, this message translates to:
  /// **'AirPlay'**
  String get playerAirplay;

  /// Settings: Danish option
  ///
  /// In en, this message translates to:
  /// **'Danish'**
  String get languageDanish;

  /// Settings: English option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Last row of the side menu
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String menuVersion(String version);

  /// Header menu button label
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get actionOpenMenu;

  /// Scrim label while the menu is open
  ///
  /// In en, this message translates to:
  /// **'Close menu'**
  String get actionCloseMenu;

  /// Slider caption
  ///
  /// In en, this message translates to:
  /// **'Default search range = {km} km'**
  String settingsSearchRangeValue(int km);

  /// Slider end labels
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String kmValue(int km);

  /// About page trial warning title
  ///
  /// In en, this message translates to:
  /// **'This app is not [yet] approved!'**
  String get contactNotApprovedTitle;

  /// About page trial warning body
  ///
  /// In en, this message translates to:
  /// **'This is a trial version. Until it has been approved by RSK, it should not be used seriously.'**
  String get contactNotApprovedBody;

  /// About page card title
  ///
  /// In en, this message translates to:
  /// **'Changes to the meeting list'**
  String get contactMeetingListChangesTitle;

  /// About page button
  ///
  /// In en, this message translates to:
  /// **'Write to the meeting list servant'**
  String get contactMeetingListServant;

  /// About page card title
  ///
  /// In en, this message translates to:
  /// **'Narcotics Anonymous online'**
  String get contactNaOnlineTitle;

  /// About page card title
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get contactAboutTitle;

  /// About page button
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get contactSourceCode;

  /// About page button
  ///
  /// In en, this message translates to:
  /// **'Bug reports'**
  String get contactBugReports;

  /// About page build line
  ///
  /// In en, this message translates to:
  /// **'Build type: {buildType}'**
  String contactBuildType(String buildType);

  /// About page version line
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String contactVersion(String version);

  /// About page card title
  ///
  /// In en, this message translates to:
  /// **'The fine print'**
  String get contactFinePrintTitle;

  /// About page fine print
  ///
  /// In en, this message translates to:
  /// **'The NA logo is a registered trademark and used in accordance with the Fellowship Intellectual Property Trust (FIPT).'**
  String get contactFinePrintBody;

  /// About page line after a legacy import
  ///
  /// In en, this message translates to:
  /// **'Imported settings from the previous version'**
  String get contactImportedSettings;

  /// JFT footer
  ///
  /// In en, this message translates to:
  /// **'Copyright (c) 2007-{year}, NA World Services, Inc. All Rights Reserved'**
  String jftCopyright(int year);

  /// JFT error state
  ///
  /// In en, this message translates to:
  /// **'Today\'s text could not be loaded'**
  String get jftUnavailable;
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
      <String>['da', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
