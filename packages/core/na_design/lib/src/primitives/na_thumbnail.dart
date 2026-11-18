import 'package:flutter/widgets.dart';
import 'package:na_design/src/tokens/na_radii.dart';

sealed class NaThumbnailImage {
  const NaThumbnailImage();
}

final class NaRemoteImage extends NaThumbnailImage {
  const NaRemoteImage({required this.uri});

  final Uri uri;
}

final class NaNoImage extends NaThumbnailImage {
  const NaNoImage();
}

final class NaThumbnail extends StatelessWidget {
  const NaThumbnail({required this.image, required this.fallback, super.key});

  static const double size = 56;

  final NaThumbnailImage image;
  final ImageProvider fallback;

  @override
  Widget build(BuildContext context) {
    final placeholder = Image(
      key: const Key('thumbnail-fallback'),
      image: fallback,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radius.card),
      child: SizedBox.square(
        dimension: size,
        child: switch (image) {
          NaRemoteImage(:final uri) => Image.network(
            uri.toString(),
            key: const Key('thumbnail-remote'),
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            loadingBuilder: (context, child, progress) => switch (progress) {
              null => child,
              ImageChunkEvent() => placeholder,
            },
            errorBuilder: (context, error, stackTrace) => placeholder,
          ),
          NaNoImage() => placeholder,
        },
      ),
    );
  }
}
