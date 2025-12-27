import 'dart:convert';
import 'dart:typed_data';
import '../models/account.dart';

/// Generates Google Authenticator compatible migration QR codes.
/// Format: otpauth-migration://offline?data=<base64-encoded-protobuf>
class ExportMigration {
  /// Generate a migration URI for a list of accounts
  static String generateMigrationUri(List<Account> accounts) {
    final payload = _buildProtobuf(accounts);
    final base64Data = base64Encode(payload);
    return 'otpauth-migration://offline?data=${Uri.encodeComponent(base64Data)}';
  }

  /// Generate individual otpauth:// URIs (simpler, more compatible)
  static List<String> generateIndividualUris(List<Account> accounts) {
    return accounts.map((account) {
      final label = account.issuer != null
          ? '${Uri.encodeComponent(account.issuer!)}:${Uri.encodeComponent(account.name)}'
          : Uri.encodeComponent(account.name);

      final params = <String, String>{
        'secret': account.secret,
        'digits': account.digits.toString(),
        'period': account.period.toString(),
        'algorithm': account.algorithm.name.toUpperCase(),
      };

      if (account.issuer != null) {
        params['issuer'] = account.issuer!;
      }

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      return 'otpauth://totp/$label?$queryString';
    }).toList();
  }

  /// Build protobuf payload for migration
  static Uint8List _buildProtobuf(List<Account> accounts) {
    final buffer = <int>[];

    for (final account in accounts) {
      final otpParams = _buildOtpParameters(account);
      // Field 1, wire type 2 (length-delimited)
      buffer.add((1 << 3) | 2);
      buffer.addAll(_encodeVarint(otpParams.length));
      buffer.addAll(otpParams);
    }

    return Uint8List.fromList(buffer);
  }

  /// Build a single OTP parameters message
  static Uint8List _buildOtpParameters(Account account) {
    final buffer = <int>[];

    // Field 1: secret (bytes)
    final secretBytes = _base32Decode(account.secret);
    buffer.add((1 << 3) | 2);
    buffer.addAll(_encodeVarint(secretBytes.length));
    buffer.addAll(secretBytes);

    // Field 2: name (string)
    final nameBytes = utf8.encode(account.issuer != null
        ? '${account.issuer}:${account.name}'
        : account.name);
    buffer.add((2 << 3) | 2);
    buffer.addAll(_encodeVarint(nameBytes.length));
    buffer.addAll(nameBytes);

    // Field 3: issuer (string)
    if (account.issuer != null) {
      final issuerBytes = utf8.encode(account.issuer!);
      buffer.add((3 << 3) | 2);
      buffer.addAll(_encodeVarint(issuerBytes.length));
      buffer.addAll(issuerBytes);
    }

    // Field 4: algorithm (enum) - 1=SHA1, 2=SHA256, 3=SHA512
    buffer.add((4 << 3) | 0);
    buffer.add(_algorithmToInt(account.algorithm));

    // Field 5: digits (enum) - 1=6, 2=8
    buffer.add((5 << 3) | 0);
    buffer.add(account.digits == 8 ? 2 : 1);

    // Field 6: type (enum) - 2=TOTP
    buffer.add((6 << 3) | 0);
    buffer.add(2);

    return Uint8List.fromList(buffer);
  }

  static int _algorithmToInt(Algorithm algo) {
    switch (algo) {
      case Algorithm.sha1:
        return 1;
      case Algorithm.sha256:
        return 2;
      case Algorithm.sha512:
        return 3;
    }
  }

  static List<int> _encodeVarint(int value) {
    final result = <int>[];
    while (value > 127) {
      result.add((value & 0x7F) | 0x80);
      value >>= 7;
    }
    result.add(value);
    return result;
  }

  /// Decode base32 string to bytes
  static Uint8List _base32Decode(String input) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final cleaned = input.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');

    final result = <int>[];
    int buffer = 0;
    int bitsLeft = 0;

    for (final char in cleaned.codeUnits) {
      final value = alphabet.indexOf(String.fromCharCode(char));
      if (value < 0) continue;

      buffer = (buffer << 5) | value;
      bitsLeft += 5;

      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        result.add((buffer >> bitsLeft) & 0xFF);
      }
    }

    return Uint8List.fromList(result);
  }
}
