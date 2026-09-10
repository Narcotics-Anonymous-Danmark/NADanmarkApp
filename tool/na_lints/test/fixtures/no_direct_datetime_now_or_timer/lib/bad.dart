import 'dart:async';

void run() {
  // expect_lint: no_direct_datetime_now_or_timer
  final now = DateTime.now();
  // expect_lint: no_direct_datetime_now_or_timer
  final stamp = DateTime.timestamp();
  // expect_lint: no_direct_datetime_now_or_timer
  Timer(const Duration(seconds: 1), () {});
  // expect_lint: no_direct_datetime_now_or_timer
  Timer.periodic(const Duration(seconds: 1), (final timer) {});
  // expect_lint: no_direct_datetime_now_or_timer
  Future<void>.delayed(const Duration(seconds: 1));
  // expect_lint: no_direct_datetime_now_or_timer
  final watch = Stopwatch();
  print([now, stamp, watch]);
}
