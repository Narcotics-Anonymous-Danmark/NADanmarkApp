import 'dart:ui' as ui show Radius;

import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_icons.dart';
import 'package:na_design/src/tokens/na_radii.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

Future<void> showNaPopover({
  required BuildContext context,
  required Key popoverKey,
  required Key closeKey,
  required String title,
  required String closeLabel,
  required Widget child,
}) async {
  final theme = NaTheme.of(context);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: closeLabel,
    barrierColor: const Color(0x66000000),
    transitionDuration: theme.motion.fast,
    pageBuilder: (dialogContext, animation, secondaryAnimation) => NaTheme(
      data: theme,
      child: NaPopover(
        key: popoverKey,
        closeKey: closeKey,
        title: title,
        closeLabel: closeLabel,
        onClose: () => Navigator.of(dialogContext).pop(),
        child: child,
      ),
    ),
  );
}

final class NaPopover extends StatelessWidget {
  const NaPopover({
    required this.closeKey,
    required this.title,
    required this.closeLabel,
    required this.onClose,
    required this.child,
    super.key,
  });

  final Key closeKey;
  final String title;
  final String closeLabel;
  final VoidCallback onClose;
  final Widget child;

  static const double maxWidth = 420;
  static const double widthFraction = 0.92;
  static const double heightFraction = 0.7;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    final screen = MediaQuery.sizeOf(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (screen.width * widthFraction).clamp(0, maxWidth),
          maxHeight: screen.height * heightFraction,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.surface,
            borderRadius: BorderRadius.circular(Radius.card),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NaPopoverBar(
                closeKey: closeKey,
                title: title,
                closeLabel: closeLabel,
                onClose: onClose,
              ),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

final class NaPopoverBar extends StatelessWidget {
  const NaPopoverBar({
    required this.closeKey,
    required this.title,
    required this.closeLabel,
    required this.onClose,
    super.key,
  });

  final Key closeKey;
  final String title;
  final String closeLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.primary,
        borderRadius: const BorderRadius.vertical(
          top: ui.Radius.circular(Radius.card),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.typography.heading.copyWith(
                    color: theme.colors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: closeLabel,
            child: GestureDetector(
              key: closeKey,
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  NaIcons.dismiss,
                  size: 24,
                  color: theme.colors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
