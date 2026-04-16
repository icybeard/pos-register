import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/client_repository.dart';

void main() {
  late AppDatabase db;
  late ClientRepository repo;
  const tenantId = '11111111-1111-1111-1111-111111111111';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ClientRepository(db, tenantId: tenantId);
  });

  tearDown(() async {
    await db.close();
  });

  test('create inserts client with debt_limit + appends to outbox atomically', () async {
    final id = await repo.create(
      name: 'Иван Иванов',
      phone: '+77001112233',
      iin: '123456789012',
      debtLimitTiyin: 100000,
    );

    final c = await repo.getById(id);
    expect(c, isNotNull);
    expect(c!.name, 'Иван Иванов');
    expect(c.iin, '123456789012');
    expect(c.debtLimitTiyin, 100000);
    expect(c.isActive, true);

    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(1));
    expect(outbox.first.targetTable, 'clients');
    final payload = jsonDecode(outbox.first.payloadJson) as Map<String, dynamic>;
    expect(payload['debt_limit_tiyin'], 100000);
  });

  test('create with null debt_limit means no cap', () async {
    final id = await repo.create(name: 'Маша');
    final c = await repo.getById(id);
    expect(c!.debtLimitTiyin, isNull);
  });

  test('update changes debt_limit + appends update op', () async {
    final id = await repo.create(name: 'Алия', debtLimitTiyin: 50000);
    await repo.update(id: id, debtLimitTiyin: 200000);

    final c = await repo.getById(id);
    expect(c!.debtLimitTiyin, 200000);

    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(2));
    final payload = jsonDecode(outbox.last.payloadJson) as Map<String, dynamic>;
    expect(payload['debt_limit_tiyin'], 200000);
  });

  test('update soft-deletes via is_active=false', () async {
    final id = await repo.create(name: 'X');
    await repo.update(id: id, isActive: false);

    expect(await repo.all(), isEmpty);
    expect(await repo.all(includeInactive: true), hasLength(1));
  });

  test('update on missing id throws', () async {
    await expectLater(
      repo.update(id: 'not-a-real-id', name: 'x'),
      throwsStateError,
    );
  });

  test('cross-tenant rows are never returned', () async {
    await repo.create(name: 'Ours');
    final other = ClientRepository(db, tenantId: 'other-tenant');
    await other.create(name: 'Theirs');

    expect((await repo.all()).map((c) => c.name), ['Ours']);
    expect((await other.all()).map((c) => c.name), ['Theirs']);
  });
}
