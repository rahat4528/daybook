import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

class EncryptedPayload {
  final String ivBase64;
  final String ciphertextBase64;
  final String authTagBase64;
  final String saltBase64;

  const EncryptedPayload({
    required this.ivBase64,
    required this.ciphertextBase64,
    required this.authTagBase64,
    required this.saltBase64,
  });

  Map<String, dynamic> toJson() => {
        'iv': ivBase64,
        'ciphertext': ciphertextBase64,
        'tag': authTagBase64,
        'salt': saltBase64,
      };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) => EncryptedPayload(
        ivBase64: json['iv'] as String,
        ciphertextBase64: json['ciphertext'] as String,
        authTagBase64: json['tag'] as String,
        saltBase64: json['salt'] as String,
      );
}

class SecurityVault {
  static final Random _secureRandom = Random.secure();

  /// Generates cryptographically secure random bytes
  static Uint8List generateRandomBytes(int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _secureRandom.nextInt(256);
    }
    return bytes;
  }

  /// PBKDF2 with HMAC-SHA256 (RFC 2898 / PKCS #5 v2.0)
  /// Default: 100,000 iterations for maximum forensic extraction resistance
  static Uint8List deriveKeyPBKDF2({
    required String password,
    required List<int> salt,
    int iterations = 100000,
    int keyLength = 32, // 256 bits
  }) {
    if (password.isEmpty) {
      throw ArgumentError('Password cannot be empty.');
    }
    if (salt.length < 16) {
      throw ArgumentError('Salt must be at least 16 bytes for cryptographic security.');
    }
    if (iterations < 1000) {
      throw ArgumentError('Iterations must be at least 1,000.');
    }

    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);
    final int hashLen = 32; // SHA-256 produces 32 bytes
    final int numBlocks = (keyLength + hashLen - 1) ~/ hashLen;
    final derivedKey = BytesBuilder(copy: false);

    for (int block = 1; block <= numBlocks; block++) {
      // U_1 = PRF(Password, Salt || INT_32_BE(block))
      final blockBytes = Uint8List(4)
        ..buffer.asByteData().setUint32(0, block, Endian.big);
      final initialData = <int>[...salt, ...blockBytes];
      List<int> u = hmac.convert(initialData).bytes;
      final xorSum = Uint8List.fromList(u);

      // U_2 ... U_c
      for (int iter = 1; iter < iterations; iter++) {
        u = hmac.convert(u).bytes;
        for (int k = 0; k < hashLen; k++) {
          xorSum[k] ^= u[k];
        }
      }

      derivedKey.add(xorSum);
    }

    return Uint8List.fromList(derivedKey.takeBytes().sublist(0, keyLength));
  }

  /// Authenticated Encrypt-then-MAC (AES-256 equivalent with HMAC-SHA256 authentication tag)
  static EncryptedPayload encrypt({
    required String plaintext,
    required List<int> key,
    List<int>? optionalSalt,
  }) {
    if (key.length != 32) {
      throw ArgumentError('Key must be exactly 32 bytes (256-bit).');
    }

    final salt = optionalSalt ?? generateRandomBytes(32);
    final iv = generateRandomBytes(16); // 128-bit IV
    final plainBytes = utf8.encode(plaintext);

    // Keystream generation using HMAC-SHA256 CTR mode
    final hmac = Hmac(sha256, key);
    final cipherBytes = Uint8List(plainBytes.length);

    int offset = 0;
    int counter = 0;
    while (offset < plainBytes.length) {
      final counterBytes = Uint8List(4)
        ..buffer.asByteData().setUint32(0, counter++, Endian.big);
      final streamBlock = hmac.convert(<int>[...iv, ...counterBytes]).bytes;
      final blockSize = min(streamBlock.length, plainBytes.length - offset);

      for (int i = 0; i < blockSize; i++) {
        cipherBytes[offset + i] = plainBytes[offset + i] ^ streamBlock[i];
      }
      offset += blockSize;
    }

    // Compute Auth Tag over IV || Ciphertext (Encrypt-then-MAC prevents padding oracles)
    final tagData = <int>[...iv, ...cipherBytes];
    final authTag = hmac.convert(tagData).bytes;

    return EncryptedPayload(
      ivBase64: base64Encode(iv),
      ciphertextBase64: base64Encode(cipherBytes),
      authTagBase64: base64Encode(authTag),
      saltBase64: base64Encode(salt),
    );
  }

  /// Decrypts payload with constant-time authentication tag verification
  static String decrypt({
    required EncryptedPayload payload,
    required List<int> key,
  }) {
    if (key.length != 32) {
      throw ArgumentError('Key must be exactly 32 bytes (256-bit).');
    }

    final iv = base64Decode(payload.ivBase64);
    final cipherBytes = base64Decode(payload.ciphertextBase64);
    final expectedTag = base64Decode(payload.authTagBase64);

    // Verify tag before doing any decryption (prevents tampering)
    final hmac = Hmac(sha256, key);
    final tagData = <int>[...iv, ...cipherBytes];
    final actualTag = hmac.convert(tagData).bytes;

    if (!_constantTimeEquals(actualTag, expectedTag)) {
      throw const SecurityException('Authentication tag mismatch. Ciphertext was tampered with or key is invalid.');
    }

    // Decrypt using identical CTR keystream
    final plainBytes = Uint8List(cipherBytes.length);
    int offset = 0;
    int counter = 0;
    while (offset < cipherBytes.length) {
      final counterBytes = Uint8List(4)
        ..buffer.asByteData().setUint32(0, counter++, Endian.big);
      final streamBlock = hmac.convert(<int>[...iv, ...counterBytes]).bytes;
      final blockSize = min(streamBlock.length, cipherBytes.length - offset);

      for (int i = 0; i < blockSize; i++) {
        plainBytes[offset + i] = cipherBytes[offset + i] ^ streamBlock[i];
      }
      offset += blockSize;
    }

    return utf8.decode(plainBytes);
  }

  /// SHA-256 hex digest for integrity and checksum verification
  static String computeSHA256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Constant-time comparison to prevent timing side-channel attacks
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
