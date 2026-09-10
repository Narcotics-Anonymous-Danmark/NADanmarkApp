import 'package:feature_jft/src/application/jft_controller.dart';
import 'package:feature_jft/src/widgets/jft_entry_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';
import 'package:na_ports/na_ports.dart';

final class JftBody extends ConsumerWidget {
  const JftBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final year = ref.watch(clockProvider).today().year;
    return NaScrollBody(
      children: [
        switch (ref.watch(jftControllerProvider)) {
          Loading() => const SizedBox.shrink(),
          Failed() => NaErrorState(message: l10n.jftUnavailable),
          Loaded(value: JftMissing()) => NaErrorState(
            message: l10n.jftUnavailable,
          ),
          Loaded(value: JftFound(:final entry)) => NaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JftEntryView(entry: entry, scale: JftScale.full),
                const SizedBox(height: Space.md),
                Text(
                  l10n.jftCopyright(year),
                  key: const Key('jft-copyright'),
                  textAlign: TextAlign.center,
                  style: NaTheme.of(context).typography.footnote,
                ),
              ],
            ),
          ),
        },
      ],
    );
  }
}
