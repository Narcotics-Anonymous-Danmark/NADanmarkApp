import 'package:flutter/services.dart';
import 'package:na_ports/na_ports.dart';
import 'package:url_launcher/url_launcher.dart';

final class UrlLauncherLinks implements ExternalLinksPort {
  const UrlLauncherLinks();

  @override
  Future<LinkOpening> open({required Uri uri}) =>
      _launch(uri: uri, mode: LaunchMode.externalApplication);

  @override
  Future<LinkOpening> openInApp({required Uri uri}) =>
      _launch(uri: uri, mode: LaunchMode.inAppBrowserView);

  static Future<LinkOpening> _launch({
    required Uri uri,
    required LaunchMode mode,
  }) async {
    try {
      final launched = await launchUrl(uri, mode: mode);
      return launched ? LinkOpening.opened : LinkOpening.refused;
    } on PlatformException {
      return LinkOpening.refused;
    }
  }
}
