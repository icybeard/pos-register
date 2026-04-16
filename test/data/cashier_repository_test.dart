import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/cashier_repository.dart';

void main() {
  late AppDatabase db;
  late CashierRepository repo;
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const storeId = '22222222-2222-2222-2222-222222222222';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CashierRepository(db, tenantId: tenantId);
  });

  tearDown(() async {
    await db.close();
  });

  test('create inserts user + appends insert to outbox atomically', () async {
    final id = await repo.create(
      storeId: storeId,
      name: 'Иван',
      login: 'ivan',
      pinHash: 'bcrypt-hash-stub',
      role: 'cashier',
    );

    final user = await repo.getById(id);
    expect(user, isNotNull);
    expect(user!.name, 'Иван');
    expect(user.login, 'ivan');
    expect(user.role, 'cashier');
    expect(user.isActive, true);

    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(1));
    expect(outbox.first.targetTable, 'users');
    expect(outbox.first.op, 'insert');
    expect(outbox.first.uuid, id);
    final payload = jsonDecode(outbox.first.payloadJson) as Map<String, dynamic>;
    expect(payload['name'], 'Иван');
    expect(payload['role'], 'cashier');
  });

  test('create with explicit id preserves it', () async {
    const explicit = '33333333-3333-3333-3333-333333333333';
    final id = await repo.create(
      id: explicit,
      storeId: storeId,
      name: 'Pre-assigned',
      login: 'preid',
      pinHash: 'h',
      role: 'cashier',
    );
    expect(id, explicit);
    expect((await repo.getById(explicit))!.id, explicit);
  });

  test('findByLogin finds only within the current tenant', () async {
    await repo.create(storeId: storeId, name: 'A', login: 'alice', pinHash: 'h', role: 'cashier');

    // Insert a row under a DIFFERENT tenant directly to prove scope.
    await db.into(db.usersTable).insert(
          UsersTableCompanion.insert(
            id: 'other-tenant-user',
            tenantId: '99999999-9999-9999-9999-999999999999',
            name: 'Other Alice',
            role: 'cashier',
            login: const Value('alice'),
            pinHash: const Value('h'),
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

    final found = await repo.findByLogin('alice');
    expect(found, isNotNull);
    expect(found!.name, 'A');
  });

  test('update changes mutable fields + appends update op', () async {
    final id = await repo.create(
      storeId: storeId, name: 'Old', login: 'u', pinHash: 'h', role: 'cashier',
    );

    await repo.update(id: id, name: 'New', role: 'senior_cashier', isActive: false);

    final updated = await repo.getById(id);
    expect(updated!.name, 'New');
    expect(updated.role, 'senior_cashier');
    expect(updated.isActive, false);

    final outbox = await (db.select(db.syncOutboxTable)
          ..where((t) => t.op.equals('update')))
        .get();
    expect(outbox, hasLength(1));
    expect(outbox.first.uuid, id);
  });

  test('update throws when cashier not found', () async {
    expect(
      () => repo.update(id: 'missing-id', name: 'x'),
      throwsStateError,
    );
  });

  test('resetPinHash updates pin_hash + queues sync', () async {
    final id = await repo.create(
      storeId: storeId, name: 'A', login: 'a', pinHash: 'old-hash', role: 'cashier',
    );
    await repo.resetPinHash(id, 'new-hash');

    final row = await repo.getById(id);
    expect(row!.pinHash, 'new-hash');

    final outbox = await (db.select(db.syncOutboxTable)
          ..where((t) => t.op.equals('update') & t.uuid.equals(id)))
        .get();
    expect(outbox, hasLength(1));
    final payload = jsonDecode(outbox.first.payloadJson) as Map<String, dynamic>;
    expect(payload['pin_hash_rotated'], true);
    // Note: actual hash NEVER travels in outbox payload — central rotates independently.
    expect(payload.containsKey('pin_hash'), false);
  });

  test('watchAll emits after create', () async {
    final emitted = <List<UserRow>>[];
    final sub = repo.watchAll().listen(emitted.add);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await repo.create(
      storeId: storeId, name: 'B', login: 'b', pinHash: 'h', role: 'cashier',
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await sub.cancel();

    expect(emitted, isNotEmpty);
    expect(emitted.last, hasLength(1));
    expect(emitted.last.first.name, 'B');
  });

  test('watchAll filters by storeId when provided', () async {
    await repo.create(storeId: storeId, name: 'In-store', login: 'in', pinHash: 'h', role: 'cashier');
    await repo.create(
      storeId: '44444444-4444-4444-4444-444444444444',
      name: 'Other-store', login: 'out', pinHash: 'h', role: 'cashier',
    );

    final emitted = <List<UserRow>>[];
    final sub = repo.watchAll(storeId: storeId).listen(emitted.add);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await sub.cancel();

    expect(emitted.last, hasLength(1));
    expect(emitted.last.first.name, 'In-store');
  });

  test('watchAll hides inactive rows by default', () async {
    final id = await repo.create(
      storeId: storeId, name: 'Active', login: 'a', pinHash: 'h', role: 'cashier',
    );
    await repo.update(id: id, isActive: false);

    final visible = await repo.all();
    expect(visible, isEmpty);

    final withInactive = await repo.all(includeInactive: true);
    expect(withInactive, hasLength(1));
    expect(withInactive.first.isActive, false);
  });

  test('cross-tenant isolation — repo scoped to its tenantId', () async {
    await repo.create(storeId: storeId, name: 'mine', login: 'm', pinHash: 'h', role: 'cashier');
    // Another repo for another tenant
    final otherRepo = CashierRepository(db, tenantId: '99999999-9999-9999-9999-999999999999');
    await otherRepo.create(
      storeId: storeId, name: 'theirs', login: 't', pinHash: 'h', role: 'cashier',
    );

    expect((await repo.all()).map((u) => u.name), ['mine']);
    expect((await otherRepo.all()).map((u) => u.name), ['theirs']);
  });
}
