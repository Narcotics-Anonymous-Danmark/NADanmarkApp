import 'package:feature_cleantime/src/application/anniversary_schedule.dart';
import 'package:feature_cleantime/src/application/cleantime_controller.dart';
import 'package:feature_cleantime/src/application/cleantime_texts.dart';
import 'package:feature_cleantime/src/widgets/cleantime_body.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class CleantimeHomeCards extends ConsumerWidget {
  const CleantimeHomeCards({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(anniversaryRefreshOnShowProvider);
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(cleantimeHomeProvider)) {
      Loaded(value: HomeProfiles(:final entries, :final today)) => NaCarousel(
        key: const Key('home-cleantime-carousel'),
        backdrop: NaBackdrop.primary,
        pages: List.unmodifiable(
          entries.indexed.map(
            (entry) => HomeCleantimeCard(
              key: Key('home-cleantime-card-${entry.$1}'),
              profile: entry.$2,
              today: today,
              onTap: onTap,
            ),
          ),
        ),
        pageLabels: List.unmodifiable(
          entries.indexed.map(
            (entry) => NaLabel(
              l10n.cleantimeCardPosition(entry.$1 + 1, entries.length),
            ),
          ),
        ),
      ),
      Loaded(value: NoHomeProfiles()) ||
      Loading() ||
      Failed() => const SizedBox.shrink(),
    };
  }
}

final class HomeCleantimeCard extends StatelessWidget {
  const HomeCleantimeCard({
    required this.profile,
    required this.today,
    required this.onTap,
    super.key,
  });

  final CleantimeProfile profile;
  final LocalDate today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = NaTheme.of(context);
    final breakdown = CleantimeTexts(l10n: l10n).homeBreakdown(
      breakdown: CleanTime.between(
        cleanDate: profile.cleanDate,
        today: today,
      ).yearsMonthsDays,
    );
    final date = LocalDateFormat(language: languageOf(context)).format(
      date: profile.cleanDate,
      pattern: DatePattern.dayMonthYear,
    );
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: NaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              NaCardTitle(text: l10n.cleantime),
              Text(profile.name.text, style: theme.typography.heading),
              const SizedBox(height: Space.xs),
              HomeCardLine(icon: NaIcons.clock, text: NaLabel(breakdown.text)),
              HomeCardLine(icon: NaIcons.calendar, text: NaLabel(date.text)),
            ],
          ),
        ),
      ),
    );
  }
}

final class HomeCardLine extends StatelessWidget {
  const HomeCardLine({required this.icon, required this.text, super.key});

  final IconData icon;
  final NaLabel text;

  @override
  Widget build(BuildContext context) {
    final theme = NaTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colors.primary),
          const SizedBox(width: Space.sm),
          Expanded(child: Text(text.value, style: theme.typography.body)),
        ],
      ),
    );
  }
}
