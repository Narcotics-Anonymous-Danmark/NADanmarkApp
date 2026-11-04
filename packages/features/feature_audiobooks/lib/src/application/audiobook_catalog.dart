import 'dart:async';

import 'package:na_kernel/na_kernel.dart';
import 'package:na_l10n/na_l10n.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';

extension AudiobookCatalog on AudiobookId {
  AssetKey get cover => AssetKey(
    'packages/feature_audiobooks/assets/covers/${playlistId.value}.png',
  );

  PlaylistCover get playlistCover => BundledCover(asset: cover);

  String title({required AppLocalizations l10n}) => switch (this) {
    AudiobookId.basicText => l10n.basicText,
    AudiobookId.howAndWhy => l10n.howAndWhy,
    AudiobookId.stepWorkingGuides => l10n.stepWorkingGuides,
  };
}

final NotifierProviderFamily<
  AudiobookLoader,
  LoadResult<Audiobook>,
  AudiobookId
>
audiobookProvider = NotifierProvider.family(AudiobookLoader.new);

final class AudiobookLoader extends Notifier<LoadResult<Audiobook>> {
  AudiobookLoader(this.book);

  final AudiobookId book;

  @override
  LoadResult<Audiobook> build() {
    unawaited(Future.microtask(_load));
    return const Loading();
  }

  Future<void> _load() async {
    final outcome = await ref.read(audiobooksPortProvider).load(book: book);
    if (ref.mounted) {
      state = LoadResult.fromOutcome(outcome: outcome);
    }
  }
}
