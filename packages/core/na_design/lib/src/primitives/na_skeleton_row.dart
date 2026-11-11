import 'package:flutter/widgets.dart';
import 'package:na_design/src/primitives/na_list_row.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_radii.dart';
import 'package:na_design/src/tokens/na_spacing.dart';

final class NaSkeletonRow extends StatelessWidget {
  const NaSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: NaListBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FractionallySizedBox(
            widthFactor: 0.55,
            child: _SkeletonBar(height: 16),
          ),
          SizedBox(height: Space.sm),
          FractionallySizedBox(
            widthFactor: 0.35,
            child: _SkeletonBar(height: 12),
          ),
        ],
      ),
    ),
  );
}

final class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: NaTheme.of(context).colors.background,
      borderRadius: BorderRadius.circular(Radius.card),
    ),
    child: SizedBox(height: height),
  );
}
