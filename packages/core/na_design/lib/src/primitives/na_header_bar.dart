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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        border: Border(bottom: BorderSide(color: theme.colors.background)),
      ),
      child: SafeArea(
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
    );
  }
}

final class NaHeaderSpacer extends StatelessWidget {
  const NaHeaderSpacer({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(width: 48, height: 48);
}
