import '../models/account.dart';

/// Parses otpauth:// URIs from QR codes.
///
/// Format: otpauth://totp/Label?secret=SECRET&issuer=Issuer&digits=6&period=30&algorithm=SHA1
///
/// Reference: https://github.com/google/google-authenticator/wiki/Key-Uri-Format
class OTPUriParser {
  /// Parse an otpauth:// URI into an Account.
  /// Returns null if the URI is invalid.
  static Account? parse(String uri, {String? folderId}) {
    try {
      final parsed = Uri.parse(uri);

      // Must be otpauth scheme
      if (parsed.scheme != 'otpauth') {
        return null;
      }

      // Must be totp type (we don't support hotp)
      if (parsed.host != 'totp') {
        return null;
      }

      // Extract label (path without leading slash)
      final label = Uri.decodeComponent(parsed.path.substring(1));

      // Parse label - can be "Issuer:Account" or just "Account"
      String name;
      String? issuerFromLabel;

      if (label.contains(':')) {
        final parts = label.split(':');
        issuerFromLabel = parts[0].trim();
        name = parts.sublist(1).join(':').trim();
      } else {
        name = label;
      }

      // Get query parameters
      final params = parsed.queryParameters;

      // Secret is required
      final secret = params['secret'];
      if (secret == null || secret.isEmpty) {
        return null;
      }

      // Issuer from param takes precedence over label
      final issuer = params['issuer'] ?? issuerFromLabel;

      // Optional parameters with defaults
      final digits = int.tryParse(params['digits'] ?? '') ?? 6;
      final period = int.tryParse(params['period'] ?? '') ?? 30;

      final algorithmStr = params['algorithm']?.toUpperCase() ?? 'SHA1';
      final algorithm = _parseAlgorithm(algorithmStr);

      return Account.create(
        name: name,
        issuer: issuer,
        secret: secret,
        folderId: folderId,
        digits: digits,
        period: period,
        algorithm: algorithm,
      );
    } catch (e) {
      return null;
    }
  }

  static Algorithm _parseAlgorithm(String str) {
    switch (str) {
      case 'SHA256':
        return Algorithm.sha256;
      case 'SHA512':
        return Algorithm.sha512;
      case 'SHA1':
      default:
        return Algorithm.sha1;
    }
  }

  /// Validate if a string is a valid otpauth:// URI
  static bool isValid(String uri) {
    return parse(uri) != null;
  }
}
