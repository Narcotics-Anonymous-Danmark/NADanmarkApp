# Legacy parity

Mapping from the Ionic/Cordova app (`../App`) to this rewrite: pages to
capabilities and porting slices, storage keys to typed settings, translation
keys to ARB keys, Cordova plugins to Flutter packages. Update this file in the
same PR as the change it describes.

## Porting slices

| Slice | Content | Done when |
|---|---|---|
| 0 | app-shell, settings, contact, jft, legacy-migration (4 settings keys) | Menu, routing, back button, loading bar, player host, 4 settings, About page, JFT page and home card. Implemented in `openspec/changes/slice-0-shell-settings-contact-jft` |
| 1 | meetings-search core: BMLT adapter, formats, meeting list/card, `/listfull` | Full list by municipality with all card rules |
| 2 | meetings-search nearby: geolocation, radius search, `/location-search` | Nearby search with timeouts and slider |
| 3 | cleantime | Profiles, breakdowns, key tags, notifications, home cards |
| 4 | media-player, audiobooks, readings | Global player, 3 books, resume points, GRC page |
| 5 | speaks | Catalog normalisation, search, filters, continue listening |
| 6 | events, home | Calendar feed, events page, home assembled from slices 0/3/6 |
| 7 | meetings-map | Map, auto radius, clusters, places search, details modal |
| 8 | parity release | legacy-migration, localisation parity, first store release 2.0.0 |
| 9 | cast/airplay, dark theme | Chromecast handoff, AirPlay picker, dark tokens |

## Pages

| Legacy route | Legacy page | Capability | Slice |
|---|---|---|---|
| `/home` | `HomePage` | app-shell (+ cleantime, jft, events cards) | 0, 3, 6 |
| `/map-search` | `MapSearchPage` | meetings-map | 7 |
| `/location-search` | `LocationSearchPage` | meetings-search | 2 |
| `/listfull` | `ListfullPage` | meetings-search | 1 |
| `/modal` (ModalController) | `ModalPage` | meetings-search (details modal) | 1, 7 |
| `/jft` | `JftPage` | jft | 0 |
| `/cleantime-counter` | `CleantimeCounterPage` | cleantime | 3 |
| `/events` | `EventsPage` | events | 6 |
| `/audiobooks` | `AudioBooksPage` | audiobooks | 4 |
| `/basic-text`, `/how-and-why`, `/step-working-guides` | three copies of the book page | audiobooks (one parameterised page) | 4 |
| `/speaks` | `SpeaksPage` | speaks | 5 |
| `/grc` | `GrcPage` | readings | 4 |
| `/settings` | `SettingsPage` | settings | 0 |
| `/contact` | `ContactPage` | contact | 0 |
| `app.component` menu, back button | `AppComponent` | app-shell | 0 |
| `app-global-loading` | `GlobalLoadingComponent` | app-shell | 0 |
| `app-media-player` | `MediaPlayerComponent` | media-player | 4, 9 |
| `app-meeting-list`, `app-meeting-card`, `app-meeting-formats` | components | meetings-search (`feature_meetings` library) | 1 |
| — (`ServiceGroupsProvider`, virtual-NA endpoints, `meetingType='virt'`) | dead code | not ported | — |

## Storage keys

Legacy store: Ionic Storage IndexedDB `_ionicstorage` / `_ionickv` at
`https://localhost` (Android) and `ionic://localhost` (iOS). Details and
scenarios: `openspec/specs/legacy-migration/spec.md`.

