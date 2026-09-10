import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/riverpod.dart';

final NotifierProvider<JftController, LoadResult<JftLookup>>
jftControllerProvider = NotifierProvider(JftController.new);

final class JftController extends Notifier<LoadResult<JftLookup>> {
  @override
  LoadResult<JftLookup> build() => const Loading();

  Future<void> load() async {
    final today = ref.read(clockProvider).today();
    final loaded = await ref.read(jftPortProvider).load();
    state = LoadResult.fromOutcome(
      outcome: loaded.map(
        transform: (calendar) => calendar.entryFor(date: today),
      ),
    );
  }
}
