import 'package:meta/meta.dart';

extension type const ReadingTitle(String text) {}

extension type const ReadingHeading(String text) {}

extension type const ReadingColour(int argb) {}

extension type const ReadingText(String text) {}

enum Emphasis { plain, emphasised }

@immutable
final class ReadingSpan {
  const ReadingSpan({required this.text, required this.emphasis});

  final ReadingText text;
  final Emphasis emphasis;

  @override
  int get hashCode => Object.hash(text, emphasis);

  @override
  bool operator ==(Object other) =>
      other is ReadingSpan && other.text == text && other.emphasis == emphasis;
}

@immutable
final class ReadingLine {
  const ReadingLine({required this.spans});

  final List<ReadingSpan> spans;

  String get plainText => spans.map((span) => span.text.text).join();
}

@immutable
sealed class ReadingBlock {
  const ReadingBlock();
}

final class ReadingParagraph extends ReadingBlock {
  const ReadingParagraph({required this.line});

  final ReadingLine line;
}

final class HangingParagraph extends ReadingBlock {
  const HangingParagraph({required this.line});

  final ReadingLine line;
}

final class NumberedList extends ReadingBlock {
  const NumberedList({required this.items});

  final List<ReadingLine> items;
}

@immutable
final class Reading {
  const Reading({
    required this.title,
    required this.heading,
    required this.colour,
    required this.blocks,
  });

  final ReadingTitle title;
  final ReadingHeading heading;
  final ReadingColour colour;
  final List<ReadingBlock> blocks;

  @override
  String toString() => 'Reading(${title.text})';
}

extension type const ReadingIndex(int position) {}

@immutable
final class ReadingCollection {
  const ReadingCollection({required this.readings});

  final List<Reading> readings;

  Reading at({required ReadingIndex index}) =>
      readings[index.position.clamp(0, readings.length - 1)];
}
