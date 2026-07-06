import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/cashier_repository.dart';
import 'package:pos_system/services/auth/local_auth_service.dart';

void main() {
  late AppDatabase db;
  late LocalAuthService service;
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const storeId = '22222222-2222-2222-2222-222222222222';
  const realTenantId = '33333333-3333-3333-3333-333333333333';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = LocalAuthService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('createOwner → listCashiers exposes PinScreen-shaped maps', () async {
    expect(await service.hasAnyUser(tenantId), isFalse);

    await service.createOwner(
      tenantId: tenantId,
      storeId: storeId,
      name: 'Адиль',
      pin: '1234',
    );

    expect(await service.hasAnyUser(tenantId), isTrue);
    final cashiers = await service.listCashiers(tenantId);
    expect(cashiers, hasLength(1));
    // PascalCase keys — the contract PinScreen renders (spec 03 R1).
    expect(cashiers.first['Name'], 'Адиль');
    expect(cashiers.first['Role'], 'owner');
    expect(cashiers.first['ID'], isNotEmpty);
  });

  test('verifyPinByName: correct PIN → row, wrong PIN/name → null', () async {
    await service.createOwner(
      tenantId: tenantId,
      storeId: storeId,
      name: 'Адиль',
      pin: '1234',
    );

    final ok = await service.verifyPinByName(
        tenantId: tenantId, name: 'Адиль', pin: '1234');
    expect(ok, isNotNull);
    expect(ok!.role, 'owner');

    expect(
        await service.verifyPinByName(
            tenantId: tenantId, name: 'Адиль', pin: '0000'),
        isNull);
    expect(
        await service.verifyPinByName(
            tenantId: tenantId, name: 'Кто-то', pin: '1234'),
        isNull);
  });

  test('adoptTenant re-stamps rows and clears the outbox', () async {
    await service.createOwner(
      tenantId: tenantId,
      storeId: storeId,
      name: 'Адиль',
      pin: '1234',
    );
    // The repository writes to sync_outbox atomically — standalone writes
    // accumulate entries that must NOT survive linking (from-link-forward).
    final outboxBefore = await db
        .customSelect('SELECT count(*) AS c FROM sync_outbox')
        .getSingle();
    expect(outboxBefore.data['c'], greaterThan(0));

    await service.adoptTenant(
        fromTenantId: tenantId, toTenantId: realTenantId);

    // Old tenant sees nothing; the real tenant owns the rows now.
    expect(await service.hasAnyUser(tenantId), isFalse);
    expect(await service.hasAnyUser(realTenantId), isTrue);
    final adopted = CashierRepository(db, tenantId: realTenantId);
    final rows = await adopted.all();
    expect(rows.single.name, 'Адиль');

    final outboxAfter = await db
        .customSelect('SELECT count(*) AS c FROM sync_outbox')
        .getSingle();
    expect(outboxAfter.data['c'], 0);
  });
}
