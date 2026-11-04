@Tags(['unit'])
library;

import 'package:na_kernel/boundary.dart';
import 'package:na_kernel/na_kernel.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

void main() {
  test('every feature port throws with its name until bound', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final expectations = <ProviderListenable<Object>, String>{
      settingsPortProvider: 'SettingsPort',
      legacyStorePortProvider: 'LegacyStorePort',
      jftPortProvider: 'JftPort',
      externalLinksPortProvider: 'ExternalLinksPort',
      appInfoProvider: 'AppInfo',
      meetingSearchPortProvider: 'MeetingSearchPort',
      meetingFormatsPortProvider: 'MeetingFormatsPort',
      geolocationPortProvider: 'GeolocationPort',
      notificationsPortProvider: 'NotificationsPort',
      audioEnginePortProvider: 'AudioEnginePort',
      mediaSessionPortProvider: 'MediaSessionPort',
      audiobooksPortProvider: 'AudiobooksPort',
      readingsPortProvider: 'ReadingsPort',
    };
    for (final entry in expectations.entries) {
      expect(
        () => container.read(entry.key),
        throwsA(
          isA<ProviderException>().having(
            (wrapped) => wrapped.exception.toString(),
            'message',
            contains('${entry.value} is not bound'),
          ),
        ),
      );
    }
  });

  test('legacy store reads compare by value', () {
    expect(
      const LegacyStoreFound(dump: LegacyStoreDumpDto(language: 'da')),
      const LegacyStoreFound(dump: LegacyStoreDumpDto(language: 'da')),
    );
    expect(
      const LegacyStoreFound(dump: LegacyStoreDumpDto(language: 'da')),
      isNot(const LegacyStoreFound(dump: LegacyStoreDumpDto(language: 'en'))),
    );
    expect(const LegacyStoreAbsent(), const LegacyStoreAbsent());
    expect(
      const LegacyStoreUnreadable(detail: 'x'),
      const LegacyStoreUnreadable(detail: 'x'),
    );
    expect(
      const LegacyStoreFound(
        dump: LegacyStoreDumpDto(language: 'da'),
      ).toString(),
      contains('language'),
    );
    expect(const LegacyStoreUnreadable(detail: 'x').toString(), contains('x'));
    expect(const LegacyStoreAbsent().toString(), 'LegacyStoreAbsent');
    expect(
      const LegacyStoreFound(dump: LegacyStoreDumpDto(language: 'da')).hashCode,
      const LegacyStoreFound(dump: LegacyStoreDumpDto(language: 'da')).hashCode,
    );
    expect(
      const LegacyStoreAbsent().hashCode,
      const LegacyStoreAbsent().hashCode,
    );
    expect(
      const LegacyStoreUnreadable(detail: 'x').hashCode,
      const LegacyStoreUnreadable(detail: 'x').hashCode,
    );
  });

  test('media port values compare by value', () {
    final item = EngineItem(
      url: AudioUrl(Uri.parse('https://x.dk/a.mp3')),
      title: const TrackTitle('A'),
    );
    expect(
      item,
      EngineItem(
        url: AudioUrl(Uri.parse('https://x.dk/a.mp3')),
        title: const TrackTitle('A'),
      ),
    );
    expect(item.hashCode, isNot(0));
    expect(item.toString(), contains('a.mp3'));
    final token = LoadToken();
    expect(token, token);
    expect(token, isNot(LoadToken()));
    expect(token.toString(), startsWith('LoadToken#'));
    const track = SessionTrack(
      id: TrackId('a'),
      title: TrackTitle('A'),
      album: PlaylistTitle('B'),
      cover: NoCover(),
      length: UnknownLength(),
      kind: PlaylistKind.speak,
      previous: Neighbour.unavailable,
      next: Neighbour.unavailable,
    );
    expect(
      track,
      const SessionTrack(
        id: TrackId('a'),
        title: TrackTitle('A'),
        album: PlaylistTitle('B'),
        cover: NoCover(),
        length: UnknownLength(),
        kind: PlaylistKind.speak,
        previous: Neighbour.unavailable,
        next: Neighbour.unavailable,
      ),
    );
    expect(track.hashCode, track.hashCode);
    expect(track.toString(), contains('A / B'));
    const playback = SessionPlayback(
      status: ActiveStatus.paused,
      position: Duration(seconds: 3),
    );
    expect(
      playback,
      const SessionPlayback(
        status: ActiveStatus.paused,
        position: Duration(seconds: 3),
      ),
    );
    expect(playback.hashCode, playback.hashCode);
    expect(playback.toString(), 'SessionPlayback(paused, 3 s)');
  });
}
