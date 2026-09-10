import 'package:feature_jft/src/application/jft_controller.dart';
import 'package:feature_jft/src/widgets/jft_entry_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class JftPreviewCard extends ConsumerWidget {
  const JftPreviewCard({required this.onTap, super.key});

  final VoidCallback onTap;

  static const double clipHeight = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(jftControllerProvider)) {
      Loaded(value: JftFound(:final entry)) => Semantics(
        button: true,
        label: l10n.jft,
        child: GestureDetector(
          key: const Key('jft-preview-card'),
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: NaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NaCardTitle(text: l10n.jft),
                NaFadeClip(
                  maxHeight: clipHeight,
                  child: JftEntryView(entry: entry, scale: JftScale.preview),
                ),
              ],
            ),
          ),
        ),
      ),
      Loaded(value: JftMissing()) ||
      Loading() ||
      Failed() => const SizedBox.shrink(),
    };
  }
}
