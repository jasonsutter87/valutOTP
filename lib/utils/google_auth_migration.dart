import 'dart:convert';
import 'dart:typed_data';
import '../models/account.dart';

/// Parses Google Authenticator migration QR codes.
///
/// Format: otpauth-migration://offline?data=<base64-encoded-protobuf>
///
/// The protobuf format is:
/// message MigrationPayload {
///   repeated OtpParameters otp_parameters = 1;
/// }
/// message OtpParameters {
///   bytes secret = 1;
///   string name = 2;
///   string issuer = 3;
///   Algorithm algorithm = 4;  // 1=SHA1, 2=SHA256, 3=SHA512
///   DigitCount digits = 5;    // 1=6 digits, 2=8 digits
///   OtpType type = 6;         // 1=HOTP, 2=TOTP
/// }
class GoogleAuthMigration {
  /// Parse a Google Authenticator migration URI
  /// Returns a list of accounts, or empty list if parsing fails
  static List<Account> parse(String uri, {String? folderId}) {
    try {
      if (!uri.startsWith('otpauth-migration://')) {
        return [];
      }

      final parsed = Uri.parse(uri);
      final data = parsed.queryParameters['data'];
      if (data == null) return [];

      // Decode base64
      final bytes = base64Decode(data);

      // Parse protobuf manually (simple implementation)
      return _parseProtobuf(bytes, folderId: folderId);
    } catch (e) {
      return [];
    }
  }

  /// Check if a URI is a Google Authenticator migration URI
  static bool isMigrationUri(String uri) {
    return uri.startsWith('otpauth-migration://');
  }

  /// Parse the protobuf payload
  static List<Account> _parseProtobuf(Uint8List bytes, {String? folderId}) {
    final accounts = <Account>[];
    var offset = 0;

    while (offset < bytes.length) {
      // Read field tag
      final tag = _readVarint(bytes, offset);
      offset = tag.newOffset;

      final fieldNumber = tag.value >> 3;
      final wireType = tag.value & 0x7;

      if (fieldNumber == 1 && wireType == 2) {
        // Length-delimited: otp_parameters
        final length = _readVarint(bytes, offset);
        offset = length.newOffset;

        final otpBytes = bytes.sublist(offset, offset + length.value);
        offset += length.value;

        final account = _parseOtpParameters(otpBytes, folderId: folderId);
        if (account != null) {
          accounts.add(account);
        }
      } else {
        // Skip unknown fields
        offset = _skipField(bytes, offset, wireType);
      }
    }

    return accounts;
  }

  /// Parse a single OTP parameters message
  static Account? _parseOtpParameters(Uint8List bytes, {String? folderId}) {
    var offset = 0;
    Uint8List? secret;
    String? name;
    String? issuer;
    Algorithm algorithm = Algorithm.sha1;
    int digits = 6;
    bool isTotp = true;

    while (offset < bytes.length) {
      final tag = _readVarint(bytes, offset);
      offset = tag.newOffset;

      final fieldNumber = tag.value >> 3;
      final wireType = tag.value & 0x7;

      switch (fieldNumber) {
        case 1: // secret (bytes)
          if (wireType == 2) {
            final length = _readVarint(bytes, offset);
            offset = length.newOffset;
            secret = bytes.sublist(offset, offset + length.value);
            offset += length.value;
          }
          break;
        case 2: // name (string)
          if (wireType == 2) {
            final length = _readVarint(bytes, offset);
            offset = length.newOffset;
            name = utf8.decode(bytes.sublist(offset, offset + length.value));
            offset += length.value;
          }
          break;
        case 3: // issuer (string)
          if (wireType == 2) {
            final length = _readVarint(bytes, offset);
            offset = length.newOffset;
            issuer = utf8.decode(bytes.sublist(offset, offset + length.value));
            offset += length.value;
          }
          break;
        case 4: // algorithm (enum)
          if (wireType == 0) {
            final value = _readVarint(bytes, offset);
            offset = value.newOffset;
            algorithm = _parseAlgorithm(value.value);
          }
          break;
        case 5: // digits (enum)
          if (wireType == 0) {
            final value = _readVarint(bytes, offset);
            offset = value.newOffset;
            digits = value.value == 2 ? 8 : 6;
          }
          break;
        case 6: // type (enum)
          if (wireType == 0) {
            final value = _readVarint(bytes, offset);
            offset = value.newOffset;
            isTotp = value.value != 1; // 1 = HOTP, 2 = TOTP
          }
          break;
        default:
          offset = _skipField(bytes, offset, wireType);
      }
    }

    // We only support TOTP
    if (!isTotp || secret == null || name == null) {
      return null;
    }

    // Convert secret bytes to base32
    final base32Secret = _bytesToBase32(secret);

    // Parse name - might be "issuer:account" format
    String accountName = name;
    String? parsedIssuer = issuer;

    if (name.contains(':')) {
      final parts = name.split(':');
      if (parsedIssuer == null || parsedIssuer.isEmpty) {
        parsedIssuer = parts[0].trim();
      }
      accountName = parts.sublist(1).join(':').trim();
    }

    return Account.create(
      name: accountName,
      issuer: parsedIssuer,
      secret: base32Secret,
      folderId: folderId,
      digits: digits,
      algorithm: algorithm,
    );
  }

  static Algorithm _parseAlgorithm(int value) {
    switch (value) {
      case 2:
        return Algorithm.sha256;
      case 3:
        return Algorithm.sha512;
      default:
        return Algorithm.sha1;
    }
  }

  /// Read a varint from bytes
  static ({int value, int newOffset}) _readVarint(Uint8List bytes, int offset) {
    int value = 0;
    int shift = 0;

    while (offset < bytes.length) {
      final byte = bytes[offset];
      offset++;
      value |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }

    return (value: value, newOffset: offset);
  }

  /// Skip a field based on wire type
  static int _skipField(Uint8List bytes, int offset, int wireType) {
    switch (wireType) {
      case 0: // Varint
        final result = _readVarint(bytes, offset);
        return result.newOffset;
      case 1: // 64-bit
        return offset + 8;
      case 2: // Length-delimited
        final length = _readVarint(bytes, offset);
        return length.newOffset + length.value;
      case 5: // 32-bit
        return offset + 4;
      default:
        return bytes.length; // Unknown, skip to end
    }
  }

  /// Convert bytes to base32 string
  static String _bytesToBase32(Uint8List bytes) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final result = StringBuffer();

    int buffer = 0;
    int bitsLeft = 0;

    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;

      while (bitsLeft >= 5) {
        bitsLeft -= 5;
        result.write(alphabet[(buffer >> bitsLeft) & 0x1F]);
      }
    }

    if (bitsLeft > 0) {
      result.write(alphabet[(buffer << (5 - bitsLeft)) & 0x1F]);
    }

    return result.toString();
  }
}
