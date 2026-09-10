@Tags(['unit'])
library;

import 'dart:convert';

import 'package:na_cli/src/notes/release_notes.dart';
import 'package:na_cli/src/play/play_track_release.dart';
import 'package:na_cli/src/play/service_account.dart';
import 'package:test/test.dart';

import '../support/builders.dart';
import '../support/json_shapes.dart';

void main() {
  test('track body names the release, lists the code and status', () {
    final json =
        jsonDecode(
              PlayTrackRelease(
                version: anAppVersion(build: 3),
                status: PlayReleaseStatus.completed,
                notes: const NoNotes(),
              ).render(),
            )
            as Map<String, Object?>;
    final release = singleObjectIn(list: json['releases']);
    expect(release['name'], '2.0.0 (3)');
    expect(release['versionCodes'], ['1120000003']);
    expect(release['status'], 'completed');
    expect(release.containsKey('releaseNotes'), isFalse);
  });

  test('release notes are localised and truncated to 500 characters', () {
    final json = PlayTrackRelease(
      version: anAppVersion(),
      status: PlayReleaseStatus.draft,
      notes: LocalisedNotes(language: 'da-DK', text: 'x' * 600),
    ).toJson();
    final release = singleObjectIn(list: json['releases']);
    final notes = singleObjectIn(list: release['releaseNotes']);
    expect(notes['language'], 'da-DK');
    expect(notes['text'], hasLength(500));
    expect(release['status'], 'draft');
  });

  test('release notes are cut out between the markers', () {
    const notes = ReleaseNotes();
    expect(
      notes.extract(
        text:
            'intro\n<!-- release-notes:start -->\nHello\n'
            '<!-- release-notes:end -->\ntail',
      ),
      'Hello',
    );
    expect(notes.extract(text: '  whole text  '), 'whole text');
    expect(notes.truncate(text: 'abcdef', maxLength: 3), 'abc');
  });

  test('service account accepts raw or base64 json', () {
    final raw = aServiceAccountJson();
    final parsed = ServiceAccount.parse(raw: raw) as ServiceAccountParsed;
    expect(parsed.account.clientEmail, 'ci@project.iam.gserviceaccount.com');
    expect(
      ServiceAccount.parse(raw: base64Encode(utf8.encode(raw))),
      isA<ServiceAccountParsed>(),
    );
    expect(ServiceAccount.parse(raw: '{}'), isA<ServiceAccountRejected>());
    expect(
      ServiceAccount.parse(raw: 'nonsense'),
      isA<ServiceAccountRejected>(),
    );
  });
}
