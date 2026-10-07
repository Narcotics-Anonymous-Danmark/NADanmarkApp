@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:na_app/composition/app_config.dart';
import 'package:na_app/composition/production_overrides.dart';

void main() {
  test('BMLT base URLs come from the defines', () {
    final config = AppConfig.fromDefines(
      denmark: ' https://denmark.test/json/ ',
      tomato: 'https://tomato.test/json/',
    );
    expect(config.bmlt.denmark.value, 'https://denmark.test/json/');
    expect(config.bmlt.tomato.value, 'https://tomato.test/json/');
  });

  test('blank defines fall back to the spec defaults', () {
    final config = AppConfig.fromDefines(denmark: '', tomato: '  ');
    expect(
      config.bmlt.denmark.value,
      'https://www.nadanmark.dk/main_server/client_interface/json/',
    );
    expect(
      config.bmlt.tomato.value,
      'https://tomato.bmltenabled.org/main_server/client_interface/json/',
    );
    expect(AppConfig.fromEnvironment().bmlt.denmark.value, isNotEmpty);
  });

  test('the BMLT client gives up instead of hanging', () {
    final options = bmltDio().options;
    expect(options.connectTimeout, const Duration(seconds: 15));
    expect(options.receiveTimeout, const Duration(seconds: 30));
  });
}
