import 'package:flutter/widgets.dart';
import 'package:na_design/src/primitives/na_card.dart';
import 'package:na_design/src/theme/na_theme.dart';

final class NaErrorState extends StatelessWidget {
  const NaErrorState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => NaCard(
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: NaTheme.of(context).typography.body.copyWith(
          color: NaTheme.of(context).colors.danger,
        ),
      ),
    ),
  );
}
