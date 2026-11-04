import 'package:feature_media_player/src/application/progress_text.dart';
import 'package:flutter/widgets.dart';
import 'package:na_design/na_design.dart';

final class ProgressLine extends StatelessWidget {
  const ProgressLine({required this.progress, super.key});

  final ShownProgress progress;

  @override
  Widget build(BuildContext context) => switch (progress) {
    HiddenProgress() => const SizedBox.shrink(),
    VisibleProgress(:final fraction, :final label) => Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(child: NaProgressBar(fraction: fraction)),
          const SizedBox(height: Space.xs),
          Text(
            label.value,
            style: NaTheme.of(context).typography.caption.copyWith(
              color: NaTheme.of(context).colors.primary,
            ),
          ),
        ],
      ),
    ),
  };
}
