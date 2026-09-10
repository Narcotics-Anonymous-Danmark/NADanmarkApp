import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';

enum NaDrawerVisibility { open, closed }

final class NaDrawerLayout extends StatelessWidget {
  const NaDrawerLayout({
    required this.visibility,
    required this.drawer,
    required this.body,
    required this.onDismiss,
    required this.dismissLabel,
    super.key,
  });

  final NaDrawerVisibility visibility;
  final Widget drawer;
  final Widget body;
  final VoidCallback onDismiss;
  final String dismissLabel;

  static const double width = 300;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    final open = visibility == NaDrawerVisibility.open;
    return Stack(
      children: [
        body,
        IgnorePointer(
          ignoring: !open,
          child: AnimatedOpacity(
            opacity: open ? 1 : 0,
            duration: theme.motion.normal,
            curve: theme.motion.curve,
            child: Semantics(
              button: true,
              label: dismissLabel,
              child: GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(
                  child: ColoredBox(color: Color(0x66000000)),
                ),
              ),
            ),
          ),
        ),
        AnimatedSlide(
          offset: open ? Offset.zero : const Offset(-1.05, 0),
          duration: theme.motion.normal,
          curve: theme.motion.curve,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: width,
              child: ExcludeSemantics(excluding: !open, child: drawer),
            ),
          ),
        ),
      ],
    );
  }
}
