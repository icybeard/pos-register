import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/feature_flags.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/product_repository.dart';
import 'package:pos_system/services/api_client.dart';
import 'package:pos_system/services/products/product_catalog_service.dart';

void main() {
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const storeA = '22222222-2222-2222-2222-222222222222';
  const storeB = '33333333-3333-3333-3333-333333333333';

  group('DriftProductCatalogService', () {
    late AppDatabase db;
    late ProductRepository repo;
    late DriftProductCatalogService svc;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = ProductRepository(db, tenantId: tenantId);
      svc = DriftProductCatalogService(repo);
    });

    tearDown(() async {
      await db.close();
    });

    test('list returns canonical entries normalized from drift rows', () async {
      await repo.create(
        name: 'Coca-Cola',
        barcodeGtin: '4870001234567',
        salePriceTiyin: 25000,
        purchasePriceTiyin: 15000,
        vatRate: 12,
      );

      final entries = await svc.list();
      expect(entries, hasLength(1));
      expect(entries.first.name, 'Coca-Cola');
      expect(entries.first.barcodeGtin, '4870001234567');
      expect(entries.first.salePriceTiyin, 25000);
      expect(entries.first.vatRate, 12);
      expect(entries.first.isActive, true);
    });

    test('list with includeInactive=false hides soft-deleted', () async {
      final id = await repo.create(
        name: 'Old',
        salePriceTiyin: 1,
        purchasePriceTiyin: 1,
      );
      await repo.update(id: id, isActive: false);

      expect(await svc.list(), isEmpty);
      expect(await svc.list(includeInactive: true), hasLength(1));
    });

    test('list store-scoped includes tenant-wide rows', () async {
      await repo.create(storeId: null, name: 'Tenant-wide', salePriceTiyin: 1, purchasePriceTiyin: 1);
      await repo.create(storeId: storeA, name: 'Only-A', salePriceTiyin: 1, purchasePriceTiyin: 1);
      await repo.create(storeId: storeB, name: 'Only-B', salePriceTiyin: 1, purchasePriceTiyin: 1);

      final forA = await svc.list(storeId: storeA);
      expect(forA.map((e) => e.name), containsAll(['Tenant-wide', 'Only-A']));
      expect(forA.map((e) => e.name), isNot(contains('Only-B')));
    });

    test('findByBarcode returns the entry, including inactive', () async {
      final id = await repo.create(
        name: 'Discontinued',
        barcodeGtin: '4870000099999',
        salePriceTiyin: 1,
        purchasePriceTiyin: 1,
      );
      await repo.update(id: id, isActive: false);

      final hit = await svc.findByBarcode('4870000099999');
      expect(hit, isNotNull);
      expect(hit!.isActive, false);
    });

    test('findByBarcode returns null on miss', () async {
      expect(await svc.findByBarcode('0000000000000'), isNull);
    });
  });

  group('LegacyApiProductCatalogService', () {
    test('list normalises Go PascalCase row shape', () async {
      final api = _FakeApiClient(
        listResponse: {
          'products': [
            {
              'ID': 'p-1',
              'Name': 'Хлеб',
              'NameKZ': 'Нан',
              'BarcodeGTIN': '4870000000001',
              'NTIN': null,
              'SalePrice': 18000,
              'SaleUnit': 'pcs',
              'IsWeighted': false,
              'VATRate': 12,
              'IsActive': true,
            },
            {
              'ID': 'p-2',
              'Name': 'Молоко',
              'BarcodeGTIN': '4870000000002',
              'SalePrice': 49900,
              'SaleUnit': 'pcs',
              'IsWeighted': false,
              'VATRate': 0,
              'IsActive': false,
            },
          ],
        },
      );
      final svc = LegacyApiProductCatalogService(api);

      final entries = await svc.list();
      // Default hides inactive
      expect(entries, hasLength(1));
      expect(entries.first.id, 'p-1');
      expect(entries.first.nameKz, 'Нан');
      expect(entries.first.salePriceTiyin, 18000);
      expect(entries.first.vatRate, 12);
    });

    test('list with includeInactive=true returns everything', () async {
      final api = _FakeApiClient(
        listResponse: {
          'products': [
            {'ID': 'p-1', 'Name': 'A', 'SalePrice': 1, 'SaleUnit': 'pcs', 'IsWeighted': false, 'VATRate': 12, 'IsActive': true},
            {'ID': 'p-2', 'Name': 'B', 'SalePrice': 2, 'SaleUnit': 'pcs', 'IsWeighted': false, 'VATRate': 12, 'IsActive': false},
          ],
        },
      );
      final svc = LegacyApiProductCatalogService(api);
      expect(await svc.list(includeInactive: true), hasLength(2));
    });

    test('findByBarcode returns null on Go 404 (network error swallowed)', () async {
      final api = _FakeApiClient(barcodeThrows: true);
      final svc = LegacyApiProductCatalogService(api);
      expect(await svc.findByBarcode('does-not-exist'), isNull);
    });

    test('findByBarcode normalises a hit', () async {
      final api = _FakeApiClient(
        barcodeResponse: {
          'ID': 'p-9',
          'Name': 'Кола',
          'BarcodeGTIN': '4870000123456',
          'SalePrice': 25000,
          'SaleUnit': 'pcs',
          'IsWeighted': false,
          'VATRate': 12,
          'IsActive': true,
        },
      );
      final svc = LegacyApiProductCatalogService(api);
      final hit = await svc.findByBarcode('4870000123456');
      expect(hit, isNotNull);
      expect(hit!.id, 'p-9');
      expect(hit.salePriceTiyin, 25000);
    });
  });

  group('createProductCatalogService factory', () {
    test('returns drift impl when useDriftProducts=true', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final svc = createProductCatalogService(
        flags: const FeatureFlags(useDriftProducts: true),
        db: db,
        tenantId: tenantId,
        api: _FakeApiClient(),
      );
      expect(svc, isA<DriftProductCatalogService>());
    });

    test('returns legacy impl when useDriftProducts=false', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final svc = createProductCatalogService(
        flags: const FeatureFlags(),
        db: db,
        tenantId: tenantId,
        api: _FakeApiClient(),
      );
      expect(svc, isA<LegacyApiProductCatalogService>());
    });
  });
}

/// Bare-bones [ApiClient] stub. Overrides only the methods this service uses.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    Map<String, dynamic>? listResponse,
    Map<String, dynamic>? barcodeResponse,
    bool barcodeThrows = false,
  })  : _listResponse = listResponse ?? const {'products': <Map<String, dynamic>>[]},
        _barcodeResponse = barcodeResponse,
        _barcodeThrows = barcodeThrows,
        super(baseUrl: 'http://fake');

  final Map<String, dynamic> _listResponse;
  final Map<String, dynamic>? _barcodeResponse;
  final bool _barcodeThrows;

  @override
  Future<Map<String, dynamic>> listProducts({String? categoryId, int limit = 50, int offset = 0}) async {
    return _listResponse;
  }

  @override
  Future<Map<String, dynamic>> getProductByBarcode(String barcode) async {
    if (_barcodeThrows) throw Exception('404');
    return _barcodeResponse ?? <String, dynamic>{};
  }
}
