enum PlistTokenKind { open, close, selfClosing, text, blank }

final class PlistToken {
  const PlistToken({
    required this.kind,
    required this.name,
    required this.text,
  });

  factory PlistToken._of(final RegExpMatch match) {
    final text = match.group(5) ?? '';
    if (text.isNotEmpty) {
      return PlistToken(
        kind: text.trim().isEmpty ? PlistTokenKind.blank : PlistTokenKind.text,
        name: '',
        text: text,
      );
    }
    final name = match.group(2).toString();
    if (match.group(1) == '/') {
      return PlistToken(kind: PlistTokenKind.close, name: name, text: '');
    }
    if (match.group(4) == '/') {
      return PlistToken(kind: PlistTokenKind.selfClosing, name: name, text: '');
    }
    return PlistToken(kind: PlistTokenKind.open, name: name, text: '');
  }

  final PlistTokenKind kind;
  final String name;
  final String text;

  static final RegExp _pattern = RegExp(
    '<(/?)([a-zA-Z]+)([^>]*?)(/?)>|([^<]+)',
    dotAll: true,
  );

  static List<PlistToken> tokenise({required final String xml}) =>
      List.unmodifiable(
        _pattern
            .allMatches(xml)
            .map(PlistToken._of)
            .where((final token) => token.kind != PlistTokenKind.blank),
      );

  static String unescape({required final String text}) => text
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}
