import 'dart:async';

import 'package:feature_speaks/src/application/speak_filters.dart';
import 'package:feature_speaks/src/application/speak_listing.dart';
import 'package:feature_speaks/src/application/speak_resumes.dart';
import 'package:feature_speaks/src/application/speak_texts.dart';
import 'package:feature_speaks/src/application/speaks_catalog_loader.dart';
import 'package:feature_speaks/src/widgets/speak_filter_panel.dart';
import 'package:feature_speaks/src/widgets/speak_row.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

Language languageOf(BuildContext context) =>
    Language.fromCode(code: Localizations.localeOf(context).languageCode);

final class SpeaksBody extends StatelessWidget {
  const SpeaksBody({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SpeaksToolbar(),
      ConventionChips(),
      Expanded(child: SpeaksContent()),
    ],
  );
}

final class SpeaksToolbar extends ConsumerWidget {
  const SpeaksToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final typed = ref.watch(speakFiltersProvider.select((f) => f.typed));
    final count = ref.watch(
      speakListingProvider(
        languageOf(context),
      ).select((listing) => listing.activeFilters),
    );
    final controller = ref.read(speakFiltersProvider.notifier);
    return ColoredBox(
      color: NaTheme.of(context).colors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.xs, 0),
        child: Row(
          children: [
            Expanded(
              child: NaSearchField(
                key: const Key('speak-search'),
                text: NaInputText(typed.text),
                placeholder: NaLabel(l10n.speakSearchPlaceholder),
                clearLabel: NaLabel(l10n.speakClearSearch),
                onChanged: (text) =>
                    controller.type(text: SearchInput(text.value)),
              ),
            ),
            NaToolbarButton(
              key: const Key('speak-filters'),
              icon: NaIcons.funnel,
              label: NaLabel(
                count.value > 0 ? '${count.value}' : l10n.speakFilters,
              ),
              semanticLabel: NaLabel(
                count.value > 0
                    ? '${l10n.speakFilters} (${count.value})'
                    : l10n.speakFilters,
              ),
              onPressed: controller.togglePanel,
            ),
          ],
        ),
      ),
    );
  }
}

