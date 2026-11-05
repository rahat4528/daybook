# ADR-0002: Encrypted Storage Architecture with SQLCipher and Android Keystore

## Status
Accepted

## Context
DayBook stores deeply intimate personal data: daily journal pages, financial ledgers, debt obligations (dhar), personal memories, relationship notes, and habit logs. Offline-first local databases must be protected at rest against physical extraction, rooted devices, and backup inspection.

## Decision
1. **Database Engine**: Drift on SQLite utilizing **SQLCipher** (AES-256 encryption in CBC mode with PBKDF2/Argon2 key derivation).
2. **Key Storage Strategy**:
   - The database passkey is generated at initial launch as a cryptographically secure 256-bit random byte array (`Random.secure()`).
   - The passkey is stored in `EncryptedSharedPreferences` / `flutter_secure_storage`, backed by an Android Keystore master key (`AndroidKeyStore` provider).
   - On hardware supporting StrongBox Keymaster or Trusted Execution Environment (TEE), hardware-backed key isolation is requested automatically.
3. **Database Key Rotation**: A master backup mechanism allows exporting the encrypted database re-encrypted with a user-chosen Argon2id passphrase.

## Consequences
- No unencrypted SQLite plaintext exists on device storage.
- Even if device files are inspected via ADB or disk imaging, the database cannot be decrypted without the hardware-bound Keystore entry.
- Minimal performance overhead (<3-5% query latency impact on SQLite operations).
