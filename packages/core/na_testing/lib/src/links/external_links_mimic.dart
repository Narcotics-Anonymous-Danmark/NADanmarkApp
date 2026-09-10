import 'package:na_ports/na_ports.dart';

final class ExternalLinksMimic implements ExternalLinksPort {
  ExternalLinksMimic({required this.behaviour});

  factory ExternalLinksMimic.opening() =>
      ExternalLinksMimic(behaviour: LinkOpening.opened);

  final LinkOpening behaviour;
  final List<Uri> opened = [];

  @override
  Future<LinkOpening> open({required Uri uri}) async {
    opened.add(uri);
    return behaviour;
  }
}
