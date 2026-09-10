import 'package:na_design/na_design.dart';
import 'package:riverpod/riverpod.dart';

final NotifierProvider<MenuController, NaDrawerVisibility>
menuControllerProvider = NotifierProvider(MenuController.new);

final class MenuController extends Notifier<NaDrawerVisibility> {
  @override
  NaDrawerVisibility build() => NaDrawerVisibility.closed;

  void open() => state = NaDrawerVisibility.open;

  void close() => state = NaDrawerVisibility.closed;
}
