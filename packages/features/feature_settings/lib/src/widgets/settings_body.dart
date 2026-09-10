import 'package:feature_settings/src/application/current_language.dart';
import 'package:feature_settings/src/application/search_radius_draft.dart';
import 'package:feature_settings/src/application/settings_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class SettingsBody extends ConsumerWidget {
  const SettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    return NaScrollBody(
      children: [
        LanguageRow(language: settings.language),
        FirstDayRow(firstDay: settings.firstDayOfWeek),
        UnitOrderRow(order: settings.cleanTimeUnitOrder),
        SearchRadiusCard(radius: settings.searchRadius),
      ],
    );
  }
}

final class LanguageRow extends ConsumerWidget {
  const LanguageRow({required this.language, super.key});

  final Language language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    String label(Language value) => switch (value) {
      Language.danish => l10n.languageDanish,
      Language.english => l10n.languageEnglish,
    };
    return NaListRow(
      key: const Key('settings-language'),
      label: l10n.language,
      value: label(language),
      onTap: () async {
        final choice = await showNaOptionDialog<Language>(
          context: context,
          title: l10n.language,
          options: Language.values
              .map((value) => NaOption(value: value, label: label(value)))
              .toList(growable: false),
          selected: language,
          cancelLabel: l10n.cancel,
        );
        switch (choice) {
          case NaOptionPicked(:final value):
            await ref
                .read(settingsControllerProvider.notifier)
                .changeLanguage(language: value);
          case NaOptionCancelled():
            return;
        }
      },
    );
  }
}

final class FirstDayRow extends ConsumerWidget {
  const FirstDayRow({required this.firstDay, super.key});

  final FirstDayOfWeek firstDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    String label(FirstDayOfWeek value) => switch (value) {
      FirstDayOfWeek.monday => l10n.monday,
      FirstDayOfWeek.sunday => l10n.sunday,
    };
    return NaListRow(
      key: const Key('settings-first-day'),
      label: l10n.firstdayofweeksetting,
      value: label(firstDay),
      onTap: () async {
        final choice = await showNaOptionDialog<FirstDayOfWeek>(
          context: context,
          title: l10n.firstdayofweeksetting,
          options: FirstDayOfWeek.values
              .map((value) => NaOption(value: value, label: label(value)))
              .toList(growable: false),
          selected: firstDay,
          cancelLabel: l10n.cancel,
        );
        switch (choice) {
          case NaOptionPicked(:final value):
            await ref
                .read(settingsControllerProvider.notifier)
                .changeFirstDayOfWeek(firstDay: value);
          case NaOptionCancelled():
            return;
        }
      },
    );
  }
}

final class UnitOrderRow extends ConsumerWidget {
  const UnitOrderRow({required this.order, super.key});

  final CleanTimeUnitOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    String label(CleanTimeUnitOrder value) => switch (value) {
      CleanTimeUnitOrder.yearsMonthsDays => l10n.ymd,
      CleanTimeUnitOrder.daysMonthsYears => l10n.dmy,
    };
    return NaListRow(
      key: const Key('settings-unit-order'),
      label: l10n.cleantimeunitsort,
      value: label(order),
      onTap: () async {
        final choice = await showNaOptionDialog<CleanTimeUnitOrder>(
          context: context,
          title: l10n.cleantimeunitsort,
          options: CleanTimeUnitOrder.values
              .map((value) => NaOption(value: value, label: label(value)))
              .toList(growable: false),
          selected: order,
          cancelLabel: l10n.cancel,
        );
        switch (choice) {
          case NaOptionPicked(:final value):
            await ref
                .read(settingsControllerProvider.notifier)
                .changeCleanTimeUnitOrder(order: value);
          case NaOptionCancelled():
            return;
        }
      },
    );
  }
}

final class SearchRadiusCard extends ConsumerWidget {
  const SearchRadiusCard({required this.radius, super.key});

  final Km radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = NaTheme.of(context);
    final shown = switch (ref.watch(searchRadiusDraftProvider)) {
      Dragging(:final radius) => radius,
      NoDraft() => radius,
    };
    return NaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.settingsSearchRangeValue(shown.value),
            key: const Key('settings-search-range-caption'),
            style: theme.typography.body,
          ),
          NaSlider(
            key: const Key('settings-search-range-slider'),
            value: radius.value,
            min: Km.searchRadiusMinimum.value,
            max: Km.searchRadiusMaximum.value,
            label: l10n.searchrangesetting,
            onChanged: (value) => ref
                .read(searchRadiusDraftProvider.notifier)
                .drag(radius: Km(value)),
            onChangeEnd: (value) async {
              ref.read(searchRadiusDraftProvider.notifier).release();
              await ref
                  .read(settingsControllerProvider.notifier)
                  .changeSearchRadius(radius: Km(value));
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.kmValue(Km.searchRadiusMinimum.value),
                style: theme.typography.caption,
              ),
              Text(
                l10n.kmValue(Km.searchRadiusMaximum.value),
                style: theme.typography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
