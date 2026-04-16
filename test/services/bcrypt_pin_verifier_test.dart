import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/services/auth/bcrypt_pin_verifier.dart';

void main() {
  // Generate hashes at test-setup time with cost 10 (same as BCrypt.Net
  // `workFactor: 10` on the server). Round-trip hash→verify is what we'd
  // get off the wire after central mints and syncs a PIN hash.
  //
  // Cost 10 is ~60ms per call on a laptop, so we generate once per suite.
  late final String hash1234;
  late final String hash9999;

  setUpAll(() {
    hash1234 = BCrypt.hashpw('1234', BCrypt.gensalt(logRounds: 10));
    hash9999 = BCrypt.hashpw('9999', BCrypt.gensalt(logRounds: 10));
  });

  test('accepts correct PIN against a cost-10 bcrypt hash', () {
    expect(bcryptVerify('1234', hash1234), isTrue);
    expect(bcryptVerify('9999', hash9999), isTrue);
  });

  test('rejects wrong PIN against a valid hash', () {
    expect(bcryptVerify('0000', hash1234), isFalse);
    expect(bcryptVerify('1234', hash9999), isFalse);
    expect(bcryptVerify('', hash1234), isFalse);
  });

  test('rejects malformed hash without throwing', () {
    expect(bcryptVerify('1234', ''), isFalse);
    expect(bcryptVerify('1234', 'not-a-bcrypt-hash'), isFalse);
    expect(bcryptVerify('1234', r'$2a$10$tooshort'), isFalse);
  });

  test(r'verifies both $2a$ and $2b$ prefix variants (.NET & OpenBSD fork)', () {
    // BCrypt.Net-Next defaults to the $2a$ prefix; some deployments use $2b$
    // (the OpenBSD canonicalised form). Both are the same algorithm — our
    // verifier must not distinguish. We generate one of each at runtime and
    // assert the round-trip holds for both.
    final twoA = BCrypt.hashpw('1234', r'$2a$10$DCq7YPn5Rq63x1Lad4cll.');
    final twoB = BCrypt.hashpw('1234', r'$2b$10$DCq7YPn5Rq63x1Lad4cll.');
    expect(twoA.startsWith(r'$2a$10$'), isTrue);
    expect(twoB.startsWith(r'$2b$10$'), isTrue);
    expect(bcryptVerify('1234', twoA), isTrue);
    expect(bcryptVerify('1234', twoB), isTrue);
    expect(bcryptVerify('0000', twoA), isFalse);
    expect(bcryptVerify('0000', twoB), isFalse);
  });
}
