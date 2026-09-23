import 'package:feature_shell/src/application/back_rule.dart';
import 'package:feature_shell/src/application/docked_player.dart';
import 'package:feature_shell/src/application/global_loading.dart';
import 'package:feature_shell/src/application/menu_controller.dart';
import 'package:feature_shell/src/application/menu_destination.dart';
import 'package:feature_shell/src/widgets/side_menu.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class NaShell extends ConsumerWidget {
  const NaShell({required this.location, required this.child, super.key});

  final RoutePath location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final menu = ref.watch(menuControllerProvider);
    final behaviour = const BackRule().resolve(location: location, menu: menu);
    return PopScope<Object>(
      canPop: behaviour is LeaveApp,
      onPopInvokedWithResult: (didPop, result) {
        switch (behaviour) {
          case CloseMenu():
            ref.read(menuControllerProvider.notifier).close();
          case PopToParent(:final parent):
            context.go(parent.value);
          case GoHome():
            context.go(MenuDestination.home.path.value);
          case LeaveApp():
            return;
        }
      },
      child: NaDrawerLayout(
        visibility: menu,
        drawer: SideMenu(location: location),
        onDismiss: () => ref.read(menuControllerProvider.notifier).close(),
        dismissLabel: l10n.actionCloseMenu,
        body: Column(
          children: [
            const GlobalLoadingBar(),
            Expanded(child: child),
            const DockedPlayerHost(),
          ],
        ),
      ),
    );
  }
}

final class GlobalLoadingBar extends ConsumerWidget {
  const GlobalLoadingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(globalLoadingProvider)) {
        LoadingIdle() => const SizedBox(height: NaIndeterminateBar.height),
        LoadingActive(:final status) => NaIndeterminateBar(
          key: const Key('global-loading-bar'),
          statusText: switch (status) {
            LoadingText(:final text) => text,
            BusyStatus(activity: BusyActivity.findingMeetings) =>
              AppLocalizations.of(context).findingMtgs,
          },
        ),
      };
}

final class DockedPlayerHost extends ConsumerWidget {
  const DockedPlayerHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(dockedPlayerProvider)) {
        NoPlayer() => const SizedBox.shrink(),
        PlayerDocked(:final player, :final height) => SizedBox(
          height: height,
          child: player,
        ),
      };
}
