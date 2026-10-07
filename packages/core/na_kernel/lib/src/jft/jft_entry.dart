import 'package:meta/meta.dart';
import 'package:na_kernel/src/jft/danish_month.dart';

extension type const DayOfMonth(int value) {}

extension type const JftTitle(String value) {}

extension type const JftQuote(String value) {}

extension type const JftSource(String value) {}

extension type const JftText(String value) {}

extension type const JftClosingBody(String value) {}

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

  final DayOfMonth day;
  final DanishMonth month;
  final JftTitle title;
  final JftQuote quote;
  final JftSource source;
  final JftText text;
  final JftClosing closing;

  String get dateLabel => '${day.value}. ${month.name}';

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
  String toString() => 'JftEntry($dateLabel, ${title.value})';
}

@immutable
sealed class JftClosing {
  const JftClosing();

  static const String lead = 'Bare for i dag:';

  static JftClosing parse({required String text}) {
    final trimmed = text.trimLeft();
    return trimmed.startsWith(lead)
        ? JftClosingWithLead(
            body: JftClosingBody(trimmed.substring(lead.length).trimLeft()),
          )
        : JftClosingPlain(body: JftClosingBody(trimmed));
  }

  String get fullText => switch (this) {
    JftClosingWithLead(:final body) => '$lead ${body.value}',
    JftClosingPlain(:final body) => body.value,
  };
}

final class JftClosingWithLead extends JftClosing {
  const JftClosingWithLead({required this.body});

  final JftClosingBody body;

  @override
  int get hashCode => Object.hash(JftClosingWithLead, body);

  @override
  bool operator ==(Object other) =>
      other is JftClosingWithLead && other.body == body;
}

final class JftClosingPlain extends JftClosing {
  const JftClosingPlain({required this.body});

  final JftClosingBody body;

  @override
  int get hashCode => Object.hash(JftClosingPlain, body);

  @override
  bool operator ==(Object other) =>
      other is JftClosingPlain && other.body == body;
}
