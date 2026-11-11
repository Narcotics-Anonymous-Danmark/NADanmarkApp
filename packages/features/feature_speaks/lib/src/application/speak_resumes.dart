import 'package:collection/collection.dart';
import 'package:feature_media_player/feature_media_player.dart';
import 'package:feature_speaks/src/application/speaks_catalog_loader.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:riverpod/riverpod.dart';

@immutable
sealed class ActiveSpeak {
  const ActiveSpeak();

  static ActiveSpeak of({required PlayerState player}) => switch (player) {
    PlayerActive(:final playlist) when playlist.kind == PlaylistKind.speak =>
      ActiveSpeakOf(id: playlist.id),
    PlayerActive() || PlayerIdle() => const NoActiveSpeak(),
  };
}

final class ActiveSpeakOf extends ActiveSpeak {
  const ActiveSpeakOf({required this.id});

  final PlaylistId id;

  @override
  int get hashCode => Object.hash(ActiveSpeakOf, id);

  @override
  bool operator ==(Object other) => other is ActiveSpeakOf && other.id == id;
}

final class NoActiveSpeak extends ActiveSpeak {
  const NoActiveSpeak();

  @override
  int get hashCode => (NoActiveSpeak).hashCode;

  @override
  bool operator ==(Object other) => other is NoActiveSpeak;
}

@immutable
final class SpeakResumes {
  const SpeakResumes({required this.continueList, required this.started});

  factory SpeakResumes.of({
    required SpeakCatalog catalog,
    required ResumeIndex index,
    required ActiveSpeak active,
  }) {
    final byId = Map.fromEntries(
      catalog.speaks.map((speak) => MapEntry(speak.id, speak)),
    );
    final resumed = index.points.entries
        .where(
          (entry) =>
              byId.containsKey(entry.key) &&
              TrackProgress.ofResume(
                    resume: ResumeAt(point: entry.value),
                    label: const UnknownLength(),
                  ) !=
                  const NoProgress(),
        )
        .sorted(
          (a, b) => b.value.updatedAt.utc.compareTo(a.value.updatedAt.utc),
        )
        .map((entry) => entry.key);
    final ordered = switch (active) {
      ActiveSpeakOf(:final id) when byId.containsKey(id) => [
        id,
        ...resumed.where((resumedId) => resumedId != id),
      ],
      ActiveSpeakOf() || NoActiveSpeak() => resumed.toList(),
    };
    return SpeakResumes(
      continueList: List.unmodifiable(
        ordered.take(limit.value).map((id) => byId[id]).whereType<Speak>(),
      ),
      started: Set.unmodifiable(ordered),
    );
  }

  static const SpeakCount limit = SpeakCount(10);

  static const SpeakResumes none = SpeakResumes(
    continueList: [],
    started: {},
  );

  static const ListEquality<Speak> _speaks = ListEquality();
  static const SetEquality<PlaylistId> _ids = SetEquality();

  final List<Speak> continueList;
  final Set<PlaylistId> started;

  SpeakCount get startedCount => SpeakCount(started.length);

  @override
  int get hashCode =>
      Object.hash(_speaks.hash(continueList), _ids.hash(started));

  @override
  bool operator ==(Object other) =>
      other is SpeakResumes &&
      _speaks.equals(other.continueList, continueList) &&
      _ids.equals(other.started, started);
}

final Provider<ActiveSpeak> activeSpeakProvider = Provider.autoDispose(
  (ref) => ref.watch(
    mediaPlayerProvider.select((player) => ActiveSpeak.of(player: player)),
  ),
);

final Provider<SpeakResumes> speakResumesProvider = Provider.autoDispose(
  (ref) => SpeakResumes.of(
    catalog: ref.watch(speaksCatalogProvider).catalogOrEmpty,
    index: switch (ref.watch(resumePointsProvider)) {
      Loaded(:final value) => value.speaks,
      Loading() || Failed() => ResumeIndex.empty,
    },
    active: ref.watch(activeSpeakProvider),
  ),
);
