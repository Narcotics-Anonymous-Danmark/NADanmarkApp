final class EnvFile {
  const EnvFile();

  Map<String, String> parse({required final String text}) => Map.unmodifiable({
    for (final line in text.split('\n'))
      if (line.contains('=') && !line.trimLeft().startsWith('#'))
        line.substring(0, line.indexOf('=')).trim(): _unquote(
          line.substring(line.indexOf('=') + 1).trim(),
        ),
  });

  String _unquote(final String value) {
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
}
