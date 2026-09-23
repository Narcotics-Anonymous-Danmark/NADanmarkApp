import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

extension type const FormatKey(String value) {
  static const FormatKey temporarilyClosed = FormatKey('TC');
  static const FormatKey hybrid = FormatKey('HY');

  String get folded => value.toLowerCase();
}

extension type const FormatId(int value) {}

enum KeyPresence { present, absent }

enum MeetingOrigin { denmark, denmarkAggregated, otherRoot }

@immutable
final class MeetingFormatCodes {
  const MeetingFormatCodes({required this.keys, required this.sharedIds});

  static const MeetingFormatCodes none = MeetingFormatCodes(
    keys: [],
    sharedIds: [],
  );

  final List<FormatKey> keys;
  final List<FormatId> sharedIds;

  KeyPresence presenceOf({required FormatKey key}) =>
      keys.any((candidate) => candidate.folded == key.folded)
      ? KeyPresence.present
      : KeyPresence.absent;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(keys), Object.hashAll(sharedIds));

  @override
  bool operator ==(Object other) =>
      other is MeetingFormatCodes &&
      const ListEquality<FormatKey>().equals(other.keys, keys) &&
      const ListEquality<FormatId>().equals(other.sharedIds, sharedIds);

  @override
  String toString() =>
      'MeetingFormatCodes(${keys.join(',')} / '
      '${sharedIds.join(',')})';
}
