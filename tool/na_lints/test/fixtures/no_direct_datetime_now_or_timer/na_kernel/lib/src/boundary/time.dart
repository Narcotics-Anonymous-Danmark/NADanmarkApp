import 'dart:async';

void run() {
  final now = DateTime.now();
  final stamp = DateTime.timestamp();
  Timer(const Duration(seconds: 1), () {});
  Timer.periodic(const Duration(seconds: 1), (final timer) {});
  Future<void>.delayed(const Duration(seconds: 1));
  final watch = Stopwatch();
  print([now, stamp, watch]);
}
