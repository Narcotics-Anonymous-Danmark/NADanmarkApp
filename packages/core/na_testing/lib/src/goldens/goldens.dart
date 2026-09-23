import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_testing/src/assets/repo_asset_bundle.dart';

Future<void> loadNaFonts() async {
  final plex = File(
    '${RepoAssetBundle.locate().repoRoot.path}'
    '/packages/core/na_design/assets/fonts/IBMPlexSans-Medium.ttf',
  );
  final phosphor = File.fromUri(
    _packageRoot(name: 'phosphor_flutter').resolve('lib/fonts/Phosphor.ttf'),
  );
  await _register(family: 'packages/na_design/Plex', file: plex);
  await _register(
    family: 'packages/phosphor_flutter/PhosphorRegular',
    file: phosphor,
  );
}

Uri _packageRoot({required String name}) {
  final configFile = File(
    '${RepoAssetBundle.locate().repoRoot.path}/.dart_tool/package_config.json',
  );
  final entry = RegExp(
    '"name":\\s*"${RegExp.escape(name)}",\\s*"rootUri":\\s*"([^"]+)"',
  ).firstMatch(configFile.readAsStringSync());
  final root = switch (entry?.group(1)) {
    final String found => found,
    null => throw StateError('$name is not in ${configFile.path}'),
  };
  final base = configFile.uri.resolve(root);
  return base.path.endsWith('/') ? base : Uri.parse('$base/');
}

Future<void> _register({required String family, required File file}) async {
  final bytes = await file.readAsBytes();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

Future<void> expectGolden({
  required Finder finder,
  required String name,
}) async {
  if (!Platform.isLinux) {
    markTestSkipped('goldens are recorded and compared on Linux only');
    return;
  }
  await expectLater(finder, matchesGoldenFile('goldens/$name.png'));
}

Future<void> expectAccessible(WidgetTester tester) => _expectGuidelines(
  tester: tester,
  guidelines: [
    androidTapTargetGuideline,
    iOSTapTargetGuideline,
    labeledTapTargetGuideline,
    textContrastGuideline,
  ],
);

Future<void> expectTapTargetsAccessible(WidgetTester tester) =>
    _expectGuidelines(
      tester: tester,
      guidelines: [
        androidTapTargetGuideline,
        iOSTapTargetGuideline,
        labeledTapTargetGuideline,
      ],
    );

Future<void> _expectGuidelines({
  required WidgetTester tester,
  required List<AccessibilityGuideline> guidelines,
}) async {
  final handle = tester.ensureSemantics();
  try {
    for (final guideline in guidelines) {
      await expectLater(tester, meetsGuideline(guideline));
    }
  } finally {
    handle.dispose();
  }
}

Widget goldenFrame({required Widget child, double width = 360}) => Center(
  child: RepaintBoundary(
    key: const Key('golden'),
    child: SizedBox(width: width, child: child),
  ),
);

Finder get goldenTarget => find.byKey(const Key('golden'));