| Legacy key | Legacy shape | New typed setting | Migration rule |
|---|---|---|---|
| `language` | `"da"` / `"en"` | `Language language` | copy if valid, else `da` |
| `firstday` | `"mo"` / `"su"` | `FirstDayOfWeek firstDayOfWeek` | copy if valid, else `mo` |
| `searchRange` | number | `Km searchRadiusKm` | copy if integer 5–50, else 15 |
| `cleanTimeUnitSort` | `"ymd"` / `"dmy"` | `UnitOrder cleanTimeUnitOrder` | copy if valid, else `ymd` |
| `theme` | string | — | dropped |
| `cleanDateProfiles` | `[{name, cleandate: ISO with offset}]` | `List<CleantimeProfile>` (`LocalDate`) | keep valid entries; calendar date in the stored offset |
| `activeProfile` | `"0"`, `"1"`, … | `ProfileIndex activeCleantimeProfile` | parse, clamp to range, else 0 |
| `meeting_formats_v1` | `{fetchedAt, formats}` | `MeetingFormatsCache` | copy when non-empty |
| `mediaResume.book.<id>` | `{trackId, trackIndex, position, duration?, updatedAt}` | `ResumePoint` under the same key | copy when numeric |
| `mediaResume.speak.<url>` | same | same key | same |
| `mediaResume.index.book` / `.speak` | `{id: point}` | same key | rebuilt from imported points |
| — | — | `legacyMigration.completed` | written once after import |

## Translation keys

177 keys in the legacy `da.json` (168 in `en.json`; the nine Danish-only keys
are marked). Proposed ARB keys are lowerCamelCase; singular/plural pairs
collapse into one ICU plural key. Values shown are the legacy strings.

