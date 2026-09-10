@Tags(['unit'])
library;

import 'dart:convert';

import 'package:na_cli/src/crypto/pem_normaliser.dart';
import 'package:test/test.dart';

void main() {
  const normaliser = PemNormaliser();
  final body = base64Encode(List.generate(100, (final i) => i));
  final plain =
      '-----BEGIN EC PRIVATE KEY-----\n$body\n-----END EC PRIVATE KEY-----\n';

  PemDocument accepted(final String raw) =>
      (normaliser.normalise(raw: raw) as PemAccepted).document;

  test('accepts a plain PEM and renders 64 column lines', () {
    final rendered = accepted(plain).render();
    final lines = rendered.trim().split('\n');
    expect(lines.first, '-----BEGIN EC PRIVATE KEY-----');
    expect(lines.last, '-----END EC PRIVATE KEY-----');
    expect(
      lines.sublist(1, lines.length - 1).every((final l) => l.length <= 64),
      isTrue,
    );
    expect(accepted(plain).kind, PemKind.ecPrivateKey);
  });

  test('accepts newline-escaped, CRLF and base64-wrapped PEM', () {
    final escaped = plain.replaceAll('\n', r'\n');
    final crlf = plain.replaceAll('\n', '\r\n');
    final wrapped = base64Encode(utf8.encode(plain));
    for (final raw in [escaped, crlf, wrapped]) {
      expect(accepted(raw).base64Body, body);
    }
  });

  test('accepts PKCS#8 PRIVATE KEY', () {
    final pkcs8 = plain.replaceAll('EC PRIVATE KEY', 'PRIVATE KEY');
    expect(accepted(pkcs8).kind, PemKind.privateKey);
  });

  test('rejects other types and garbage', () {
    expect(
      normaliser.normalise(
        raw: plain.replaceAll('EC PRIVATE KEY', 'CERTIFICATE'),
      ),
      isA<PemRejected>(),
    );
    expect(normaliser.normalise(raw: 'hello'), isA<PemRejected>());
  });
}