final class ConventionChips extends ConsumerWidget {
  const ConventionChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conventions = ref.watch(
      speaksCatalogProvider.select(
        (state) => state.catalogOrEmpty.conventions,
      ),
    );
    final selected = ref.watch(
      speakFiltersProvider.select((filters) => filters.selection.conventions),
    );
    final controller = ref.read(speakFiltersProvider.notifier);
    return conventions.length > 1
        ? ColoredBox(
            color: NaTheme.of(context).colors.surface,
            child: NaChipStrip(
              key: const Key('speak-conventions'),
              chips: [
                NaToggleChip(
                  key: const Key('speak-convention-all'),
                  label: NaLabel(AppLocalizations.of(context).speakAll),
                  selection: selectionOf(among: selected),
                  onTap: controller.clearConventions,
                ),
                for (final convention in conventions)
                  NaToggleChip(
                    key: Key('speak-convention-${convention.key.value}'),
                    label: NaLabel(convention.label.text),
                    selection: chosen(values: selected, value: convention.key),
                    onTap: () =>
                        controller.toggleConvention(convention: convention.key),
                  ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }
}

final class SpeaksContent extends ConsumerWidget {
  const SpeaksContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final loader = ref.read(speaksCatalogProvider.notifier);
    return switch (ref.watch(speaksCatalogProvider)) {
      CatalogLoading() => ListView(
        key: const Key('speaks-loading'),
        children: [for (final row in _placeholders) NaSkeletonRow(key: row)],
      ),
      CatalogFailed() => SingleChildScrollView(
        child: NaMessageBlock(
          key: const Key('speaks-failed'),
          title: NaLabel(l10n.speakLoadError),
          body: NaLabel(l10n.speakLoadErrorBody),
          action: NaMessageButton(
            label: NaLabel(l10n.speakRetry),
            onPressed: () => unawaited(loader.reload()),
          ),
        ),
      ),
      CatalogReady(:final refresh) => NaPullToRefresh(
        activity: switch (refresh) {
          RefreshState.refreshing => NaActivity.busy,
          RefreshState.idle => NaActivity.idle,
        },
        busyLabel: NaLabel(l10n.playerLoading),
        onRefresh: () => unawaited(loader.reload()),
        child: SpeaksResults(language: languageOf(context)),
      ),
    };
  }

  static final List<Key> _placeholders = List.unmodifiable(
    List.generate(8, (index) => Key('speak-skeleton-$index')),
  );
}

final class SpeaksResults extends ConsumerWidget {
  const SpeaksResults({required this.language, super.key});

  static const double loadAhead = 600;

  final Language language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final texts = SpeakTexts(l10n: l10n);
    final listing = ref.watch(speakListingProvider(language));
    final filters = ref.watch(speakFiltersProvider);
    final continueList = ref.watch(
      speakResumesProvider.select((resumes) => resumes.continueList),
    );
    final controller = ref.read(speakFiltersProvider.notifier);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (listing.more == MoreSpeaks.available &&
            notification.metrics.extentAfter < loadAhead) {
          unawaited(
            Future.microtask(() => controller.showMore(after: filters.shown)),
          );
        }
        return false;
      },
      child: CustomScrollView(
        key: ValueKey(filters.selection),
        physics: NaPullToRefresh.physics,
        slivers: [
          if (filters.panel == FilterPanel.open)
            SliverToBoxAdapter(child: SpeakFilterPanel(listing: listing)),
          if (continueList.isNotEmpty)
            SliverMainAxisGroup(
              key: const Key('speak-continue'),
              slivers: [
                PinnedHeaderSliver(
                  child: SpeakSectionHeader(
                    label: NaLabel(l10n.playerContinueListening),
                  ),
                ),
                SliverList.list(
                  children: [
                    for (final speak in continueList)
                      ContinueRow(
                        key: Key('speak-continue-${speak.id.value}'),
                        speak: speak,
                      ),
                  ],
                ),
              ],
            ),
          SliverToBoxAdapter(
            child: listing.matchCount.value > 0
                ? CountLine(count: listing.matchCount)
                : NaMessageBlock(
                    key: const Key('speaks-none'),
                    title: NaLabel(l10n.speakNoneFound),
                    body: NaLabel(l10n.speakNoneFoundBody),
                    action: switch (listing.inUse) {
                      FiltersInUse.yes => NaMessageButton(
                        label: NaLabel(l10n.speakResetFilters),
                        onPressed: controller.reset,
                      ),
                      FiltersInUse.no => const NoMessageAction(),
                    },
                  ),
          ),
          for (final section in listing.sections)
            SliverMainAxisGroup(
              key: Key('speak-section-${section.convention.key.value}'),
              slivers: [
                PinnedHeaderSliver(
                  child: SpeakSectionHeader(
                    label: texts.section(convention: section.convention),
                  ),
                ),
                SliverList.builder(
                  itemCount: section.speaks.length,
                  itemBuilder: (context, index) => SpeakRow(
                    key: Key('speak-row-${section.speaks[index].id.value}'),
                    speak: section.speaks[index],
                    line: SpeakLine.meta,
                  ),
                ),
              ],
            ),
          if (listing.more == MoreSpeaks.available)
            const SliverToBoxAdapter(
              child: NaSkeletonRow(key: Key('speaks-more')),
            ),
        ],
      ),
    );
  }
}

final class CountLine extends StatelessWidget {
  const CountLine({required this.count, super.key});

  final SpeakCount count;

  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('speak-count'),
    padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.sm),
    child: Text(
      AppLocalizations.of(context).speakCount('${count.value}'),
      style: NaTheme.of(context).typography.caption,
    ),
  );
}
