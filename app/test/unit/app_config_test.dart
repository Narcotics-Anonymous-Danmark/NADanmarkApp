@Tags(['unit'])
library;

import 'package:adapter_wordpress/adapter_wordpress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_app/composition/app_config.dart';
import 'package:na_app/composition/production_overrides.dart';
import 'package:na_kernel/na_kernel.dart';

void main() {
  test('BMLT base URLs come from the defines', () {
    final config = AppConfig.fromDefines(
      denmark: ' https://denmark.test/json/ ',
      tomato: 'https://tomato.test/json/',
      naApi: 'https://wp.test',
      basicAuth: 'user:secret',
    );
    expect(config.bmlt.denmark.value, 'https://denmark.test/json/');
    expect(config.bmlt.tomato.value, 'https://tomato.test/json/');
  });

  test('blank defines fall back to the spec defaults', () {
    final config = AppConfig.fromDefines(
      denmark: '',
      tomato: '  ',
      naApi: ' ',
      basicAuth: '',
    );
    expect(
      config.bmlt.denmark.value,
      'https://www.nadanmark.dk/main_server/client_interface/json/',
    );
    expect(
      config.bmlt.tomato.value,
      'https://tomato.bmltenabled.org/main_server/client_interface/json/',
    );
    expect(AppConfig.fromEnvironment().bmlt.denmark.value, isNotEmpty);
    expect(config.wordpress.base.value, 'https://www.nadanmark.dk');
    expect(config.wordpress.credentials, isA<NoCredentials>());
  });

  test('the WordPress base URL and credentials come from the defines', () {
    final config = AppConfig.fromDefines(
      denmark: '',
      tomato: '',
      naApi: ' https://wp.test ',
      basicAuth: 'user:secret',
    );
    expect(
      config.wordpress.speaks(language: SpeakLanguage.danish),
      'https://wp.test/wp-json/wp/v2/speaks?excerpt[]=NA-SPEAKS-DK',
    );
    expect(config.wordpress.credentials.headers, {
      'Authorization': 'Basic dXNlcjpzZWNyZXQ=',
    });
  });

  test('the BMLT client gives up instead of hanging', () {
    for (final dio in [bmltDio(), wordpressDio()]) {
      expect(dio.options.connectTimeout, const Duration(seconds: 15));
      expect(dio.options.receiveTimeout, const Duration(seconds: 30));
    }
  });
}
