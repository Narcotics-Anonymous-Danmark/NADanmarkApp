import 'package:na_cli/src/plist/plist_token.dart';
import 'package:na_cli/src/plist/plist_value.dart';

final class PlistReader {
  const PlistReader();

  static const Set<String> _scalarTags = {
    'string',
    'date',
    'data',
    'integer',
    'real',
  };

  PlistValue read({required final String xml}) {
    final tokens = PlistToken.tokenise(xml: xml);
    final plistStart = tokens.indexWhere(
      (final t) => t.kind == PlistTokenKind.open && t.name == 'plist',
    );
    if (plistStart < 0 || plistStart + 1 >= tokens.length) {
      return const PlistMissing();
    }
    return _parseValue(tokens: tokens, at: plistStart + 1).value;
  }

  ParsedPlistValue _parseValue({
    required final List<PlistToken> tokens,
    required final int at,
  }) {
    final token = tokens[at];
    if (token.name == 'dict') {
      return _parseDict(tokens: tokens, start: at + 1);
    }
    if (token.name == 'array') {
      return _parseArray(tokens: tokens, start: at + 1);
    }
    if (token.name == 'true') {
      return ParsedPlistValue(
        value: const PlistBool(value: PlistTruth.yes),
        next: at + 1,
      );
    }
    if (token.name == 'false') {
      return ParsedPlistValue(
        value: const PlistBool(value: PlistTruth.no),
        next: at + 1,
      );
    }
    if (_scalarTags.contains(token.name)) {
      return _parseScalar(tokens: tokens, at: at);
    }
    return ParsedPlistValue(value: const PlistMissing(), next: at + 1);
  }

  ParsedPlistValue _parseScalar({
    required final List<PlistToken> tokens,
    required final int at,
  }) {
    final open = tokens[at];
    if (open.kind == PlistTokenKind.selfClosing) {
      return ParsedPlistValue(
        value: _scalar(name: open.name, text: ''),
        next: at + 1,
      );
    }
    final next = tokens[at + 1];
    if (next.kind == PlistTokenKind.text) {
      return ParsedPlistValue(
        value: _scalar(name: open.name, text: next.text),
        next: at + 3,
      );
    }
    return ParsedPlistValue(
      value: _scalar(name: open.name, text: ''),
      next: at + 2,
    );
  }

  PlistValue _scalar({
    required final String name,
    required final String text,
  }) {
    if (name == 'string') {
      return PlistString(value: PlistToken.unescape(text: text));
    }
    if (name == 'date') {
      return PlistDate(
        value: DateTime.tryParse(text.trim()) ?? DateTime.utc(1970),
      );
    }
    if (name == 'data') {
      return PlistData(base64: text.replaceAll(RegExp(r'\s'), ''));
    }
    return PlistInteger(value: int.tryParse(text.trim()) ?? 0);
  }

  ParsedPlistValue _parseDict({
    required final List<PlistToken> tokens,
    required final int start,
  }) {
    var at = start;
    final entries = <String, PlistValue>{};
    while (at < tokens.length && tokens[at].kind != PlistTokenKind.close) {
      final keyText = tokens[at + 1];
      final key = switch (keyText.kind) {
        PlistTokenKind.text => PlistToken.unescape(text: keyText.text),
        PlistTokenKind.open ||
        PlistTokenKind.close ||
        PlistTokenKind.selfClosing ||
        PlistTokenKind.blank => '',
      };
      final parsed = _parseValue(
        tokens: tokens,
        at: key.isEmpty ? at + 2 : at + 3,
      );
      entries[key] = parsed.value;
      at = parsed.next;
    }
    return ParsedPlistValue(
      value: PlistDict(entries: Map.unmodifiable(entries)),
      next: at + 1,
    );
  }

  ParsedPlistValue _parseArray({
    required final List<PlistToken> tokens,
    required final int start,
  }) {
    var at = start;
    final items = <PlistValue>[];
    while (at < tokens.length && tokens[at].kind != PlistTokenKind.close) {
      final parsed = _parseValue(tokens: tokens, at: at);
      items.add(parsed.value);
      at = parsed.next;
    }
    return ParsedPlistValue(
      value: PlistArray(items: List.unmodifiable(items)),
      next: at + 1,
    );
  }
}

final class ParsedPlistValue {
  const ParsedPlistValue({required this.value, required this.next});

  final PlistValue value;
  final int next;
}
