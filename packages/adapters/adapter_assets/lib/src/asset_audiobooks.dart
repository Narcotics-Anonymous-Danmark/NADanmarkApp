import 'package:adapter_assets/src/assets_wire.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class AssetAudiobooks implements AudiobooksPort {
  const AssetAudiobooks({required this.bundle});

  static String assetKey({required AudiobookId book}) =>
      'packages/adapter_assets/assets/books/${book.playlistId.value}.json';

  final AssetBundle bundle;

  @override
  Future<Outcome<Audiobook, Failure>> load({required AudiobookId book}) =>
      bundle
          .loadString(assetKey(book: book))
          .then<Outcome<Audiobook, Failure>>(
            (text) => decode(book: book, text: text),
          )
          .catchError(
            (Object error) => Err<Audiobook, Failure>(
              error: UnavailableFailure(
                what: '${assetKey(book: book)}: $error',
              ),
            ),
            test: (error) => error is FlutterError,
          );

  static const WireJson _wire = WireJson();

  static Outcome<Audiobook, Failure> decode({
    required AudiobookId book,
    required String text,
  }) => switch (_wire
      .parse(text: text, context: book.playlistId.value)
      .flatMap(
        transform: (json) => _wire.object(
          json: json,
          fromJson: AudiobookDto.fromJson,
          context: book.playlistId.value,
        ),
      )
      .flatMap(
        transform: (dto) => _audiobook(book: book, dto: dto),
      )) {
    Ok(:final value) => Ok(value: value),
    Err(:final error) => Err(error: error),
  };

  static Outcome<Audiobook, DecodeFailure> _audiobook({
    required AudiobookId book,
    required AudiobookDto dto,
  }) {
    final chapters = (dto.chapters ?? const <ChapterDto>[])
        .map(_chapter)
        .toList();
    final title = dto.bookTitle?.trim() ?? '';
    if (title.isEmpty || chapters.isEmpty || chapters.any((c) => c == null)) {
      return Err(
        error: DecodeFailure(
          detail: '${book.playlistId.value}: title or chapters',
        ),
      );
    }
    return Ok(
      value: Audiobook(
        id: book,
        title: PlaylistTitle(title),
        chapters: List.unmodifiable(chapters.whereType<Chapter>()),
      ),
    );
  }

  static Chapter? _chapter(ChapterDto dto) {
    final title = dto.title?.trim() ?? '';
    final url = Uri.tryParse(dto.url?.trim() ?? '');
    if (title.isEmpty || url == null || !url.hasScheme || url.host.isEmpty) {
      return null;
    }
    return Chapter(
      title: TrackTitle(title),
      url: AudioUrl(url),
      label: DurationLabel(dto.duration?.trim() ?? ''),
    );
  }
}
