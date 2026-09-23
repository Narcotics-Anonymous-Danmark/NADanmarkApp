import 'package:flutter/widgets.dart';
import 'package:na_design/na_design.dart';
import 'package:na_l10n/na_l10n.dart';

extension type const RoutePath(String value) {}

enum MenuDestination {
  home(path: RoutePath('/home'), icon: NaIcons.home),
  map(path: RoutePath('/map-search'), icon: NaIcons.map),
  nearby(path: RoutePath('/location-search'), icon: NaIcons.search),
  meetings(path: RoutePath('/listfull'), icon: NaIcons.list),
  justForToday(path: RoutePath('/jft'), icon: NaIcons.albums),
  cleantime(path: RoutePath('/cleantime-counter'), icon: NaIcons.hourglass),
  events(path: RoutePath('/events'), icon: NaIcons.calendar),
  audiobooks(path: RoutePath('/audiobooks'), icon: NaIcons.book),
  speaks(path: RoutePath('/speaks'), icon: NaIcons.chat),
  groupReadings(path: RoutePath('/grc'), icon: NaIcons.reader),
  settings(path: RoutePath('/settings'), icon: NaIcons.settings),
  about(path: RoutePath('/contact'), icon: NaIcons.person)
  ;

  const MenuDestination({required this.path, required this.icon});

  final RoutePath path;
  final IconData icon;

  NaSelection selectionAt({required RoutePath location}) =>
      location == path || location.value.startsWith('${path.value}/')
      ? NaSelection.selected
      : NaSelection.unselected;

  static RoutePath parentOf({required RoutePath location}) => values
      .firstWhere(
        (destination) =>
            location.value.startsWith('${destination.path.value}/'),
        orElse: () => MenuDestination.home,
      )
      .path;

  String label({required AppLocalizations l10n}) => switch (this) {
    MenuDestination.home => l10n.home,
    MenuDestination.map => l10n.mapSearch,
    MenuDestination.nearby => l10n.locationsearch,
    MenuDestination.meetings => l10n.listfull,
    MenuDestination.justForToday => l10n.jft,
    MenuDestination.cleantime => l10n.nacc,
    MenuDestination.events => l10n.events,
    MenuDestination.audiobooks => l10n.audiobooks,
    MenuDestination.speaks => l10n.speaks,
    MenuDestination.groupReadings => l10n.grc,
    MenuDestination.settings => l10n.settings,
    MenuDestination.about => l10n.contact,
  };
}

enum BookRoute {
  basicText(path: RoutePath('/basic-text')),
  howAndWhy(path: RoutePath('/how-and-why')),
  stepWorkingGuides(path: RoutePath('/step-working-guides'))
  ;

  const BookRoute({required this.path});

  final RoutePath path;

  String label({required AppLocalizations l10n}) => switch (this) {
    BookRoute.basicText => l10n.basicText,
    BookRoute.howAndWhy => l10n.howAndWhy,
    BookRoute.stepWorkingGuides => l10n.stepWorkingGuides,
  };
}
