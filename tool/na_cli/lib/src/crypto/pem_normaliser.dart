import 'dart:convert';

enum PemKind {
  ecPrivateKey('EC PRIVATE KEY'),
  privateKey('PRIVATE KEY'),
  rsaPrivateKey('RSA PRIVATE KEY')
  ;

  const PemKind(this.label);

  final String label;
}

final class PemDocument {
  const PemDocument({required this.kind, required this.base64Body});

  final PemKind kind;
  final String base64Body;

  List<int> get derBytes => base64Decode(base64Body);

  String render() {
    final lines = RegExp(
      '.{1,64}',
    ).allMatches(base64Body).map((final match) => match.group(0).toString());
    return [
      '-----BEGIN ${kind.label}-----',
      ...lines,
      '-----END ${kind.label}-----',
      '',
    ].join('\n');
  }
}

final class PemNormaliser {
  const PemNormaliser();

  static final RegExp _envelope = RegExp(
    r'-----BEGIN ([A-Z ]+)-----([A-Za-z0-9+/=\s]*)-----END \1-----',
  );

  PemNormalisation normalise({required final String raw}) {
    final unescaped = raw
        .replaceAll(r'\n', '\n')
        .replaceAll('\r\n', '\n')
        .trim();
    final direct = _envelope.firstMatch(unescaped);
    if (direct != null) {
      return _fromMatch(direct);
    }
    final decoded = _tryBase64(unescaped);
    final wrapped = _envelope.firstMatch(decoded);
    if (wrapped != null) {
      return _fromMatch(wrapped);
    }
    return const PemRejected(
      reason:
          'private key must be a PEM block (plain, base64 encoded or with '
          r'\n escapes) of type EC PRIVATE KEY or PRIVATE KEY',
    );
  }

  PemNormalisation _fromMatch(final RegExpMatch match) {
    final label = match.group(1).toString();
    final body = match.group(2).toString().replaceAll(RegExp(r'\s'), '');
    final kinds = PemKind.values.where((final kind) => kind.label == label);
    if (kinds.isEmpty) {
      return PemRejected(reason: 'unsupported PEM type "$label"');
    }
    try {
      base64Decode(body);
    } on FormatException {
      return const PemRejected(reason: 'PEM body is not valid base64');
    }
    return PemAccepted(
      document: PemDocument(kind: kinds.first, base64Body: body),
    );
  }

  String _tryBase64(final String text) {
    try {
      return utf8.decode(base64Decode(text.replaceAll(RegExp(r'\s'), '')));
    } on FormatException {
      return '';
    }
  }
}

sealed class PemNormalisation {
  const PemNormalisation();
}

final class PemAccepted extends PemNormalisation {
  const PemAccepted({required this.document});

  final PemDocument document;
}

final class PemRejected extends PemNormalisation {
  const PemRejected({required this.reason});

  final String reason;
}
