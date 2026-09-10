@Tags(['unit'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Directory packageRoot() {
  final cwd = Directory.current;
  final candidates = [
    cwd,
    Directory('${cwd.path}/packages/core/na_l10n'),
  ];
  return candidates.firstWhere(
    (dir) => File('${dir.path}/lib/l10n/app_da.arb').existsSync(),
    orElse: () => throw StateError(
      'na_l10n not found from ${cwd.path}; run from the '
      'repo root or from packages/core/na_l10n',
    ),
  );
}

Set<String> keysOf({required String file}) {
  final path = '${packageRoot().path}/lib/l10n/$file';
  final json = jsonDecode(File(path).readAsStringSync());
  return switch (json) {
    final Map<String, Object?> map =>
      map.keys.where((key) => !key.startsWith('@')).toSet(),
    _ => throw StateError('$file is not a JSON object'),
  };
}

void main() {
  group('ARB files', () {
    test('Danish and English define the same keys', () {
      final danish = keysOf(file: 'app_da.arb');
      final english = keysOf(file: 'app_en.arb');
      expect(danish.difference(english), isEmpty);
      expect(english.difference(danish), isEmpty);
    });
  });
}
