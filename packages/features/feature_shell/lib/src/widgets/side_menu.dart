import 'package:feature_shell/src/application/menu_controller.dart';
import 'package:feature_shell/src/application/menu_destination.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:na_design/na_design.dart';
import 'package:na_l10n/na_l10n.dart';
import 'package:na_ports/na_ports.dart';

final class SideMenu extends ConsumerWidget {
  const SideMenu({required this.location, super.key});

  final RoutePath location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final info = ref.watch(appInfoProvider);
    return NaSideMenu(
      title: l10n.menu,
      entries: MenuDestination.values
          .map(
            (destination) => NaMenuTile(
              key: Key('menu-${destination.name}'),
              icon: destination.icon,
              label: destination.label(l10n: l10n),
              selected: destination.selectionAt(location: location),
              onTap: () {
                ref.read(menuControllerProvider.notifier).close();
                context.go(destination.path.value);
              },
            ),
          )
          .toList(growable: false),
      footer: Text(
        l10n.menuVersion(info.version.value),
        key: const Key('menu-version'),
        style: NaTheme.of(context).typography.caption,
      ),
    );
  }
}