| Legacy key | da | en | ARB key | Disposition |
|---|---|---|---|---|
| `MENU` | Menu | Menu | `menuTitle` | ported |
| `HOME` | Hjem | Home | `pageHome` | ported |
| `LOCATIONSEARCH` | Møder i nærheden | Meetings nearby | `pageMeetingsNearby` | ported |
| `LOADINGMAP` | Indlæser kort ... | Loading map... | — | dropped (unused BMLT template key) |
| `LOCATION` | *(empty)* | *(empty)* | — | dropped (unused BMLT template key) |
| `NO_LOCATION` | Placeringen er ikke indstillet | Location not set | `locationNotSet` | ported |
| `LOCATING` | Finder position ... | Locating... | `loadingLocating` | ported |
| `FINDING_MTGS` | Finder møder ... | Finding Meetings ... | `loadingFindingMeetings` | ported |
| `LISTFULL` | Mødeliste | Meetings | `pageMeetings` | ported |
| `TAGS` | Tags | Tags | — | dropped (unused BMLT template key) |
| `CATEGORY` | Kategori | Category | — | dropped (unused BMLT template key) |
| `MENUS` | Menuer | Menus | — | dropped (unused BMLT template key) |
| `MAP_SEARCH` | Kort | Map | `pageMap` | ported |
| `MAP_SEARCH_DESC` |  møder nærmest den røde markør. Træk den røde markør for at flytte søgningen. |  meetings nearest the red marker. Drag the red marker to move the search. | — | dropped (unused BMLT template key) |
| `MEETINGS` |  Møder |  meetings | — | dropped (unused BMLT template key) |
| `KM` |  km |  km | `unitKm` | ported |
| `MAP` | Kørselsvejledning | Directions | `meetingDirections` | ported |
| `SETTINGS` | Indstillinger | Settings | `pageSettings` | ported |
| `SEARCHRANGESETTING` | Standard søgeradius | Default search range | `settingsDefaultSearchRange` | ported |
| `FIRSTDAYOFWEEKSETTING` | Ugen starter med | First day of week | `settingsFirstDayOfWeek` | ported |
| `SHOWOWNREGIONONTOPSETTING` | Vis Danmark øverst på fuld mødeliste | *(missing)* | — | dropped (da only, unused) |
| `HOME_TITLE` | Narcotics Anonymous Danmark | Narcotics Anonymous Denmark | `homeTitle` | ported |
| `HOME_MESSAGE` | Helpline: 70 20 01 85 | Helpline: 70 20 01 85 | `homeHelpline` | ported |
| `CONTACT` | Om denne app / Kontakt | About | `pageAbout` | ported |
| `LANGUAGE` | Sprog | Language | `settingsLanguage` | ported |
| `ENGLISH` | Engelsk | English | `languageEnglish` | ported |
| `ITALIAN` | Italiensk | Italiano | — | dropped (unused BMLT template key) |
| `SPANISH` | Spansk | Español | — | dropped (unused BMLT template key) |
| `DANISH` | Dansk | Dansk | `languageDanish` | ported |
| `POLISH` | Polsk | Polskie | — | dropped (unused BMLT template key) |
| `PORTUGUESE` | Portugisisk | Português | — | dropped (unused BMLT template key) |
| `RUSSIAN` | Russisk | Русский | — | dropped (unused BMLT template key) |
| `ADDRESSSEARCH` | Adressesøgning | Address Search | — | dropped (unused BMLT template key) |
| `DOIHAVETHEBMLT` | Har jeg BMLT? | Do I have the BMLT? | — | dropped (unused BMLT template key) |
| `MAPRANGE` | Standard søgeradius | Default Search Range | — | dropped (unused BMLT template key) |
| `TIMEDISPLAY` | Tidsformat | Time format | — | dropped (unused BMLT template key) |
| `24HR` | 24 Timer | 24 hr clock | — | dropped (unused BMLT template key) |
| `12HR` | AM/PM | 12 hr clock | — | dropped (unused BMLT template key) |
| `SUNDAY` | Søndag | Sunday | `sunday` | ported |
| `MONDAY` | Mandag | Monday | `monday` | ported |
| `TUESDAY` | Tirsdag | Tuesday | `tuesday` | ported |
| `WEDNESDAY` | Onsdag | Wednesday | `wednesday` | ported |
| `THURSDAY` | Torsdag | Thursday | `thursday` | ported |
| `FRIDAY` | Fredag | Friday | `friday` | ported |
| `SATURDAY` | Lørdag | Saturday | `saturday` | ported |
| `DISTANCE` | Afstand | Distance | — | dropped (unused BMLT template key) |
| `FORMATS` | Struktur | Formats | — | dropped (unused BMLT template key) |
| `DIRECTIONS` | Kørselsvejledning | Directions | — | dropped (unused BMLT template key) |
| `MILES` | miles | miles | — | dropped (unused BMLT template key) |
| `KMS` | km | kms | — | dropped (unused BMLT template key) |
| `MEETINGS_NEAREST` | møder nærmest | meetings nearest | — | dropped (unused BMLT template key) |
| `MARKER_INSTR` | Træk markør for at indstille position | Drag marker to set position | — | dropped (unused BMLT template key) |
| `NOTHING_FOUND` | Intet fundet | Nothing Found | — | dropped (unused BMLT template key) |
| `BUS` | Note | Bus | `meetingBusLines` | ported |
| `TRAIN` | Mødeformat | Train | `meetingTrainLines` | ported |
| `SRC_CODE` | Kildekode til app'en | App Source Code | `contactSourceCode` | reused for the localised About page (value replaced) |
| `BUG_REPORT` | Opret en fejlrapport / unit test | Open a bug report/enhancement request | `contactBugReports` | reused for the localised About page (value replaced) |
| `FIND_OUT_MORE` | Hvordan finder jeg ud af mere om BMLT? | How do I find out more about the BMLT? | — | dropped (unused BMLT template key) |
| `JOIN_FB_GROUP` | Deltag i Facebook-gruppen | Join the Facebook Group | `contactNaOnline` | reused for the localised About page (value replaced) |
| `VISIT_WEBSITE` | Besøg hjemmesiden | Visit the website | `contactMeetingListChanges` | reused for the localised About page (value replaced) |
| `IS_BMLT` | Er min placering dækket af BMLT? | Is my location covered by the BMLT? | — | dropped (unused BMLT template key) |
| `YES` | Ja | Yes | — | dropped (unused BMLT template key) |
| `NO` | Nej | No | — | dropped (unused BMLT template key) |
| `AWAY` | væk. | away | — | dropped (unused BMLT template key) |
| `IS_BMLT_YES_1` | I BMLT's internationale mødedatabase er det møde, der er tættest på din nuværende placering,  | On the BMLT worldwide DB, the nearest meeting to your current location is | — | dropped (unused BMLT template key) |
| `IS_BMLT_YES_2` | Så det ser ud som din lokale service enhed | So it looks like your local service body | — | dropped (unused BMLT template key) |
| `IS_BMLT_YES_3` | har sat BMLT op for jeres mødeliste. | has implemented the BMLT for their meetings list. | — | dropped (unused BMLT template key) |
| `IS_BMLT_NO_1` | I BMLT's verdensomspændende database ser det ud til, at det møde, der er nærmest din nuværende placering, er  | On the BMLT worldwide DB, it looks like the nearest meeting to your current location is | — | dropped (unused BMLT template key) |
| `IS_BMLT_NO_2` | Så det ser ud til, at din lokale service område ikke har implementeret BMLT for jeres mødeliste. | So, it looks like your local service body has not implemented the BMLT for their meetings list. | — | dropped (unused BMLT template key) |
| `CLOSE` | Luk | Close | `actionClose` | ported |
| `MEETING_DETAILS` | Mødedetaljer | Meeting Details | `meetingDetailsTitle` | ported |
| `MEETING_FORMATS` | Mødeformater | Meeting Formats | `meetingFormatsTitle` | ported |
| `CANCEL` | Annuller | Cancel | `actionCancel` | ported |
| `VIRTUAL_LINK` | Link til netmøde | Virtual Link | `meetingVirtualLink` | ported |
| `PHONE_MEETING` | Telefonmøde – opkaldsnummer | Phone Meeting Dial-in | `meetingPhoneDialIn` | ported |
| `TEMP_CLOSED` | Midlertidigt lukket | Temporarily Closed | `meetingTemporarilyClosed` | ported |
| `VIRTUAL_MEETINGS` | Netmøder: virtual-na.org | virtual-na.org | — | dropped (unused BMLT template key) |
| `LIST` | Vis liste | List | — | dropped (unused BMLT template key) |
| `SEARCH` | Søg | Search | — | dropped (unused BMLT template key) |
| `VISIT` | Besøg | Visit | — | dropped (unused BMLT template key) |
| `WEEKDAYS` | Alle dage | Weekdays | `allDays` | ported |
| `VIRTUAL_NA` | Virtual NA er en international serviceressource, hvis hovedformål det er at drive en søgemaskine til NA-møder. Den dækker både online- og telefonmøder fra forskellige lande rundt om i verden. | *(missing)* | — | dropped (da only; virtual-NA feature not ported) |
| `HOME_MESSAGE_2` | Hvis du har et problem med stoffer, | If you have a problem with substances, | — | dropped (unused) |
| `HOME_MESSAGE_3` | så kan vi måske hjælpe. | we can perhaps help. | — | dropped (unused) |
| `NEWS` | Nyheder | News | — | dropped (unused) |
| `EVENTS` | Arrangementer | Events | `pageEvents` | ported |
| `BASIC_TEXT` | Basis Tekst | Basic Text | `bookBasicText` | ported |
| `HOW_AND_WHY` | Det Virker: Hvordan og Hvorfor | It Works: How and Why | `bookHowAndWhy` | ported |
| `STEP_WORKING_GUIDES` | Vejledninger i Trinarbejde | The NA Step Working Guides | `bookStepWorkingGuides` | ported |
| `SPEAKS` | Speaks | Speaks | `pageSpeaks` | ported |
| `JFT` | Dagens tekst | Just for today | `pageJustForToday` | ported |
| `AUDIOBOOKS` | Lydbøger | Audiobooks | `pageAudiobooks` | ported |
| `NACC` | Cleantimeberegner | Cleantime calculator | `pageCleantimeCalculator` | ported |
| `GRC` | Gruppeoplæsninger | Group readings | `pageGroupReadings` | ported |
| `COMING_SOON` | Kommer snart. | *(missing)* | — | dropped (unused, da only) |
| `COMING_SOON_BODY` | Vi arbejder på det .. | *(missing)* | — | dropped (unused, da only) |
| `MONDAY_IS_FIRST_DAY_OF_WEEK` | true | *(missing)* | — | dropped (boolean, not a string) |
| `LANGUAGE(S)` | Sprog | *(missing)* | — | dropped (da only, unused) |
| `CONVENTION` | Konvent | Convention | `speakConvention` | ported (was hard-coded in template) |
| `OPENING_SPEAKER` | Åbningsspeak | Opening speak | `speakKindOpening` | ported |
| `MAIN_SPEAKER` | Hovedspeak | Main speak | `speakKindMain` | ported |
| `CLOSING_SPEAKER` | Afslutningsspeak | Closing speak | `speakKindClosing` | ported |
| `STEPS` | Trin | *(missing)* | — | dropped (da only, unused) |
| `TRADITIONS` | Traditioner | *(missing)* | — | dropped (da only, unused) |
| `NA_HISTORY` | NA's historie | *(missing)* | — | dropped (da only, unused) |
| `mapsearch.search` | Søg | Search | `mapSearchPlaceholder` | ported |
| `CLEANTIME` | Cleantime | Cleantime | `cleantimeCardTitle` | ported |
| `DATETIME` | Cleantimeberegner | Cleantime counter | `pageCleantimeCalculator` | ported |
| `ENTERCLEANDATE` | Første clean dag | First clean day | `cleantimeFirstCleanDay` | ported |
| `CLEANTIMEINDAYS` | Clean dage | Clean days | `cleantimeCleanDays` | ported |
| `DAY` | dag | day | `unitDays (ICU plural)` | ported |
| `DAYS` | dage | days | `unitDays (ICU plural)` | ported |
| `CLEANTIMEINWEEKS` | Clean uger | Clean weeks | — | dropped (unused) |
| `WEEK` | uge | week | — | dropped (unused) |
| `WEEKS` | uger | weeks | — | dropped (unused) |
| `CLEANTIMEINYEARS` | Clean år | Clean years | `cleantimeCleanYears` | ported |
| `YEAR` | år | year | `unitYears (ICU plural)` | ported |
| `YEARS` | år | years | `unitYears (ICU plural)` | ported |
| `CLEANTIMEINMONTHS` | Clean måneder | Clean months | `cleantimeCleanMonths` | ported |
| `MONTH` | måned | month | `unitMonths (ICU plural)` | ported |
| `MONTHS` | måneder | months | `unitMonths (ICU plural)` | ported |
| `BIRTHDAY` | Mærkedag | Cleanday | `cleantimeCleanday` | ported |
| `DAYCLEAN` | dag | day | `unitDays (ICU plural)` | ported |
| `DAYSCLEAN` | dage | days | `unitDays (ICU plural)` | ported |
| `MONTHCLEAN` | måned | month | `unitMonths (ICU plural)` | ported (was hard-coded in template) |
| `MONTHSCLEAN` | måneder | months | `unitMonths (ICU plural)` | ported |
| `YEARCLEAN` | år | year | `unitYears (ICU plural)` | ported |
| `YEARSCLEAN` | år | years | `unitYears (ICU plural)` | ported |
| `CLEANTIMEUNITSORT` | Cleantime sortering | Cleantime sorting | `settingsCleantimeSorting` | ported |
| `DMY` | dage - måneder - år | days - months - years | `unitOrderDmy` | ported |
| `YMD` | år - måneder - dage | years - months - days | `unitOrderYmd` | ported |
| `OR` | ELLER | OR | `orSeparator` | ported |
| `BACK` | Tilbage | Back | `actionBack` | ported |
| `NEWPROFILE` | Ny profil | New profile | `cleantimeNewProfile` | ported |
| `NEWPROFILENAMEHERE` | Ny profilnavn her | New profile name here | `cleantimeNewProfileNamePlaceholder` | ported |
| `CANCELBUTTON` | Afbryd | Cancel | `actionCancel` | ported |
| `ADDBUTTON` | Opret | Create | `actionCreate` | ported |
| `RENAMEPROFILE` | Omdøb profil | Rename profile | `cleantimeRenameProfile` | ported |
| `RENAME` | Omdøb | Rename | `actionRename` | ported |
| `AREYOUSURE` | Er du sikker? | Are you sure? | `confirmAreYouSure` | ported |
| `DELETE` | Slet | Delete | `actionDelete` | ported |
| `PLAYER_CONTINUE` | Fortsæt afspilning | Continue playing | — | dropped (superseded by PLAYER_CONTINUE_LISTENING) |
| `PLAYER_PLAY` | Afspil | Play | `playerPlay` | ported |
| `PLAYER_PAUSE` | Pause | Pause | `playerPause` | ported |
| `PLAYER_CLOSE` | Luk afspiller | Close player | `playerClose` | ported |
| `PLAYER_PREVIOUS` | Forrige kapitel | Previous chapter | `playerPrevious` | ported |
| `PLAYER_NEXT` | Næste kapitel | Next chapter | `playerNext` | ported |
| `PLAYER_REWIND` | Spol 15 sekunder tilbage | Rewind 15 seconds | `playerRewind` | ported |
| `PLAYER_FORWARD` | Spol 30 sekunder frem | Forward 30 seconds | `playerForward` | ported |
| `SPEAK_SEARCH_PLACEHOLDER` | Søg navn, konvent, by, år … | Search name, convention, city, year … | `speakSearchPlaceholder` | ported |
| `SPEAK_FILTERS` | Filtre | Filters | `speakFilters` | ported |
| `SPEAK_ALL` | Alle | All | `speakAll` | ported |
| `SPEAK_SORT` | Sortering | Sort | `speakSort` | ported |
| `SPEAK_SORT_NEWEST` | Nyeste | Newest | `speakSortNewest` | ported |
| `SPEAK_SORT_OLDEST` | Ældste | Oldest | `speakSortOldest` | ported |
| `SPEAK_SORT_NAME` | Navn | Name | `speakSortName` | ported |
| `SPEAK_YEAR` | År | Year | `speakYear` | ported |
| `SPEAK_ONLY_STARTED` | Kun påbegyndte | Only started | `speakOnlyStarted` | ported |
| `CHAPTERS` | Kapitler | Chapters | `chapters` | ported |
| `PLAYER_CONTINUE_LISTENING` | Fortsæt afspilning | Continue listening | `playerContinueListening` | ported |
| `PLAYER_CONTINUE_FROM` | Fortsæt fra {{time}} | Continue from {{time}} | `playerContinueFrom` | ported |
| `PLAYER_TIME_LEFT` | {{time}} tilbage | {{time}} left | `playerTimeLeft` | ported |
| `PLAYER_NOW_PLAYING` | Afspiller nu | Now playing | `playerNowPlaying` | ported |
| `BOOK_CHAPTER_OF` | Kapitel {{index}} af {{count}} | Chapter {{index}} of {{count}} | `bookChapterOf` | ported |
| `SPEAK_COUNT` | {{count}} speaks | {{count}} speaks | `speakCount` | ported |
| `SPEAK_NONE_FOUND` | Ingen speaks fundet | No speaks found | `speakNoneFound` | ported |
| `SPEAK_NONE_FOUND_BODY` | Prøv et andet søgeord, eller nulstil filtrene. | Try another search word, or reset the filters. | `speakNoneFoundBody` | ported |
| `SPEAK_RESET_FILTERS` | Nulstil | Reset | `speakResetFilters` | ported |
| `SPEAK_LOAD_ERROR` | Kunne ikke hente speaks | Could not load the speaks | `speakLoadError` | ported |
| `SPEAK_LOAD_ERROR_BODY` | Tjek din internetforbindelse og prøv igen. | Check your internet connection and try again. | `speakLoadErrorBody` | ported |
| `SPEAK_RETRY` | Prøv igen | Try again | `speakRetry` | ported |
| `SPEAK_FORGET` | Fjern fra listen | Remove from list | `speakForget` | ported |
| `PLAYER_CAST` | Afspil på Chromecast | Play on Chromecast | `playerCast` | ported |
| `PLAYER_CAST_CONNECTED` | Caster – tryk for valgmuligheder | Casting — tap for options | `playerCastConnected` | ported |
| `PLAYER_PLAYING_ON` | Afspiller på {{device}} | Playing on {{device}} | `playerPlayingOn` | ported |
| `PLAYER_CONNECTING_TO_CAST` | Forbinder til Chromecast… | Connecting to Chromecast… | `playerConnectingToCast` | ported |
| `PLAYER_AIRPLAY` | AirPlay | AirPlay | `playerAirplay` | ported |

