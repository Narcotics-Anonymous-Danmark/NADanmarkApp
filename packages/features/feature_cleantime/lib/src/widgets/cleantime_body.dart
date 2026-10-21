import 'package:feature_cleantime/src/application/anniversary_schedule.dart';
import 'package:feature_cleantime/src/application/cleantime_controller.dart';
import 'package:feature_cleantime/src/application/cleantime_texts.dart';
import 'package:feature_cleantime/src/widgets/key_tag_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

Language languageOf(BuildContext context) =>
    Language.fromCode(code: Localizations.localeOf(context).languageCode);

final class CleantimeBody extends ConsumerWidget {
  const CleantimeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(anniversaryRefreshOnShowProvider);
    return switch (ref.watch(cleantimeControllerProvider)) {
      Loaded(:final value) => CleantimeContent(view: value),
      Loading() || Failed() => const NaScrollBody(children: []),
    };
  }
}

final class CleantimeContent extends StatelessWidget {
  const CleantimeContent({required this.view, super.key});

  final CleantimeView view;

  @override
  Widget build(BuildContext context) => NaScrollBody(
    children: [
      ProfileHeader(view: view),
      CleanDateField(view: view),
      switch (view.anniversaryToday) {
        OnAnniversary(:final anniversary) => CleandayCard(
          anniversary: anniversary,
        ),
        NoAnniversary() => const SizedBox.shrink(),
      },
      CleanTimeGroups(groups: view.groups),
    ],
  );
}

final class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({required this.view, super.key});

  final CleantimeView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: Space.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: ProfileSelector(
              name: view.active.name,
              onTap: () => _select(context: context, ref: ref, l10n: l10n),
            ),
          ),
          NaIconButton(
            key: const Key('cleantime-add-profile'),
            icon: NaIcons.addPlain,
            label: l10n.cleantimeAddProfile,
            tone: NaTone.success,
            onPressed: () => _add(context: context, ref: ref, l10n: l10n),
          ),
          NaIconButton(
            key: const Key('cleantime-rename-profile'),
            icon: NaIcons.edit,
            label: l10n.renameprofile,
            tone: NaTone.primary,
            onPressed: () => _rename(context: context, ref: ref, l10n: l10n),
          ),
          NaIconButton(
            key: const Key('cleantime-delete-profile'),
            icon: NaIcons.trash,
            label: l10n.cleantimeDeleteProfile,
            tone: NaTone.danger,
            onPressed: () => _delete(context: context, ref: ref, l10n: l10n),
          ),
        ],
      ),
    );
  }

  Future<void> _select({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) async {
    final controller = ref.read(cleantimeControllerProvider.notifier);
    final choice = showNaOptionDialog<ProfileIndex>(
      context: context,
      title: l10n.cleantimeSelectProfile,
      options: List.unmodifiable(
        view.profiles.entries.indexed.map(
          (entry) => NaOption(
            value: ProfileIndex(entry.$1),
            label: entry.$2.name.text,
          ),
        ),
      ),
      selected: view.profiles.active,
      cancelLabel: l10n.cancelbutton,
    );
    switch (await choice) {
      case NaOptionPicked(:final value):
        await controller.select(index: value);
      case NaOptionCancelled():
        break;
    }
  }

  Future<void> _add({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) async {
    final controller = ref.read(cleantimeControllerProvider.notifier);
    final choice = showNaTextInputDialog(
      context: context,
      title: NaLabel(l10n.newprofile),
      placeholder: NaLabel(l10n.newprofilenamehere),
      initialText: const NaInputText(''),
      cancelLabel: NaLabel(l10n.cancelbutton),
      confirmLabel: NaLabel(l10n.addbutton),
    );
    switch (await choice) {
      case NaTextEntered(:final text):
        await controller.add(name: ProfileName(text.value));
      case NaTextCancelled():
        break;
    }
  }

  Future<void> _rename({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) async {
    final controller = ref.read(cleantimeControllerProvider.notifier);
    final choice = showNaTextInputDialog(
      context: context,
      title: NaLabel(l10n.renameprofile),
      placeholder: NaLabel(view.active.name.text),
      initialText: NaInputText(view.active.name.text),
      cancelLabel: NaLabel(l10n.cancelbutton),
      confirmLabel: NaLabel(l10n.rename),
    );
    switch (await choice) {
      case NaTextEntered(:final text):
        await controller.rename(name: ProfileName(text.value));
      case NaTextCancelled():
        break;
    }
  }

  Future<void> _delete({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
  }) async {
    final controller = ref.read(cleantimeControllerProvider.notifier);
    final choice = showNaConfirmDialog(
      context: context,
      title: NaLabel(l10n.areyousure),
      cancelLabel: NaLabel(l10n.cancelbutton),
      confirmLabel: NaLabel(l10n.delete),
    );
    switch (await choice) {
      case NaConfirmation.confirmed:
        await controller.deleteActive();
      case NaConfirmation.declined:
        break;
    }
  }
}

final class ProfileSelector extends StatelessWidget {
  const ProfileSelector({required this.name, required this.onTap, super.key});

  final ProfileName name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).cleantimeSelectProfile,
      value: name.text,
      child: GestureDetector(
        key: const Key('cleantime-profile-selector'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: ExcludeSemantics(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name.text,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.heading,
                  ),
                ),
                const SizedBox(width: Space.xs),
                Icon(NaIcons.caret, size: 18, color: theme.colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class CleanDateField extends ConsumerWidget {
  const CleanDateField({required this.view, super.key});

  static const LocalDate earliest = LocalDate(year: 1950, month: 1, day: 1);

  final CleantimeView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final format = LocalDateFormat(language: languageOf(context));
    return NaListRow(
      key: const Key('cleantime-date-field'),
      label: l10n.entercleandate,
      value: format
          .format(
            date: view.active.cleanDate,
            pattern: DatePattern.dayShortMonthYear,
          )
          .text,
      onTap: () =>
          _pick(context: context, ref: ref, l10n: l10n, format: format),
    );
  }

  Future<void> _pick({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required LocalDateFormat format,
  }) async {
    final controller = ref.read(cleantimeControllerProvider.notifier);
    final cleanDate = view.active.cleanDate;
    final choice = showNaDatePicker(
      context: context,
      initial: cleanDate,
      first: switch (cleanDate.compareTo(other: earliest)) {
        Comparison.before => cleanDate,
        Comparison.same || Comparison.after => earliest,
      },
      last: view.today,
      labels: NaDateWheelLabels(
        day: NaLabel(l10n.datePickerDay),
        month: NaLabel(l10n.datePickerMonth),
        year: NaLabel(l10n.datePickerYear),
        monthNames: List.unmodifiable(
          format.monthNames.map((name) => NaLabel(name.text)),
        ),
      ),
      cancelLabel: NaLabel(l10n.cancel),
      confirmLabel: NaLabel(l10n.ok),
    );
    switch (await choice) {
      case NaDatePicked(:final date):
        await controller.changeDate(cleanDate: date);
      case NaDateCancelled():
        break;
    }
  }
}

final class CleandayCard extends StatelessWidget {
  const CleandayCard({required this.anniversary, super.key});

  static const double keyTagHeight = 200;

  final Anniversary anniversary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = CleantimeTexts(
      l10n: l10n,
    ).anniversaryText(anniversary: anniversary).text;
    final theme = NaTheme.of(context);
    return NaCard(
      key: const Key('cleantime-cleanday'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NaCardTitle(text: l10n.birthday),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.typography.display,
          ),
          const SizedBox(height: Space.md),
          Image(
            image: KeyTagImage(
              kind: anniversary.kind,
              language: languageOf(context),
            ).image,
            height: keyTagHeight,
            fit: BoxFit.contain,
            semanticLabel: l10n.cleantimeKeyTag(text),
          ),
        ],
      ),
    );
  }
}

