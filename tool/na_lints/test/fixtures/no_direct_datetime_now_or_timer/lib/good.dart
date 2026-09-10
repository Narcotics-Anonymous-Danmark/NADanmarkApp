void run() {
  final epoch = DateTime.utc(1970);
  final future = Future<int>.value(1);
  final duration = Duration(seconds: epoch.second);
  print([epoch, future, duration]);
}
