import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

@immutable
final class ContactLinks {
  const ContactLinks({
    required this.meetingListServant,
    required this.website,
    required this.naWorld,
    required this.sourceCode,
    required this.bugReports,
  });

  static final ContactLinks standard = ContactLinks(
    meetingListServant: Uri.parse('mailto:modelisteansvarlig@nadanmark.dk'),
    website: Uri.parse('https://nadanmark.dk/'),
    naWorld: Uri.parse('https://na.org/'),
    sourceCode: Uri.parse('https://github.com/Narcotics-Anonymous-Danmark/App'),
    bugReports: Uri.parse('mailto:app@nadanmark.dk'),
  );

  final Uri meetingListServant;
  final Uri website;
  final Uri naWorld;
  final Uri sourceCode;
  final Uri bugReports;
}

final Provider<ContactLinks> contactLinksProvider = Provider(
  (ref) => ContactLinks.standard,
);
