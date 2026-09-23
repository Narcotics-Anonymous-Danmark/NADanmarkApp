@Tags(['unit'])
library;

import 'package:na_kernel/na_kernel.dart';
import 'package:test/test.dart';

import '../support/meetings.dart';

void main() {
  group('Meeting value semantics', () {
    test('a meeting equals an identical copy and differs by any field', () {
      expect(aMeeting(), aMeeting());
      expect(aMeeting().hashCode, aMeeting().hashCode);
      expect(aMeeting(id: 2), isNot(aMeeting()));
      expect(aMeeting(locationLines: ['Andet']), isNot(aMeeting()));
      expect(aMeeting(formats: ['O']), isNot(aMeeting()));
      expect(
        aMeeting().toString(),
        'Meeting(1, Bare for i dag, monday 19:00 - 20:00)',
      );
    });

    test('the sealed parts compare by value', () {
      expect(
        const Mapped(point: GeoPoint(latitude: 1, longitude: 2)),
        const Mapped(point: GeoPoint(latitude: 1, longitude: 2)),
      );
      expect(const Unmapped(), const Unmapped());
      expect(aVirtualLink(), aVirtualLink());
      expect(const NoVirtualLink(), isNot(aVirtualLink()));
      expect(
        const DialInNumber(number: '+45 1'),
        const DialInNumber(number: '+45 1'),
      );
      expect(const Comment(text: 'x'), const Comment(text: 'x'));
      expect(const NoComment(), isNot(const Comment(text: 'x')));
      expect(
        {
          const Mapped(point: GeoPoint(latitude: 1, longitude: 2)).hashCode,
          const Unmapped().hashCode,
          const NoDialIn().hashCode,
          const NoComment().hashCode,
          const NoVirtualLink().hashCode,
        },
        hasLength(5),
      );
    });
  });

  group('Meeting times', () {
    test('end time is start plus duration', () {
      expect(
        aMeeting(
          duration: const Duration(hours: 1, minutes: 30),
        ).times.toString(),
        '19:00 - 20:30',
      );
    });

    test('a blank duration ends when it starts', () {
      expect(
        aMeeting(duration: Duration.zero).times.toString(),
        '19:00 - 19:00',
      );
    });

    test('a meeting past midnight wraps to the next day', () {
      expect(aMeeting(hour: 23, minute: 30).times.toString(), '23:30 - 00:30');
    });
  });

  group('Temporarily closed rule', () {
    test('TC without virtual link is closed', () {
      expect(
        aMeeting(formats: ['O', 'TC']).closure,
        TemporaryClosure.temporarilyClosed,
      );
    });

    test('TC with a virtual link is not closed', () {
      expect(
        aMeeting(formats: ['O', 'TC'], virtualLink: aVirtualLink()).closure,
        TemporaryClosure.open,
      );
    });

    test('a key that only contains TC is not closed', () {
      expect(aMeeting(formats: ['O', 'ATC']).closure, TemporaryClosure.open);
    });

    test('TC matches case-insensitively', () {
      expect(
        aMeeting(formats: ['tc']).closure,
        TemporaryClosure.temporarilyClosed,
      );
    });
  });

  group('Meeting card actions', () {
    test(
      'in-person meeting opens the Google Maps search for its coordinates',
      () {
        expect(aMeeting().actions, [
          OpenDirections(
            uri: Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=55.476224,8.4606976',
            ),
          ),
        ]);
      },
    );

    test('hybrid meeting offers directions and the virtual link', () {
      final meeting = aMeeting(formats: ['HY'], virtualLink: aVirtualLink());
      expect(
        meeting.venue,
        Hybrid(link: Uri.parse('https://zoom.example/j/1')),
      );
      expect(meeting.actions.map((action) => action.runtimeType), [
        OpenDirections,
        JoinVirtualMeeting,
      ]);
    });

    test(
      'virtual meeting with a phone number offers the link and the dial-in',
      () {
        final meeting = aMeeting(
          virtualLink: aVirtualLink(),
          dialIn: const DialInNumber(number: '+45 12 34'),
        );
        expect(meeting.venue, isA<Virtual>());
        expect(meeting.actions, [
          JoinVirtualMeeting(uri: Uri.parse('https://zoom.example/j/1')),
          CallDialIn(
            uri: Uri(scheme: 'tel', path: '+45 12 34'),
          ),
        ]);
      },
    );

    test('a dial-in number without a virtual link offers nothing extra', () {
      final meeting = aMeeting(dialIn: const DialInNumber(number: '+45 12 34'));
      expect(meeting.actions.single, isA<OpenDirections>());
    });

    test('a meeting without coordinates offers no directions', () {
      expect(aMeeting(location: const Unmapped()).actions, isEmpty);
    });

    test('HY without a virtual link is an in-person meeting', () {
      expect(aMeeting(formats: ['HY']).venue, const InPerson());
    });
  });

  group('Transit lines', () {
    test('the BMLT prefixes are stripped case-insensitively everywhere', () {
      expect(
        TransitLine.fromWire(
          kind: TransitKind.bus,
          text: 'Bus Lines#@-@#2A, 5C',
        ).lines,
        '2A, 5C',
      );
      expect(
        TransitLine.fromWire(
          kind: TransitKind.train,
          text: 'train lines#@-@#S Train Lines#@-@#E',
        ).lines,
        'S  E',
      );
      expect(
        TransitLine.fromWire(kind: TransitKind.bus, text: 'Bus Lines 1').lines,
        'Bus Lines 1',
      );
    });
  });
}
