import 'dart:io';

import 'package:na_cli/src/ports/console.dart';

final class IoConsole implements Console {
  const IoConsole();

  @override
  void out({required final String line}) => stdout.writeln(line);

  @override
  void err({required final String line}) => stderr.writeln(line);
}
