import 'package:adapter_bmlt/adapter_bmlt.dart';

const String bmltDenmarkDefine = String.fromEnvironment(
  'BMLT_DENMARK_BASE_URL',
);
const String bmltTomatoDefine = String.fromEnvironment('BMLT_TOMATO_BASE_URL');

final class AppConfig {
  const AppConfig({required this.bmlt});

  factory AppConfig.fromDefines({
    required String denmark,
    required String tomato,
  }) => AppConfig(
    bmlt: BmltEndpoints(
      denmark: BmltBaseUrl(
        denmark.trim().isEmpty ? defaultDenmark.value : denmark.trim(),
      ),
      tomato: BmltBaseUrl(
        tomato.trim().isEmpty ? defaultTomato.value : tomato.trim(),
      ),
    ),
  );

  factory AppConfig.fromEnvironment() => AppConfig.fromDefines(
    denmark: bmltDenmarkDefine,
    tomato: bmltTomatoDefine,
  );

  static const BmltBaseUrl defaultDenmark = BmltBaseUrl(
    'https://www.nadanmark.dk/main_server/client_interface/json/',
  );
  static const BmltBaseUrl defaultTomato = BmltBaseUrl(
    'https://tomato.bmltenabled.org/main_server/client_interface/json/',
  );

  final BmltEndpoints bmlt;
}
