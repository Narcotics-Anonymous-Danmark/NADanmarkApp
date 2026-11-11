import 'package:feature_speaks/src/application/speak_filters.dart';
import 'package:feature_speaks/src/application/speak_listing.dart';
import 'package:feature_speaks/src/application/speak_resumes.dart';
import 'package:feature_speaks/src/application/speak_texts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

NaSelection selectionOf<T>({required Set<T> among}) =>
    among.isEmpty ? NaSelection.selected : NaSelection.unselected;

NaSelection chosen<T>({required Set<T> values, required T value}) =>
    values.contains(value) ? NaSelection.selected : NaSelection.unselected;

final class SpeakFilterPanel extends ConsumerWidget {
  const SpeakFilterPanel({required this.listing, super.key});

  final SpeakListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final texts = SpeakTexts(l10n: l10n);
    final selection = ref.watch(
      speakFiltersProvider.select((filters) => filters.selection),
    );
    final startedCount = ref.watch(
      speakResumesProvider.select((resumes) => resumes.startedCount),
    );
    final controller = ref.read(speakFiltersProvider.notifier);
    return ColoredBox(
      key: const Key('speak-filter-panel'),
      color: NaTheme.of(context).colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterHeading(label: NaLabel(l10n.language)),
          NaChipStrip(
            chips: [
              NaToggleChip(
                key: const Key('speak-language-all'),
                label: NaLabel(l10n.speakAll),
                selection: selectionOf(among: selection.languages),
                onTap: controller.clearLanguages,
              ),
              for (final language in SpeakLanguage.values)
                NaToggleChip(
                  key: Key('speak-language-${language.code}'),
                  label: texts.language(language: language),
                  selection: chosen(
                    values: selection.languages,
                    value: language,
                  ),
                  onTap: () => controller.toggleLanguage(language: language),
                ),
            ],
          ),
          if (listing.yearOptions.isNotEmpty) ...[
            FilterHeading(label: NaLabel(l10n.speakYear)),
            NaChipStrip(
              key: const Key('speak-years'),
              chips: [
                NaToggleChip(
                  key: const Key('speak-year-all'),
                  label: NaLabel(l10n.speakAll),
                  selection: selectionOf(among: selection.years),
                  onTap: controller.clearYears,
                ),
                for (final year in listing.yearOptions)
                  NaToggleChip(
                    key: Key('speak-year-${year.value}'),
                    label: NaLabel('${year.value}'),
                    selection: chosen(values: selection.years, value: year),
                    onTap: () => controller.toggleYear(year: year),
                  ),
              ],
            ),
          ],
          FilterHeading(label: NaLabel(l10n.speakSort)),
          NaChipStrip(
            chips: [
              for (final sort in SpeakSort.values)
                NaToggleChip(
                  key: Key('speak-sort-${sort.name}'),
                  label: NaLabel(switch (sort) {
                    SpeakSort.newest => l10n.speakSortNewest,
                    SpeakSort.oldest => l10n.speakSortOldest,
                    SpeakSort.name => l10n.speakSortName,
                  }),
                  selection: selection.sort == sort
                      ? NaSelection.selected
                      : NaSelection.unselected,
                  onTap: () => controller.sortBy(sort: sort),
                ),
              if (startedCount.value > 0 ||
                  selection.onlyStarted == OnlyStarted.on)
                NaToggleChip(
                  key: const Key('speak-only-started'),
                  label: NaLabel(
                    '${l10n.speakOnlyStarted} (${startedCount.value})',
                  ),
                  selection: switch (selection.onlyStarted) {
                    OnlyStarted.on => NaSelection.selected,
                    OnlyStarted.off => NaSelection.unselected,
                  },
                  onTap: controller.toggleOnlyStarted,
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (listing.inUse == FiltersInUse.yes)
                NaDialogTextButton(
                  key: const Key('speak-panel-reset'),
                  label: NaLabel(l10n.speakResetFilters),
                  availability: NaAvailability.enabled,
                  onTap: controller.reset,
                ),
              NaDialogTextButton(
                key: const Key('speak-panel-close'),
                label: NaLabel(l10n.close),
                availability: NaAvailability.enabled,
                onTap: controller.togglePanel,
              ),
              const SizedBox(width: Space.sm),
            ],
          ),
        ],
      ),
    );
  }
}

final class FilterHeading extends StatelessWidget {
  const FilterHeading({required this.label, super.key});

  final NaLabel label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, 0),
    child: Semantics(
      header: true,
      child: Text(label.value, style: NaTheme.of(context).typography.caption),
    ),
  );
}
