import 'package:na_ports/na_ports.dart';

final class ExternalLinksMimic implements ExternalLinksPort {
  ExternalLinksMimic({required this.behaviour});

  factory ExternalLinksMimic.opening() =>
      ExternalLinksMimic(behaviour: LinkOpening.opened);

  final LinkOpening behaviour;
  final List<Uri> opened = [];
  final List<Uri> openedInApp = [];

  @override
  Future<LinkOpening> open({required Uri uri}) async {
    opened.add(uri);
    return behaviour;
  }

  @override
  Future<LinkOpening> openInApp({required Uri uri}) async {
    openedInApp.add(uri);
    return behaviour;
  }
}