final class CleanTimeGroups extends StatelessWidget {
  const CleanTimeGroups({required this.groups, super.key});

  final List<List<CleanTimeAmount>> groups;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ...groups.indexed.expand(
        (entry) => [
          if (entry.$1 > 0) const OrSeparator(),
          Column(
            key: Key('cleantime-group-${entry.$1 + 1}'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.unmodifiable(
              entry.$2.map((amount) => CleanTimeCard(amount: amount)),
            ),
          ),
        ],
      ),
    ],
  );
}

final class OrSeparator extends StatelessWidget {
  const OrSeparator({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.sm),
    child: Text(
      '- ${AppLocalizations.of(context).or} -',
      textAlign: TextAlign.center,
      style: NaTheme.of(context).typography.heading,
    ),
  );
}

final class CleanTimeCard extends StatelessWidget {
  const CleanTimeCard({required this.amount, super.key});

  final CleanTimeAmount amount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texts = CleantimeTexts(l10n: l10n);
    final theme = NaTheme.of(context);
    final (title, value) = switch (amount) {
      YearsAmount(:final years) => (
        l10n.cleantimeinyears,
        texts.years(years: years),
      ),
      MonthsAmount(:final months) => (
        l10n.cleantimeinmonths,
        texts.months(months: months),
      ),
      DaysAmount(:final days) => (
        l10n.cleantimeindays,
        texts.days(days: days),
      ),
    };
    return NaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            key: const Key('cleantime-unit-title'),
            style: theme.typography.heading,
          ),
          const SizedBox(height: Space.sm),
          Text(
            value.text,
            key: const Key('cleantime-value'),
            style: theme.typography.display,
          ),
        ],
      ),
    );
  }
}
