import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/cashier_repository.dart';
import 'package:pos_system/services/override/manager_override_service.dart';

void main() {
  late AppDatabase db;
  late CashierRepository cashiers;
  late ManagerOverrideService svc;
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const storeId = '22222222-2222-2222-2222-222222222222';

  // Stub verifier: treats the stored "hash" as the literal PIN. Lets tests
  // skip bcrypt's per-call cost and reason about "wrong PIN" purely from the
  // service logic.
  bool plainVerify(String pin, String hash) => pin == hash;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cashiers = CashierRepository(db, tenantId: tenantId);
    svc = ManagerOverrideService(cashiers, verifier: plainVerify);
  });

  tearDown(() async => db.close());

  Future<void> seed({
    required String login,
    required String role,
    String pin = '1234',
    bool isActive = true,
  }) async {
    await cashiers.create(
      storeId: storeId,
      name: login,
      login: login,
      pinHash: pin, // stub verifier treats pin as its own hash
      role: role,
      isActive: isActive,
    );
  }

  group('happy paths', () {
    test('manager with correct PIN → ok, returns the user', () async {
      await seed(login: 'masha', role: 'manager', pin: '9999');
      final out = await svc.verify(login: 'masha', pin: '9999');
      expect(out.result, OverrideResult.ok);
      expect(out.isOk, true);
      expect(out.user?.login, 'masha');
    });

    test('senior_cashier with correct PIN → ok', () async {
      await seed(login: 'aidar', role: 'senior_cashier');
      final out = await svc.verify(login: 'aidar', pin: '1234');
      expect(out.result, OverrideResult.ok);
    });

    test('admin with correct PIN → ok', () async {
      await seed(login: 'adm', role: 'admin');
      final out = await svc.verify(login: 'adm', pin: '1234');
      expect(out.result, OverrideResult.ok);
    });

    test('owner with correct PIN → ok (owner overrides everything)', () async {
      await seed(login: 'owner', role: 'owner');
      final out = await svc.verify(login: 'owner', pin: '1234');
      expect(out.result, OverrideResult.ok);
    });
  });

  group('role gate', () {
    test('plain cashier with correct PIN → insufficientRole (cashiers cant override their own shortage)',
        () async {
      await seed(login: 'ivan', role: 'cashier');
      final out = await svc.verify(login: 'ivan', pin: '1234');
      expect(out.result, OverrideResult.insufficientRole);
      expect(out.user?.login, 'ivan',
          reason: 'user returned so UI can show "X is a cashier, ask a manager"');
    });

    test('unknown role → insufficientRole (fail-closed)', () async {
      await seed(login: 'weirdrole', role: 'intern');
      final out = await svc.verify(login: 'weirdrole', pin: '1234');
      expect(out.result, OverrideResult.insufficientRole);
    });
  });

  group('authentication failures', () {
    test('wrong PIN → wrongPin, no user payload', () async {
      await seed(login: 'masha', role: 'manager', pin: '9999');
      final out = await svc.verify(login: 'masha', pin: 'WRONG');
      expect(out.result, OverrideResult.wrongPin);
      expect(out.user, isNull);
    });

    test('unknown login → notFound', () async {
      final out = await svc.verify(login: 'ghost', pin: '1234');
      expect(out.result, OverrideResult.notFound);
    });

    test('empty login → notFound (short-circuits; no DB hit)', () async {
      final out = await svc.verify(login: '', pin: '1234');
      expect(out.result, OverrideResult.notFound);
    });

    test('empty pin → notFound (short-circuits)', () async {
      await seed(login: 'masha', role: 'manager');
      final out = await svc.verify(login: 'masha', pin: '');
      expect(out.result, OverrideResult.notFound);
    });

    test('login is case-insensitive + trimmed (cashier types "  MASHA ")', () async {
      await seed(login: 'masha', role: 'manager');
      final out = await svc.verify(login: '  MASHA ', pin: '1234');
      expect(out.result, OverrideResult.ok);
    });
  });

  group('edge cases', () {
    test('deactivated manager → inactive (user returned so UI can explain)', () async {
      await seed(login: 'former', role: 'manager', isActive: false);
      final out = await svc.verify(login: 'former', pin: '1234');
      expect(out.result, OverrideResult.inactive);
      expect(out.user?.login, 'former');
    });

    test('user with no PIN hash (owner on web-only) → wrongPin', () async {
      // Insert directly to bypass CashierRepository.create's required pinHash
      final id = await cashiers.create(
        storeId: storeId,
        name: 'webowner',
        login: 'webowner',
        pinHash: '', // empty — can't verify
        role: 'owner',
      );
      expect(id, isNotEmpty);

      final out = await svc.verify(login: 'webowner', pin: 'anything');
      expect(out.result, OverrideResult.wrongPin);
    });

    test('cross-tenant user is invisible (tenantId scoping via repository)', () async {
      await seed(login: 'masha', role: 'manager');
      final otherRepo = CashierRepository(db, tenantId: 'other-tenant');
      final otherSvc = ManagerOverrideService(otherRepo, verifier: plainVerify);

      final out = await otherSvc.verify(login: 'masha', pin: '1234');
      expect(out.result, OverrideResult.notFound);
    });

    test('result order: role-gate is checked BEFORE is_active', () async {
      // A deactivated plain cashier should report insufficientRole, not inactive —
      // the role gate is the structural block, inactive is a secondary concern.
      await seed(login: 'former', role: 'cashier', isActive: false);
      final out = await svc.verify(login: 'former', pin: '1234');
      expect(out.result, OverrideResult.insufficientRole,
          reason: 'role gate precedes the is_active check by design');
    });

    test('verifier is only called when the user exists (avoids PIN leak timing)', () async {
      // Track calls to the verifier; a lookup for an unknown login must not invoke it.
      var calls = 0;
      final countingSvc = ManagerOverrideService(cashiers, verifier: (p, h) {
        calls++;
        return p == h;
      });

      await countingSvc.verify(login: 'ghost', pin: '1234');
      expect(calls, 0, reason: 'unknown login short-circuits before PIN verify');

      await seed(login: 'masha', role: 'manager');
      await countingSvc.verify(login: 'masha', pin: '1234');
      expect(calls, 1, reason: 'known login triggers exactly one verifier call');
    });
  });
}
