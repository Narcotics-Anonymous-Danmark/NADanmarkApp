import 'package:flutter/widgets.dart';
import 'package:na_kernel/na_kernel.dart';

@immutable
final class KeyTagImage {
  const KeyTagImage({required this.kind, required this.language});

  final AnniversaryKind kind;
  final Language language;

  AssetImage get image => AssetImage(
    'assets/keytags/${language.code}/${kind.keyTag.file}.png',
    package: 'feature_cleantime',
  );
}
