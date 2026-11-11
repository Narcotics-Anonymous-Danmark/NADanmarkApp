import 'dart:async';

import 'package:feature_speaks/src/application/speak_texts.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

enum RefreshState { idle, refreshing }

@immutable
sealed class CatalogState {
  const CatalogState();

  SpeakCatalog get catalogOrEmpty => switch (this) {
    CatalogReady(:final catalog) => catalog,
    CatalogLoading() || CatalogFailed() => SpeakCatalog.empty,
  };
}

final class CatalogLoading extends CatalogState {
  const CatalogLoading();

  @override
  int get hashCode => (CatalogLoading).hashCode;

  @override
  bool operator ==(Object other) => other is CatalogLoading;

  @override
  String toString() => 'CatalogLoading';
}

final class CatalogReady extends CatalogState {
  const CatalogReady({required this.catalog, required this.refresh});

  final SpeakCatalog catalog;
  final RefreshState refresh;

  @override
  int get hashCode => Object.hash(catalog, refresh);

  @override
  bool operator ==(Object other) =>
      other is CatalogReady &&
      other.catalog == catalog &&
      other.refresh == refresh;

  @override
  String toString() => 'CatalogReady($catalog, ${refresh.name})';
}

final class CatalogFailed extends CatalogState {
  const CatalogFailed({required this.failure});

  final Failure failure;

  @override
  int get hashCode => Object.hash(CatalogFailed, failure);

  @override
  bool operator ==(Object other) =>
      other is CatalogFailed && other.failure == failure;

  @override
  String toString() => 'CatalogFailed($failure)';
}

final Provider<SpeakKindWords> speakKindWordsProvider = Provider(
  (ref) => SpeakTexts.kindWords(),
);

final NotifierProvider<SpeaksCatalogLoader, CatalogState>
speaksCatalogProvider = NotifierProvider(SpeaksCatalogLoader.new);

final class SpeaksCatalogLoader extends Notifier<CatalogState> {
  SpeaksFeedPort get _feed => ref.read(speaksFeedPortProvider);

  @override
  CatalogState build() {
    unawaited(Future.microtask(_load));
    return const CatalogLoading();
  }

  Future<void> reload() async {
    switch (state) {
      case CatalogReady(:final catalog, refresh: RefreshState.idle):
        state = CatalogReady(
          catalog: catalog,
          refresh: RefreshState.refreshing,
        );
      case CatalogFailed():
        state = const CatalogLoading();
      case CatalogReady(refresh: RefreshState.refreshing) || CatalogLoading():
        return;
    }
    await _load();
  }

  Future<void> _load() async {
    final feeds = await Future.wait(
      SpeakLanguage.values.map((language) => _feed.feed(language: language)),
    );
    if (!ref.mounted) {
      return;
    }
    final groups = feeds.whereType<Ok<List<FeedGroup>, Failure>>();
    state = switch ((groups.isEmpty, state)) {
      (true, CatalogReady(:final catalog)) => CatalogReady(
        catalog: catalog,
        refresh: RefreshState.idle,
      ),
      (true, CatalogLoading() || CatalogFailed()) => CatalogFailed(
        failure: feeds.whereType<Err<List<FeedGroup>, Failure>>().first.error,
      ),
      (false, CatalogState()) => CatalogReady(
        catalog: SpeakCatalog.build(
          groups: List.unmodifiable(groups.expand((ok) => ok.value)),
          kindWords: ref.read(speakKindWordsProvider),
        ),
        refresh: RefreshState.idle,
      ),
    };
  }
}
