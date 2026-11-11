import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:na_kernel/src/media/media_values.dart';
import 'package:na_kernel/src/speaks/feed_text.dart';
import 'package:na_kernel/src/speaks/speak_values.dart';

@immutable
final class FeedEntry {
  const FeedEntry({
    required this.id,
    required this.url,
    required this.name,
    required this.location,
    required this.year,
  });

  final PlaylistId id;
  final AudioUrl url;
  final FeedText name;
  final FeedText location;
  final FeedText year;

  @override
  int get hashCode => Object.hash(id, url, name, location, year);

  @override
  bool operator ==(Object other) =>
      other is FeedEntry &&
      other.id == id &&
      other.url == url &&
      other.name == name &&
      other.location == location &&
      other.year == year;

  @override
  String toString() => 'FeedEntry(${id.value})';
}

@immutable
final class FeedGroup {
  const FeedGroup({
    required this.title,
    required this.language,
    required this.entries,
  });

  final FeedText title;
  final SpeakLanguage language;
  final List<FeedEntry> entries;

  static const ListEquality<FeedEntry> _entries = ListEquality();

  @override
  int get hashCode => Object.hash(title, language, _entries.hash(entries));

  @override
  bool operator ==(Object other) =>
      other is FeedGroup &&
      other.title == title &&
      other.language == language &&
      _entries.equals(other.entries, entries);

  @override
  String toString() =>
      'FeedGroup(${title.value}, ${language.code}, ${entries.length})';
}
