sealed class Progress {
  const Progress();
}

final class NotStarted extends Progress {
  const NotStarted();
}

final class Started extends Progress {
  const Started({required this.step});

  final int step;
}

final class Counter {
  Counter({required this.start}) : current = start;

  final int start;
  int current;
  Progress progress = const NotStarted();

  void advance() => progress = Started(step: current += 1);
}
