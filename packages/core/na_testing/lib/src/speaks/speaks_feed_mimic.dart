import 'dart:async';

import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:na_testing/src/builders/test_values.dart';
import 'package:na_testing/src/speaks/speak_builders.dart';

final class FeedHold {
  FeedHold();

  final Completer<void> _release = Completer<void>();

  void release() => _release.complete();
}

final class SpeaksFeedMimic implements SpeaksFeedPort {
  SpeaksFeedMimic({required this.outcomes});

  factory SpeaksFeedMimic.sample() => SpeaksFeedMimic(
    outcomes: {
      SpeakLanguage.danish: Ok(
        value: feedGroupsOf(
          dtos: sampleDanishSpeaks,
          language: SpeakLanguage.danish,
        ),
      ),
      SpeakLanguage.english: Ok(
        value: feedGroupsOf(
          dtos: sampleEnglishSpeaks,
          language: SpeakLanguage.english,
        ),
      ),
    },
  );

  final Map<SpeakLanguage, Outcome<List<FeedGroup>, Failure>> outcomes;
  final Map<SpeakLanguage, FeedHold> _holds = {};
  CallCount loads = const CallCount(0);

  void serve({
    required SpeakLanguage language,
    required Outcome<List<FeedGroup>, Failure> outcome,
  }) => outcomes[language] = outcome;

  void failBoth() {
    for (final language in SpeakLanguage.values) {
      serve(
        language: language,
        outcome: Err(error: NetworkFailure(detail: language.code)),
      );
    }
  }

  FeedHold hold({required SpeakLanguage language}) =>
      _holds[language] = FeedHold();

  @override
  Future<Outcome<List<FeedGroup>, Failure>> feed({
    required SpeakLanguage language,
  }) async {
    loads = loads.next;
    switch (_holds.remove(language)) {
      case final FeedHold held:
        await held._release.future;
      case null:
        break;
    }
    return outcomes[language] ??
        Err(error: UnavailableFailure(what: 'speaks ${language.code}'));
  }
}
