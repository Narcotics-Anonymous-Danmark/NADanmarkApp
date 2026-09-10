import 'package:na_cli/src/ios/export_options.dart';

final class SigningIdentities {
  const SigningIdentities();

  static final RegExp _line = RegExp(r'^\s*\d+\)\s+[0-9A-F]+\s+"(.+)"\s*$');

  IdentityLookup distributionIdentity({required final String listing}) {
    final names = listing
        .split('\n')
        .map(_line.firstMatch)
        .nonNulls
        .map((final match) => match.group(1).toString())
        .where(
          (final name) =>
              name.startsWith('Apple Distribution') ||
              name.startsWith('iPhone Distribution'),
        );
    if (names.isEmpty) {
      return const IdentityMissing(
        reason:
            'no "Apple Distribution" or "iPhone Distribution" identity in '
            'the release keychain',
      );
    }
    return IdentityFound(identity: SigningIdentity(names.first));
  }
}

sealed class IdentityLookup {
  const IdentityLookup();
}

final class IdentityFound extends IdentityLookup {
  const IdentityFound({required this.identity});

  final SigningIdentity identity;
}

final class IdentityMissing extends IdentityLookup {
  const IdentityMissing({required this.reason});

  final String reason;
}
