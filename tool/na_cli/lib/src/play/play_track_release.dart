import 'dart:convert';

import 'package:na_cli/src/release/version.dart';

enum PlayReleaseStatus {
  completed,
  draft
  ;

  String get wire => name;
}

sealed class PlayReleaseNotes {
  const PlayReleaseNotes();
}

final class LocalisedNotes extends PlayReleaseNotes {
  const LocalisedNotes({required this.language, required this.text});

  final String language;
  final String text;
}

final class NoNotes extends PlayReleaseNotes {
  const NoNotes();
}

final class PlayTrackRelease {
  const PlayTrackRelease({
    required this.version,
    required this.status,
    required this.notes,
  });

  final AppVersion version;
  final PlayReleaseStatus status;
  final PlayReleaseNotes notes;

  static const int notesLimit = 500;

  Map<String, Object> toJson() => {
    'releases': [
      {
        'name': '${version.version} (${version.build.value})',
        'versionCodes': ['${version.code.value}'],
        'status': status.wire,
        ...switch (notes) {
          NoNotes() => const <String, Object>{},
          LocalisedNotes(:final language, :final text) => {
            'releaseNotes': [
              {
                'language': language,
                'text': text.length <= notesLimit
                    ? text
                    : text.substring(0, notesLimit),
              },
            ],
          },
        },
      },
    ],
  };

  String render() => jsonEncode(toJson());
}