New ARB keys with no legacy counterpart (hard-coded Danish in legacy templates
or new states). Slice 0 added: `languageDanish`, `languageEnglish`,
`menuVersion`, `actionOpenMenu`, `actionCloseMenu`, `settingsSearchRangeValue`,
`kmValue`, `contactNotApprovedTitle`, `contactNotApprovedBody`,
`contactMeetingListChangesTitle`, `contactMeetingListServant`,
`contactNaOnlineTitle`, `contactAboutTitle`, `contactSourceCode`,
`contactBugReports`, `contactBuildType`, `contactVersion`,
`contactFinePrintTitle`, `contactFinePrintBody`, `contactImportedSettings`,
`jftCopyright`, `jftUnavailable`. Planned for later slices: `contactMeetingListChangesTitle`, `contactMeetingListServant`,
`contactNaOnlineTitle`, `contactAboutTitle`, `contactBuildType`,
`contactVersion`, `contactFinePrintTitle`, `contactFinePrintBody`,
`contactNotApprovedTitle`, `contactNotApprovedBody`, `contactImportedSettings`,
`cleantimeDefaultProfileName`, `cleantimeSelect`, `notificationCleandayTitle`,
`notificationCleandayBody`, `readingsSelectPlaceholder`, `eventsLoadError`,
`eventsRetry`, `loadingEvents`, `mapUnavailable`, `jftCopyright`,
`menuVersion`.

