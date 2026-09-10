import 'package:feature_contact/feature_contact.dart';
import 'package:feature_jft/feature_jft.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:feature_shell/feature_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:na_app/app/na_page.dart';
import 'package:na_l10n/na_l10n.dart';

const String homePath = '/home';

final Set<String> knownPaths = Set.unmodifiable({
  ...MenuDestination.values.map((d) => d.path.value),
  ...BookRoute.values.map((b) => b.path.value),
});

GoRouter createRouter({required String initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  redirect: (context, state) =>
      knownPaths.contains(state.uri.path) ? null : homePath,
  routes: [
    ShellRoute(
      builder: (context, state, child) => NaShell(
        location: RoutePath(state.uri.path),
        child: child,
      ),
      routes: [
        ...MenuDestination.values.map(
          (destination) => GoRoute(
            path: destination.path.value,
            pageBuilder: (context, state) => NaPage(
              key: state.pageKey,
              child: DestinationPage(destination: destination),
            ),
          ),
        ),
        ...BookRoute.values.map(
          (book) => GoRoute(
            path: book.path.value,
            pageBuilder: (context, state) => NaPage(
              key: state.pageKey,
              child: BookPage(book: book),
            ),
          ),
        ),
      ],
    ),
  ],
);

final class DestinationPage extends StatelessWidget {
  const DestinationPage({required this.destination, super.key});

  final MenuDestination destination;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ShellPage(
      title: destination.label(l10n: l10n),
      back: const NoBack(),
      body: switch (destination) {
        MenuDestination.home => HomeBody(
          cards: [
            JftPreviewCard(
              onTap: () => context.go(MenuDestination.justForToday.path.value),
            ),
          ],
        ),
        MenuDestination.justForToday => const JftBody(),
        MenuDestination.settings => const SettingsBody(),
        MenuDestination.about => const ContactBody(),
        MenuDestination.map ||
        MenuDestination.nearby ||
        MenuDestination.meetings ||
        MenuDestination.cleantime ||
        MenuDestination.events ||
        MenuDestination.audiobooks ||
        MenuDestination.speaks ||
        MenuDestination.groupReadings => const SizedBox.shrink(),
      },
    );
  }
}

final class BookPage extends StatelessWidget {
  const BookPage({required this.book, super.key});

  final BookRoute book;

  @override
  Widget build(BuildContext context) => ShellPage(
    title: book.label(l10n: AppLocalizations.of(context)),
    back: BackTo(parent: MenuDestination.audiobooks.path),
    body: const SizedBox.shrink(),
  );
}
