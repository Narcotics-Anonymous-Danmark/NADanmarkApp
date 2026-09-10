import 'package:adapter_links/src/url_launcher_links.dart';
import 'package:na_ports/na_ports.dart';
import 'package:riverpod/misc.dart';

List<Override> linksOverrides() => [
  externalLinksPortProvider.overrideWithValue(const UrlLauncherLinks()),
];
