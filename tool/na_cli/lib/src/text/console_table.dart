final class ConsoleTable {
  const ConsoleTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  String render() {
    final widths = List.generate(
      headers.length,
      (final column) => [
        headers[column].length,
        ...rows.map((final row) => row[column].length),
      ].reduce((final a, final b) => a > b ? a : b),
    );
    String line(final List<String> cells) => cells.indexed
        .map((final cell) => cell.$2.padRight(widths[cell.$1]))
        .join('  ')
        .trimRight();
    return [
      line(headers),
      widths.map((final width) => '-' * width).join('  '),
      ...rows.map(line),
    ].join('\n');
  }
}
