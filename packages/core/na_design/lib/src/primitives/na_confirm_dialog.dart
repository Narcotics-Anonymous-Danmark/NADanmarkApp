import 'package:flutter/widgets.dart';
import 'package:na_design/src/flutter_bridge/na_multi_option_dialog.dart';
import 'package:na_design/src/primitives/na_dialog_surface.dart';
import 'package:na_design/src/values/na_values.dart';

enum NaConfirmation { confirmed, declined }

Future<NaConfirmation> showNaConfirmDialog({
  required BuildContext context,
  required NaLabel title,
  required NaLabel cancelLabel,
  required NaLabel confirmLabel,
}) => showNaDialog(
  context: context,
  barrierLabel: cancelLabel,
  dismissed: NaConfirmation.declined,
  builder: (dialogContext) => NaConfirmSheet(
    title: title,
    cancelLabel: cancelLabel,
    confirmLabel: confirmLabel,
    onAnswered: (answer) => Navigator.of(dialogContext).pop(answer),
  ),
);

final class NaConfirmSheet extends StatelessWidget {
  const NaConfirmSheet({
    required this.title,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onAnswered,
    super.key,
  });

  final NaLabel title;
  final NaLabel cancelLabel;
  final NaLabel confirmLabel;
  final ValueChanged<NaConfirmation> onAnswered;

  @override
  Widget build(BuildContext context) => NaDialogSurface(
    children: [
      NaDialogTitle(title: title),
      NaDialogActions(
        children: [
          NaDialogTextButton(
            key: const Key('na-dialog-cancel'),
            label: cancelLabel,
            availability: NaAvailability.enabled,
            onTap: () => onAnswered(NaConfirmation.declined),
          ),
          NaDialogTextButton(
            key: const Key('na-dialog-confirm'),
            label: confirmLabel,
            availability: NaAvailability.enabled,
            onTap: () => onAnswered(NaConfirmation.confirmed),
          ),
        ],
      ),
    ],
  );
}
