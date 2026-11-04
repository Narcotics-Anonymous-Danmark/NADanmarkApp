import 'package:feature_readings/src/application/readings_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';

final class ReadingsBody extends ConsumerWidget {
  const ReadingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(readingsProvider)) {
        Loading() => const SizedBox.shrink(),
        Failed() => Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Align(
            alignment: Alignment.topCenter,
            child: NaErrorState(
              message: AppLocalizations.of(context).readingsLoadFailed,
            ),
          ),
        ),
        Loaded(:final value) => ReadingsPage(collection: value),
      };
}

final class ReadingsPage extends ConsumerWidget {
  const ReadingsPage({required this.collection, super.key});

  final ReadingCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(selectedReadingProvider);
    final reading = collection.at(index: index);
    return ColoredBox(
      key: const Key('readings-background'),
      color: Color(reading.colour.argb),
      child: ListView(
        children: [
          ReadingSelector(collection: collection, selected: index),
          Padding(
            padding: const EdgeInsets.all(Space.sm),
            child: ReadingCard(reading: reading),
          ),
        ],
      ),
    );
  }
}

final class ReadingSelector extends ConsumerWidget {
  const ReadingSelector({
    required this.collection,
    required this.selected,
    super.key,
  });

  final ReadingCollection collection;
  final ReadingIndex selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return NaSelectRow(
      key: const Key('readings-select'),
      value: collection.at(index: selected).title.text,
      onTap: () async {
        final choice = await showNaOptionDialog<ReadingIndex>(
          context: context,
          title: l10n.grc,
          options: List.unmodifiable(
            collection.readings.indexed.map(
              (entry) => NaOption(
                value: ReadingIndex(entry.$1),
                label: entry.$2.title.text,
              ),
            ),
          ),
          selected: selected,
          cancelLabel: l10n.cancel,
        );
        switch (choice) {
          case NaOptionPicked(:final value):
            ref.read(selectedReadingProvider.notifier).selected = value;
          case NaOptionCancelled():
            return;
        }
      },
    );
  }
}

final class ReadingCard extends StatelessWidget {
  const ReadingCard({required this.reading, super.key});

  static const Color ink = Color(0xFF000000);

  final Reading reading;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const Key('reading-card'),
    decoration: BoxDecoration(
      color: Color(reading.colour.argb),
      border: Border.all(width: 2),
    ),
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(width: 2)),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  reading.heading.text,
                  key: const Key('reading-heading'),
                  textAlign: TextAlign.center,
                  style: NaTheme.of(context).typography.display.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              for (final block in reading.blocks)
                ReadingBlockView(block: block),
            ],
          ),
        ),
      ),
    ),
  );
}

final class ReadingBlockView extends StatelessWidget {
  const ReadingBlockView({required this.block, super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.md),
    child: switch (block) {
      ReadingParagraph(:final line) => ReadingLineText(
        line: line,
        indent: ReadingIndent.firstLine,
      ),
      HangingParagraph(:final line) => Padding(
        padding: const EdgeInsets.only(left: 20),
        child: ReadingLineText(line: line, indent: ReadingIndent.none),
      ),
      NumberedList(:final items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (position, item) in items.indexed)
            NumberedItem(number: ItemNumber(position + 1), line: item),
        ],
      ),
    },
  );

  final ReadingBlock block;
}

extension type const ItemNumber(int value) {}

final class NumberedItem extends StatelessWidget {
  const NumberedItem({required this.number, required this.line, super.key});

  final ItemNumber number;
  final ReadingLine line;

  @override
  Widget build(BuildContext context) => Padding(
    key: Key('reading-item-${number.value}'),
    padding: const EdgeInsets.only(bottom: Space.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Text(
            '${number.value}.',
            textAlign: TextAlign.right,
            style: ReadingLineText.styleOf(context: context),
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: ReadingLineText(line: line, indent: ReadingIndent.none),
        ),
      ],
    ),
  );
}

enum ReadingIndent { firstLine, none }

final class ReadingLineText extends StatelessWidget {
  const ReadingLineText({required this.line, required this.indent, super.key});

  static TextStyle styleOf({required BuildContext context}) =>
      NaTheme.of(context).typography.body.copyWith(
        color: ReadingCard.ink,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  final ReadingLine line;
  final ReadingIndent indent;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      style: styleOf(context: context),
      children: [
        ...switch (indent) {
          ReadingIndent.firstLine => const [
            WidgetSpan(child: SizedBox(width: 20)),
          ],
          ReadingIndent.none => const <InlineSpan>[],
        },
        for (final span in line.spans)
          TextSpan(
            text: span.text.text,
            style: switch (span.emphasis) {
              Emphasis.emphasised => const TextStyle(
                fontStyle: FontStyle.italic,
              ),
              Emphasis.plain => null,
            },
          ),
      ],
    ),
  );
}
