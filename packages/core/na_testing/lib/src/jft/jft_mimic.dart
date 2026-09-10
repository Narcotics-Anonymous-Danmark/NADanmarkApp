import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';

final class JftMimic implements JftPort {
  JftMimic({required this.outcome});

  factory JftMimic.calendar({required JftCalendar calendar}) =>
      JftMimic(outcome: Ok(value: calendar));

  Outcome<JftCalendar, Failure> outcome;
  int loads = 0;

  @override
  Future<Outcome<JftCalendar, Failure>> load() async {
    loads += 1;
    return outcome;
  }
}
