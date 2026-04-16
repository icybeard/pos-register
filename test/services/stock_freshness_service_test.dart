import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/services/stock/stock_freshness_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  /// Seed the shared pull cursor as if the puller wrote it `ageFromNow` ago.
  Future<void> seedCursor(Duration ageFromNow, DateTime now) async {
    await db.into(db.syncCursorsTable).insertOnConflictUpdate(
          SyncCursorsTableCompanion.insert(
            targetTable: '__all__',
            cursor: 'ignored',
            updatedAt: now.subtract(ageFromNow),
          ),
        );
  }

  group('StockFreshnessService.current', () {
    test('returns unknown when no pull cursor exists yet', () async {
      final svc = StockFreshnessService(db);
      final snap = await svc.current();
      expect(snap.tier, StockFreshness.unknown);
      expect(snap.age, Duration.zero);
    });

    test('fresh when last pull < 60s ago', () async {
      final now = DateTime.utc(2026, 4, 15, 12);
      await seedCursor(const Duration(seconds: 30), now);
      final svc = StockFreshnessService(db, clock: () => now);
      final snap = await svc.current();
      expect(snap.tier, StockFreshness.fresh);
      expect(snap.age, const Duration(seconds: 30));
    });

    test('exactly 60s → stale (boundary is strict-less-than kStockFreshMaxAge)', () async {
      final now = DateTime.utc(2026, 4, 15, 12);
      await seedCursor(kStockFreshMaxAge, now); // exactly 60s
      final svc = StockFreshnessService(db, clock: () => now);
      expect((await svc.current()).tier, StockFreshness.stale);
    });

    test('stale when 60s ≤ age < 5min', () async {
      final now = DateTime.utc(2026, 4, 15, 12);
      await seedCursor(const Duration(minutes: 2), now);
      final svc = StockFreshnessService(db, clock: () => now);
      expect((await svc.current()).tier, StockFreshness.stale);
    });

    test('exactly 5min → outdated', () async {
      final now = DateTime.utc(2026, 4, 15, 12);
      await seedCursor(kStockStaleMaxAge, now); // exactly 5min
      final svc = StockFreshnessService(db, clock: () => now);
      expect((await svc.current()).tier, StockFreshness.outdated);
    });

    test('outdated when 10 min have passed', () async {
      final now = DateTime.utc(2026, 4, 15, 12);
      await seedCursor(const Duration(minutes: 10), now);
      final svc = StockFreshnessService(db, clock: () => now);
      final snap = await svc.current();
      expect(snap.tier, StockFreshness.outdated);
      expect(snap.age, const Duration(minutes: 10));
    });

    test('future-dated cursor (clock skew) → fresh (does not crash)', () async {
      final now = DateTime.utc(2026, 4, 15, 12);
      await seedCursor(const Duration(seconds: -30), now); // cursor is 30s in the future
      final svc = StockFreshnessService(db, clock: () => now);
      expect((await svc.current()).tier, StockFreshness.fresh);
    });

    test('a fresh pull flips the tier back to fresh', () async {
      final now = DateTime.utc(2026, 4, 15, 12);
      await seedCursor(const Duration(minutes: 10), now);
      final svc = StockFreshnessService(db, clock: () => now);
      expect((await svc.current()).tier, StockFreshness.outdated);

      // Puller just ran — seed a new cursor with age 0.
      await seedCursor(Duration.zero, now);
      expect((await svc.current()).tier, StockFreshness.fresh);
    });
  });

  group('StockFreshnessService.watch', () {
    test('emits current snapshot on subscribe, then re-emits on each tick', () async {
      final now = DateTime.utc(2026, 4, 15, 12);
      await seedCursor(const Duration(seconds: 30), now);

      final svc = StockFreshnessService(
        db,
        clock: () => now,
        pollInterval: const Duration(milliseconds: 30),
      );

      final emissions = <StockFreshness>[];
      final sub = svc.watch().listen((s) => emissions.add(s.tier));

      // Wait for 3 ticks worth of time
      await Future<void>.delayed(const Duration(milliseconds: 110));
      await sub.cancel();

      expect(emissions, isNotEmpty);
      expect(emissions.every((t) => t == StockFreshness.fresh), true);
      expect(emissions.length, greaterThanOrEqualTo(2),
          reason: 'initial emit + at least one poll tick');
    });

    test('cancelling the subscription stops the timer (no late emissions)', () async {
      final now = DateTime.utc(2026, 4, 15, 12);
      await seedCursor(const Duration(seconds: 5), now);

      final svc = StockFreshnessService(
        db,
        clock: () => now,
        pollInterval: const Duration(milliseconds: 10),
      );

      final emissions = <StockFreshness>[];
      final sub = svc.watch().listen((s) => emissions.add(s.tier));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await sub.cancel();

      final snapshotAfterCancel = emissions.length;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emissions.length, snapshotAfterCancel,
          reason: 'timer should be dead after cancel');
    });
  });
}
