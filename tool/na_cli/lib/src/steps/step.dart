enum StepState { satisfied, needed }

final class Step {
  const Step({required this.name, required this.check, required this.run});

  final String name;
  final Future<StepState> Function() check;
  final Future<void> Function() run;
}
