final class SecretsXcconfig {
  const SecretsXcconfig();

  String render({required final Map<String, String> defines}) {
    final entries = defines.entries
        .where((final entry) => entry.key == 'GOOGLE_MAPS_API_KEY')
        .map((final entry) => '${entry.key} = ${entry.value}');
    return [...entries, ''].join('\n');
  }
}
