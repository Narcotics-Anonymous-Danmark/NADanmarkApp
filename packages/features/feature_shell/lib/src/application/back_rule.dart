import 'package:feature_shell/src/application/menu_destination.dart';
import 'package:na_design/na_design.dart';

sealed class BackBehaviour {
  const BackBehaviour();
}

final class CloseMenu extends BackBehaviour {
  const CloseMenu();
}

final class PopToParent extends BackBehaviour {
  const PopToParent({required this.parent});

  final RoutePath parent;
}

final class GoHome extends BackBehaviour {
  const GoHome();
}

final class LeaveApp extends BackBehaviour {
  const LeaveApp();
}

final class BackRule {
  const BackRule();

  BackBehaviour resolve({
    required RoutePath location,
    required NaDrawerVisibility menu,
  }) {
    if (menu == NaDrawerVisibility.open) {
      return const CloseMenu();
    }
    if (BookRoute.values.any((book) => book.path == location)) {
      return PopToParent(parent: MenuDestination.audiobooks.path);
    }
    if (MenuDestination.values.any(
      (destination) => location.value.startsWith('${destination.path.value}/'),
    )) {
      return PopToParent(parent: MenuDestination.parentOf(location: location));
    }
    if (location == MenuDestination.home.path) {
      return const LeaveApp();
    }
    return const GoHome();
  }
}