## Cordova plugins and libraries

| Legacy | Flutter |
|---|---|
| `cordova-plugin-media` (AVPlayer / MediaPlayer) | `just_audio` |
| `cordova-plugin-music-controls2` | `audio_service` |
| `na-cast` (local plugin, Cast sender SDK) | `na_cast` Flutter plugin, same Kotlin/Swift over MethodChannel/EventChannel |
| `na-airplay-picker` (local plugin) | `na_airplay_picker` Flutter plugin, `UiKitView` around `AVRoutePickerView` |
| `cordova-plugin-googlemaps-2` (map, clusters, `LocationService`, `Geocoder`, `Spherical`) | `google_maps_flutter` + clustering in `feature_meetings_map`, `geolocator`, `geocoding`, kernel haversine |
| Places JS SDK in `index.html` | Places HTTPS API through `adapter_places` |
| `cordova-plugin-local-notification` | `flutter_local_notifications` |
| `@ionic/storage` (localForage / IndexedDB) | `shared_preferences` behind `KeyValueStore`; `adapter_legacy_store` plugin for the one-time import |
| `@ionic-native/in-app-browser` (`_system`, `tel:`, `mailto:`) | `url_launcher` |
| `@ionic-native/in-app-browser` (in-app window for events) | `webview_flutter` in `NaModalPage` |
| `@ionic-native/http` (CORS bypass) | not needed; `http` package |
| `@ionic-native/base64` | not needed |
| `cordova-plugin-device` | `package_info_plus` |
| `cordova-plugin-ionic-keyboard` | Flutter built-in |
| `@ngx-translate/core` + JSON | `flutter_localizations` + `intl` gen-l10n from ARB |
| `moment`, `moment-timezone` | `LocalDate` in `na_kernel` + `intl` `DateFormat` |
| `thenby` | `package:collection` `sortedBy` / `compareBy` |
| `@angular/router` | `go_router` |
| RxJS `BehaviorSubject` | Riverpod `Notifier` + `Stream`s from adapters |
| Jest | `flutter_test`, Patrol |
