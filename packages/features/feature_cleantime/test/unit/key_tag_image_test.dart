@Tags(['unit'])
library;

import 'package:feature_cleantime/feature_cleantime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_testing/na_testing.dart';

void main() {
  test('every key tag resolves to a bundled file in both languages', () async {
    final bundle = RepoAssetBundle.locate();
    final tags = AnniversaryKind.values.expand(
      (kind) => Language.values.map(
        (language) => KeyTagImage(kind: kind, language: language),
      ),
    );
    final sizes = await Future.wait(
      tags.map(
        (tag) =>
            bundle.load(tag.image.keyName).then((data) => data.lengthInBytes),
      ),
    );
    expect(sizes, hasLength(18));
    expect(sizes.every((size) => size > 0), isTrue);
  });

  test('the asset path follows the language and the kind', () {
    expect(
      const KeyTagImage(
        kind: AnniversaryKind.years,
        language: Language.english,
      ).image.keyName,
      'packages/feature_cleantime/assets/keytags/en/x-years.png',
    );
  });
}
