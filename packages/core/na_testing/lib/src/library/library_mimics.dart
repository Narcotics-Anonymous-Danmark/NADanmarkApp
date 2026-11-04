import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/src/builders/test_values.dart';
import 'package:na_testing/src/library/library_builders.dart';

final class AudiobooksMimic implements AudiobooksPort {
  AudiobooksMimic({required this.books});

  factory AudiobooksMimic.synthetic() => AudiobooksMimic(
    books: Map.unmodifiable({
      for (final id in AudiobookId.values)
        id: Ok<Audiobook, Failure>(value: anAudiobook(id: id)),
    }),
  );

  Map<AudiobookId, Outcome<Audiobook, Failure>> books;
  CallCount loads = const CallCount(0);

  @override
  Future<Outcome<Audiobook, Failure>> load({required AudiobookId book}) async {
    loads = loads.next;
    return books[book] ??
        Err(error: UnavailableFailure(what: 'no book ${book.name}'));
  }

  void serve({
    required AudiobookId book,
    required Outcome<Audiobook, Failure> outcome,
  }) => books = Map.unmodifiable({...books, book: outcome});
}

final class ReadingsMimic implements ReadingsPort {
  ReadingsMimic({required this.outcome});

  factory ReadingsMimic.synthetic() =>
      ReadingsMimic(outcome: Ok(value: aReadingCollection()));

  Outcome<ReadingCollection, Failure> outcome;

  @override
  Future<Outcome<ReadingCollection, Failure>> load() async => outcome;
}
