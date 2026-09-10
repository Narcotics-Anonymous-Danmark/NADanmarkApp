@Tags(['unit'])
library;

import 'package:adapter_links/adapter_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_ports/na_ports.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:riverpod/riverpod.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('opens the uri externally and reports the launcher verdict', () async {
    final launcher = _LauncherMimic(answer: true);
    UrlLauncherPlatform.instance = launcher;
    final uri = Uri.parse('mailto:app@nadanmark.dk');
    expect(await const UrlLauncherLinks().open(uri: uri), LinkOpening.opened);
    expect(launcher.launched, [uri.toString()]);
    expect(launcher.modes, [PreferredLaunchMode.externalApplication]);
  });

  test('a refused launch and a platform error both read as refused', () async {
    UrlLauncherPlatform.instance = _LauncherMimic(answer: false);
    final uri = Uri.parse('https://na.org/');
    expect(await const UrlLauncherLinks().open(uri: uri), LinkOpening.refused);
    UrlLauncherPlatform.instance = _ThrowingLauncher();
    expect(await const UrlLauncherLinks().open(uri: uri), LinkOpening.refused);
  });

  test('linksOverrides binds the port', () {
    final container = ProviderContainer(overrides: linksOverrides());
    addTearDown(container.dispose);
    expect(container.read(externalLinksPortProvider), isA<UrlLauncherLinks>());
  });
}

final class _LauncherMimic extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  _LauncherMimic({required this.answer});

  final bool answer;
  final List<String> launched = [];
  final List<PreferredLaunchMode> modes = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    modes.add(options.mode);
    return answer;
  }
}

final class _ThrowingLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async =>
      throw PlatformException(code: 'boom');
}
