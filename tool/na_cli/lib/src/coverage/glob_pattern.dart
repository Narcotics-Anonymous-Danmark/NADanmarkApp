extension type const GlobPattern(String value) {
  RegExp toRegExp() {
    final buffer = StringBuffer('^');
    var index = 0;
    while (index < value.length) {
      final char = value[index];
      if (value.startsWith('**/', index)) {
        buffer.write('(?:.*/)?');
        index += 3;
      } else if (value.startsWith('**', index)) {
        buffer.write('.*');
        index += 2;
      } else if (char == '*') {
        buffer.write('[^/]*');
        index += 1;
      } else if (char == '?') {
        buffer.write('[^/]');
        index += 1;
      } else {
        buffer.write(RegExp.escape(char));
        index += 1;
      }
    }
    buffer.write(r'$');
    return RegExp(buffer.toString());
  }

  GlobMatch match({required String path}) =>
      toRegExp().hasMatch(path) ? GlobMatch.matches : GlobMatch.differs;
}

enum GlobMatch { matches, differs }
