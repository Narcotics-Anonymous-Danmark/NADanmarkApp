import 'package:na_cli/src/android/key_alias.dart';
import 'package:na_cli/src/fs/file_path.dart';

final class KeyProperties {
  const KeyProperties({
    required this.storeFile,
    required this.storePassword,
    required this.keyAlias,
    required this.keyPassword,
  });

  final FilePath storeFile;
  final String storePassword;
  final KeyAlias keyAlias;
  final String keyPassword;

  String render() => [
    'storeFile=${storeFile.value}',
    'storePassword=$storePassword',
    'keyAlias=${keyAlias.value}',
    'keyPassword=$keyPassword',
    '',
  ].join('\n');
}
