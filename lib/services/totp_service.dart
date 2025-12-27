import 'package:otp/otp.dart' as otp_lib;
import '../models/account.dart';

/// Generates TOTP codes for accounts.
/// Uses the battle-tested 'otp' package for RFC 6238 compliance.
class TOTPService {
  /// Generate the current TOTP code for an account
  String generateCode(Account account) {
    final algorithm = _mapAlgorithm(account.algorithm);

    return otp_lib.OTP.generateTOTPCodeString(
      account.secret,
      DateTime.now().millisecondsSinceEpoch,
      algorithm: algorithm,
      length: account.digits,
      interval: account.period,
      isGoogle: true, // Handles base32 padding correctly
    );
  }

  /// Get remaining seconds until the current code expires
  int getRemainingSeconds(Account account) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final elapsed = now % account.period;
    return account.period - elapsed;
  }

  /// Get progress (0.0 to 1.0) through the current period
  double getProgress(Account account) {
    final remaining = getRemainingSeconds(account);
    return remaining / account.period;
  }

  otp_lib.Algorithm _mapAlgorithm(Algorithm algo) {
    switch (algo) {
      case Algorithm.sha1:
        return otp_lib.Algorithm.SHA1;
      case Algorithm.sha256:
        return otp_lib.Algorithm.SHA256;
      case Algorithm.sha512:
        return otp_lib.Algorithm.SHA512;
    }
  }
}
