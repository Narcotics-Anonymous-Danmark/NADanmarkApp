import 'package:flutter/services.dart';
import 'package:na_ports/na_ports.dart';
import 'package:url_launcher/url_launcher.dart';

final class UrlLauncherLinks implements ExternalLinksPort {
  const UrlLauncherLinks();

  @override
  Future<LinkOpening> open({required Uri uri}) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched ? LinkOpening.opened : LinkOpening.refused;
    } on PlatformException {
      return LinkOpening.refused;
    }
  }
}
