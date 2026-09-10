import 'package:flutter/widgets.dart';
import 'package:na_design/na_design.dart';
import 'package:na_l10n/na_l10n.dart';

final class HomeBody extends StatelessWidget {
  const HomeBody({required this.cards, super.key});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = NaTheme.of(context);
    final onPrimary = theme.colors.onPrimary;
    return ColoredBox(
      color: theme.colors.primary,
      child: NaScrollBody(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.homeTitle,
                    key: const Key('welcome-title'),
                    textAlign: TextAlign.center,
                    style: theme.typography.heading.copyWith(color: onPrimary),
                  ),
                ),
                Text(
                  l10n.homeMessage,
                  key: const Key('home-helpline'),
                  textAlign: TextAlign.center,
                  style: theme.typography.heading.copyWith(color: onPrimary),
                ),
              ],
            ),
          ),
          ...cards,
        ],
      ),
    );
  }
}
