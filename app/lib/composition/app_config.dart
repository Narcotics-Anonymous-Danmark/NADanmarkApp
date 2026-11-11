import 'package:adapter_bmlt/adapter_bmlt.dart';
import 'package:adapter_wordpress/adapter_wordpress.dart';

const String bmltDenmarkDefine = String.fromEnvironment(
  'BMLT_DENMARK_BASE_URL',
);
const String bmltTomatoDefine = String.fromEnvironment('BMLT_TOMATO_BASE_URL');
const String naApiBaseDefine = String.fromEnvironment('NA_API_BASE_URL');
const String naApiBasicAuthDefine = String.fromEnvironment(
  'NA_API_BASIC_AUTH',
);

final class AppConfig {
  const AppConfig({required this.bmlt, required this.wordpress});

  factory AppConfig.fromDefines({
    required String denmark,
    required String tomato,
    required String naApi,
    required String basicAuth,
  }) => AppConfig(
    bmlt: BmltEndpoints(
      denmark: BmltBaseUrl(
        denmark.trim().isEmpty ? defaultDenmark.value : denmark.trim(),
      ),
      tomato: BmltBaseUrl(
        tomato.trim().isEmpty ? defaultTomato.value : tomato.trim(),
      ),
    ),
    wordpress: WordPressEndpoints(
      base: WordPressBaseUrl(
        naApi.trim().isEmpty ? defaultNaApi.value : naApi.trim(),
      ),
      credentials: WordPressCredentials.of(
        credentials: BasicCredentials(basicAuth.trim()),
      ),
    ),
  );

  factory AppConfig.fromEnvironment() => AppConfig.fromDefines(
    denmark: bmltDenmarkDefine,
    tomato: bmltTomatoDefine,
    naApi: naApiBaseDefine,
    basicAuth: naApiBasicAuthDefine,
  );

  static const BmltBaseUrl defaultDenmark = BmltBaseUrl(
    'https://www.nadanmark.dk/main_server/client_interface/json/',
  );
  static const BmltBaseUrl defaultTomato = BmltBaseUrl(
    'https://tomato.bmltenabled.org/main_server/client_interface/json/',
  );
  static const WordPressBaseUrl defaultNaApi = WordPressBaseUrl(
    'https://www.nadanmark.dk',
  );

  final BmltEndpoints bmlt;
  final WordPressEndpoints wordpress;
}
