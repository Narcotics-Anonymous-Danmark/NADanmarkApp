import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_motion.dart';
import 'package:na_design/src/tokens/na_spacing.dart';
import 'package:na_design/src/values/na_values.dart';

final class NaSwipeActions extends StatefulWidget {
  const NaSwipeActions({
    required this.child,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  static const double actionWidth = 132;

  final Widget child;
  final NaLabel actionLabel;
  final VoidCallback onAction;

  @override
  State<NaSwipeActions> createState() => _NaSwipeActionsState();
}

sealed class _Reveal {
  const _Reveal();

  double get offset;
}

final class _Closed extends _Reveal {
  const _Closed();

  @override
  double get offset => 0;
}

final class _Open extends _Reveal {
  const _Open();

  @override
  double get offset => NaSwipeActions.actionWidth;
}

final class _Dragging extends _Reveal {
  const _Dragging({required this.offset});

  @override
  final double offset;
}

final class _NaSwipeActionsState extends State<NaSwipeActions> {
  _Reveal _reveal = const _Closed();

  void _drag(DragUpdateDetails details) => setState(
    () => _reveal = _Dragging(
      offset: (_reveal.offset - details.delta.dx).clamp(
        0,
        NaSwipeActions.actionWidth,
      ),
    ),
  );

  void _release(DragEndDetails details) => setState(
    () => _reveal = _reveal.offset > NaSwipeActions.actionWidth / 2
        ? const _Open()
        : const _Closed(),
  );

  void _close() => setState(() => _reveal = const _Closed());

  void _act() {
    _close();
    widget.onAction();
  }

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: widget.actionLabel.value): _act,
      },
      child: ClipRect(
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: theme.colors.inkMuted,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: GestureDetector(
                    key: const Key('na-swipe-action'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _act,
                    child: SizedBox(
                      width: NaSwipeActions.actionWidth,
                      child: Padding(
                        padding: const EdgeInsets.all(Space.sm),
                        child: Text(
                          widget.actionLabel.value,
                          textAlign: TextAlign.center,
                          style: theme.typography.label.copyWith(
                            color: theme.colors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onHorizontalDragUpdate: _drag,
              onHorizontalDragEnd: _release,
              child: AnimatedContainer(
                duration: switch (_reveal) {
                  _Dragging() => Duration.zero,
                  _Open() || _Closed() => NaMotion.standard.fast,
                },
                transform: Matrix4.translationValues(-_reveal.offset, 0, 0),
                child: switch (_reveal) {
                  _Closed() => widget.child,
                  _Open() || _Dragging() => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _close,
                    child: AbsorbPointer(child: widget.child),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
