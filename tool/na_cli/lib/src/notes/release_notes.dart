final class ReleaseNotes {
  const ReleaseNotes();

  static const String startMarker = '<!-- release-notes:start -->';
  static const String endMarker = '<!-- release-notes:end -->';

  String extract({required final String text}) {
    final start = text.indexOf(startMarker);
    final end = text.indexOf(endMarker);
    if (start < 0 || end < 0 || end < start) {
      return text.trim();
    }
    return text.substring(start + startMarker.length, end).trim();
  }

  String truncate({required final String text, required final int maxLength}) =>
      text.length <= maxLength ? text : text.substring(0, maxLength);
}
