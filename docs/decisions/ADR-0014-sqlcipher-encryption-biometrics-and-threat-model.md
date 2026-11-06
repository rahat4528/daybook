# ADR-0014: SQLCipher On-Disk Encryption, PBKDF2 Key Derivation, Biometric Lock & Threat Model

## Status
Accepted

## Context
DayBook stores deeply personal thoughts, financial loans, relationships, academic grades, and mental health check-ins. A lost or compromised phone must not expose plaintext data under any circumstances. Furthermore, when cloud sync is utilized in Part 13, the remote backend must never receive entry plaintext.

Requirements:
1. **At-Rest Encryption**: All database files, single event log entries, and journal pages must be encrypted at rest using SQLCipher (AES-256-CBC) with hardware-backed key storage via Android Keystore.
2. **Key Derivation**: Passphrase-derived keys must use PBKDF2 with HMAC-SHA256, 100,000 iterations, and a cryptographically secure 32-byte salt.
3. **Biometric Guard**: Local device authentication via Android BiometricPrompt (`local_auth`) with auto-locking on background pause (customizable session timeout: immediate, 1 min, 5 min).
4. **Encrypted Backup Portability**: Exported database backups must use authenticated encryption (AES-256-GCM) with an initialization vector (IV) and authentication tag to prevent ciphertext tampering.

## Decisions

### 1. Cryptographic Primitives
- **Key Derivation**: PBKDF2-HMAC-SHA256, 100,000 iterations, 32-byte random salt.
- **Payload & Backup Cipher**: AES-256-GCM (Galois/Counter Mode) with 12-byte random IV and 128-bit authentication tag.
- **Local Master Key**: Stored exclusively in the Android Keystore using `flutter_secure_storage` with hardware-backed StrongBox / TEE enforcement where supported.

### 2. Zero-Knowledge Threat Model
The remote sync backend (`backend/`) operates strictly as an encrypted blob store:
- Clients encrypt payloads locally using user's sync secret before network transmission.
- The server stores `(user_id, device_id, epoch, iv_base64, ciphertext_base64)`.
- Even in the event of a full server database breach, the attacker obtains only opaque ciphertexts.

### 3. Biometric Lock Lifecycle
- When the app transitions to the background (`AppLifecycleState.paused` or `inactive`), a lock timestamp is recorded.
- If the elapsed time exceeds `lockTimeoutSeconds` (default 60s), `BiometricLockService` marks the session locked and overlays `SecurityLockScreen`.
- Authentication succeeds only upon a valid hardware biometric match or device security fallback (PIN/Pattern).

## Consequences
- Protects user privacy against physical device theft, root extraction, forensic file copying, and server-side data compromises.
- Conforms to high enterprise and medical-grade confidentiality standards.
