import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:na_kernel/na_kernel.dart';

typedef DirectoryLocator = Future<Directory> Function();

final class ArtworkFiles {
  ArtworkFiles({required this.bundle, required this.directory});

  final AssetBundle bundle;
  final DirectoryLocator directory;
  final Map<AssetKey, Uri> _copied = {};

  Future<Uri?> uriFor({required PlaylistCover cover}) async => switch (cover) {
    NoCover() => null,
    BundledCover(:final asset) => _copied[asset] ?? await _copy(asset: asset),
  };

  Future<Uri?> _copy({required AssetKey asset}) async {
    final bytes = await bundle
        .load(asset.path)
        .then<ByteData?>((data) => data)
        .catchError(
          (Object error) => null,
          test: (error) => error is FlutterError,
        );
    if (bytes == null) {
      return null;
    }
    try {
      final folder = Directory('${(await directory()).path}/artwork');
      await folder.create(recursive: true);
      final file = File('${folder.path}/${asset.path.split('/').last}');
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      return _copied[asset] = file.uri;
    } on FileSystemException {
      return null;
    }
  }
}
