import 'package:meta/meta.dart';
import 'package:na_kernel/src/jft/danish_month.dart';

@immutable
final class JftEntry {
  const JftEntry({
    required this.day,
    required this.month,
    required this.title,
    required this.quote,
    required this.source,
    required this.text,
    required this.closing,
  });

  final int day;
  final DanishMonth month;
  final String title;
  final String quote;
  final String source;
  final String text;
  final JftClosing closing;

  String get dateLabel => '$day. ${month.name}';

  @override
  int get hashCode => Object.hash(day, month, title, quote, source, text);

  @override
  bool operator ==(Object other) =>
      other is JftEntry &&
      other.day == day &&
      other.month == month &&
      other.title == title &&
      other.quote == quote &&
      other.source == source &&
      other.text == text &&
      other.closing == closing;

  @override
  String toString() => 'JftEntry($dateLabel, $title)';
}

@immutable
sealed class JftClosing {
  const JftClosing();

  static const String lead = 'Bare for i dag:';

  static JftClosing parse({required String text}) {
    final trimmed = text.trimLeft();
    return trimmed.startsWith(lead)
        ? JftClosingWithLead(body: trimmed.substring(lead.length).trimLeft())
        : JftClosingPlain(body: trimmed);
  }

  String get fullText => switch (this) {
    JftClosingWithLead(:final body) => '$lead $body',
    JftClosingPlain(:final body) => body,
  };
}

final class JftClosingWithLead extends JftClosing {
  const JftClosingWithLead({required this.body});

  final String body;

  @override
  int get hashCode => Object.hash(JftClosingWithLead, body);

  @override
  bool operator ==(Object other) =>
      other is JftClosingWithLead && other.body == body;
}

final class JftClosingPlain extends JftClosing {
  const JftClosingPlain({required this.body});

  final String body;

  @override
  int get hashCode => Object.hash(JftClosingPlain, body);

  @override
  bool operator ==(Object other) =>
      other is JftClosingPlain && other.body == body;
}
