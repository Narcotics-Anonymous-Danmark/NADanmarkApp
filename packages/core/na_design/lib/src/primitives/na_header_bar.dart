import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

final class NaHeaderBar extends StatelessWidget {
  const NaHeaderBar({
    required this.leading,
    required this.title,
    required this.trailing,
    super.key,
  });

  final Widget leading;
  final String title;
  final Widget trailing;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    final statusBarBrightness = theme.colors.statusBarBrightness;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: theme.colors.statusBar,
        statusBarBrightness: statusBarBrightness,
        statusBarIconBrightness: switch (statusBarBrightness) {
          Brightness.light => Brightness.dark,
          Brightness.dark => Brightness.light,
        },
      ),
      child: ColoredBox(
        color: theme.colors.statusBar,
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colors.surface,
              border: Border(
                bottom: BorderSide(color: theme.colors.background),
              ),
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: SizedBox(
                height: height,
                child: Row(
                  children: [
                    leading,
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.sm,
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.title,
                          ),
                        ),
                      ),
                    ),
                    trailing,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class NaHeaderSpacer extends StatelessWidget {
  const NaHeaderSpacer({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(width: 48, height: 48);
}
