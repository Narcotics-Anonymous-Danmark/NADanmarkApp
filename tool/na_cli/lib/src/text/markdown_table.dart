final class MarkdownTable {
  const MarkdownTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  String render() => [
    '| ${headers.join(' | ')} |',
    '| ${headers.map((final _) => '---').join(' | ')} |',
    ...rows.map((final row) => '| ${row.join(' | ')} |'),
  ].join('\n');
}
