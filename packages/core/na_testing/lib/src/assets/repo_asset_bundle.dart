import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final class RepoAssetBundle extends CachingAssetBundle {
  RepoAssetBundle({required this.repoRoot});

  factory RepoAssetBundle.locate() =>
      RepoAssetBundle(repoRoot: _repoRootFrom(Directory.current));

  final Directory repoRoot;

  @override
  Future<ByteData> load(String key) async {
    final file = _fileFor(key: key);
    if (!file.existsSync()) {
      throw FlutterError(
        'Unable to load asset: "$key" (looked at ${file.path})',
      );
    }
    final bytes = await file.readAsBytes();
    return ByteData.sublistView(bytes);
  }

  File _fileFor({required String key}) {
    final segments = key.split('/');
    if (segments.length < 3 || segments.first != 'packages') {
      return File('${repoRoot.path}/$key');
    }
    final package = segments[1];
    final rest = segments.sublist(2).join('/');
    final candidates = Directory('${repoRoot.path}/packages')
        .listSync()
        .whereType<Directory>()
        .map((layer) => File('${layer.path}/$package/$rest'));
    return candidates.firstWhere(
      (file) => file.existsSync(),
      orElse: () => File('${repoRoot.path}/packages/$package/$rest'),
    );
  }

  static Directory _repoRootFrom(Directory start) {
    var current = start.absolute;
    while (true) {
      if (Directory('${current.path}/packages').existsSync() &&
          File('${current.path}/pubspec.yaml').existsSync()) {
        return current;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        return start.absolute;
      }
      current = parent;
    }
  }
}
