import 'package:na_kernel/na_kernel.dart';
import 'package:riverpod/riverpod.dart';

sealed class RadiusDraft {
  const RadiusDraft();
}

final class NoDraft extends RadiusDraft {
  const NoDraft();
}

final class Dragging extends RadiusDraft {
  const Dragging({required this.radius});

  final Km radius;
}

final NotifierProvider<SearchRadiusDraft, RadiusDraft>
searchRadiusDraftProvider = NotifierProvider(SearchRadiusDraft.new);

final class SearchRadiusDraft extends Notifier<RadiusDraft> {
  @override
  RadiusDraft build() => const NoDraft();

  void drag({required Km radius}) => state = Dragging(radius: radius);

  void release() => state = const NoDraft();
}
