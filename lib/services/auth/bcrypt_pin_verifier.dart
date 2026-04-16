import 'package:bcrypt/bcrypt.dart';

import '../override/manager_override_service.dart';

/// Pure-Dart bcrypt [PinVerifier] that accepts hashes minted by .NET's
/// BCrypt.Net-Next (cost factor 10) and Go's `x/crypto/bcrypt.DefaultCost`.
/// Both produce the standard `$2a$` / `$2b$` crypt format, which the `bcrypt`
/// pub package — pointycastle-backed — verifies byte-compatibly.
///
/// Cost 10 is ~60–100ms per verify on a low-end Android, which is fine for
/// the override flow (one call per oversell) but would be prohibitive in a
/// test loop — use a stub `(pin, hash) => pin == hash` in unit tests.
///
/// Malformed hashes are swallowed as "not a match" so a corrupt drift row
/// can't crash the override dialog — the cashier just sees "wrong PIN" and
/// the admin gets a separate alert via central sync validation.
bool bcryptVerify(String pin, String storedHash) {
  try {
    return BCrypt.checkpw(pin, storedHash);
  } on Object {
    return false;
  }
}
