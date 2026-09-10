import 'package:flutter/widgets.dart';
import 'package:na_design/na_design.dart';
import 'package:na_kernel/na_kernel.dart';

enum JftScale { full, preview }

final class JftEntryView extends StatelessWidget {
  const JftEntryView({required this.entry, required this.scale, super.key});

  final JftEntry entry;
  final JftScale scale;

  @override
  Widget build(BuildContext context) {
    final typography = NaTheme.of(context).typography;
    final ink = NaTheme.of(context).colors.ink;
    final (date, title, quote, source, body) = switch (scale) {
      JftScale.full => (
        typography.heading.copyWith(color: ink),
        typography.display,
        typography.body.copyWith(fontStyle: FontStyle.italic),
        typography.body.copyWith(fontWeight: FontWeight.w700),
        typography.body,
      ),
      JftScale.preview => (
        typography.caption.copyWith(color: ink),
        typography.label.copyWith(color: ink),
        typography.caption.copyWith(fontStyle: FontStyle.italic),
        typography.footnote.copyWith(fontWeight: FontWeight.w700),
        typography.footnote,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          entry.dateLabel,
          key: const Key('jft-date'),
          textAlign: TextAlign.right,
          style: date.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Space.sm),
        Text(
          entry.title,
          key: const Key('jft-title'),
          textAlign: TextAlign.center,
          style: title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Space.sm),
        Text(entry.quote, textAlign: TextAlign.center, style: quote),
        const SizedBox(height: Space.xs),
        Text(entry.source, textAlign: TextAlign.right, style: source),
        const SizedBox(height: Space.lg),
        Text(entry.text, style: body),
        if (scale == JftScale.full) ...[
          const SizedBox(height: Space.lg),
          JftClosingText(closing: entry.closing, style: body),
        ],
      ],
    );
  }
}

final class JftClosingText extends StatelessWidget {
  const JftClosingText({required this.closing, required this.style, super.key});

  final JftClosing closing;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => switch (closing) {
    JftClosingWithLead(:final body) => Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: JftClosing.lead,
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' $body'),
        ],
      ),
      key: const Key('jft-closing'),
      style: style,
    ),
    JftClosingPlain(:final body) => Text(
      body,
      key: const Key('jft-closing'),
      style: style,
    ),
  };
}
