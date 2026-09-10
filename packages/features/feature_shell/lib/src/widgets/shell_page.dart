import 'package:feature_shell/src/application/docked_player.dart';
import 'package:feature_shell/src/application/menu_controller.dart';
import 'package:feature_shell/src/application/menu_destination.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:na_design/na_design.dart';
import 'package:na_l10n/na_l10n.dart';

sealed class PageBack {
  const PageBack();
}

final class NoBack extends PageBack {
  const NoBack();
}

final class BackTo extends PageBack {
  const BackTo({required this.parent});

  final RoutePath parent;
}

final class ShellPage extends ConsumerWidget {
  const ShellPage({
    required this.title,
    required this.body,
    required this.back,
    super.key,
  });

  final String title;
  final Widget body;
  final PageBack back;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dock = ref.watch(dockedPlayerProvider);
    return NaPageFrame(
      header: NaHeaderBar(
        leading: NaIconButton(
          key: const Key('menu-button'),
          icon: NaIcons.menu,
          label: l10n.actionOpenMenu,
          onPressed: () => ref.read(menuControllerProvider.notifier).open(),
        ),
        title: title,
        trailing: switch (back) {
          NoBack() => const NaHeaderSpacer(),
          BackTo(:final parent) => NaIconButton(
            key: const Key('back-button'),
            icon: NaIcons.back,
            label: l10n.back,
            onPressed: () => context.go(parent.value),
          ),
        },
      ),
      body: body,
      bottomInset: dock.height,
    );
  }
}
