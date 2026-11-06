# DayBook Threat Model & Security Posture

## 1. Executive Summary
DayBook is engineered with an **offline-first, zero-trust** security posture. It is designed to safeguard intimate personal reflections, financial transactions (bKash/cash/loans), contact networks, and daily activity logs against physical theft, forensic memory extraction, supply-chain tampering, and remote server compromise.

---

## 2. Assets & Sensitivity Classification

| Asset | Sensitivity | Storage Location | Protection Mechanism |
|---|---|---|---|
| Single Event Log (`entries`) | Tier 1 (Critical) | Local SQLite Database | SQLCipher AES-256 encrypted at rest |
| Master Encryption Key | Tier 1 (Critical) | Android Keystore | Hardware-backed TEE / StrongBox KeyStore |
| User Passphrase & PIN | Tier 1 (Critical) | Never Stored in Plaintext | PBKDF2-HMAC-SHA256 (100,000 iterations) |
| Money & Dhar Records | Tier 2 (High) | Local Database | Keystore-encrypted database tables |
| Student Records & Notes | Tier 2 (High) | Local Database | Keystore-encrypted database tables |
| AI Chat Context | Tier 2 (High) | Local Memory Vault | PII Redaction Engine (Auto-scrub card/passwords) |
| Cloud Sync Payloads | Tier 1 (Critical) | Remote PostgreSQL Store | Client-side AES-256-GCM ciphertext only |

---

## 3. Threat Actors & Adversary Profiles

1. **Physical Device Thief (Opportunistic)**: Snatching an unlocked or sleeping phone in public transit.
   - *Mitigation*: Biometric authentication with aggressive session timeout (1–5 mins). Pure OLED black lock screen overlay preventing screen recording and OS task snapshot caching (`FLAG_SECURE`).
2. **Forensic Investigator / Extractor (Targeted)**: Physical possession of device with USB debugging or file system extraction tools (Cellebrite, ADB backup).
   - *Mitigation*: Full SQLCipher database encryption. Key is never saved on external storage; hardware-backed Keystore does not export private key material.
3. **Malicious Cloud Host / Compromised Backend**: Adversary accessing NestJS backend PostgreSQL database.
   - *Mitigation*: Zero-knowledge ciphertext sync. The server only sees base64 opaque AES-256-GCM blobs. Even root DB access reveals zero user entries.
4. **Prompt Injection / Malicious AI Persona**: Malicious input in journal or clipboard attempting to trick the AI into executing unauthorized code or deleting data.
   - *Mitigation*: Fixed schema tool allowlist (14 tools max). Prohibited shell, eval, or raw SQL access. Strict confirmation gate for destructive calls. Full reversal undo stack.

---

## 4. STRIDE Threat Analysis

| Threat (STRIDE) | Attack Vector | Security Control |
|---|---|---|
| **S**poofing | Attacker impersonating user on device | BiometricPrompt (fingerprint / face) + hardware Keystore authentication |
| **T**ampering | Tampering with backup archive or local DB | AES-256-GCM authenticated encryption tag; SHA-256 checksum validation |
| **R**epudiation | User denies creating an entry | Single event log with monotonic timestamps and SHA-256 hash chains |
| **I**nformation Disclosure | Plaintext leaks in logs or backups | Redaction engine for credit cards and passwords; encrypted exports |
| **D**enial of Service | Battery killer OEM killing alarms | Foreground service with `START_STICKY`, `RECEIVE_BOOT_COMPLETED`, and battery exemption guide |
| **E**levation of Privilege | AI assistant attempting database drop | Tool execution sandbox; fixed allowlist; schema validation |

---

## 5. Cryptographic Standards & Algorithms

- **Symmetric Cipher**: AES-256-GCM (Galois/Counter Mode) with 96-bit random IV and 128-bit authentication tag.
- **Key Derivation Function**: PBKDF2 with HMAC-SHA256, 100,000 iterations, 32-byte cryptographically secure pseudorandom salt.
- **Database Engine**: SQLCipher 4.x with 4096-byte page size and HMAC-SHA512 page integrity checking.
- **Hardware Integration**: Android Keystore Provider with `KeyGenParameterSpec.Builder(PURPOSE_ENCRYPT | PURPOSE_DECRYPT)`.
