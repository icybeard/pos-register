import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import 'auth/auth_session.dart';
import 'logging_http_client.dart';

/// HTTP клиент для .NET central. Адрес читается из
/// [AppConstants.defaultApiHost] (по умолчанию `http://localhost:5080`).
///
/// Авторизация:
///   - Каждый публичный метод объявляет свой [AuthFlavor]:
///       * [AuthFlavor.none]   — анонимные эндпоинты (login / activate / health)
///       * [AuthFlavor.device] — системные / pre-login (listCashiers, sync, ...)
///       * [AuthFlavor.user]   — действия от лица кассира / админа (всё остальное)
///   - [AuthSession] держит оба токена параллельно (device + user) и обновляет
///     нужный при 401: `_send` ловит ответ, вызывает `session.refresh(flavor)`
///     и повторяет запрос один раз.
///   - Если refresh упал ([SessionExpiredException]), исключение поднимается
///     наверх — `auth_bloc` разруливает по flavor (re-activation vs PIN).
///
/// Для удобства: внутренние `_get/_post/_put/_delete` имеют `flavor` по
/// умолчанию `AuthFlavor.user`, потому что подавляющее большинство публичных
/// методов — user. Эндпоинты `none` и `device` явно передают свой flavor.
class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final AuthSession? _session;

  ApiClient({String? baseUrl, AuthSession? session})
      : baseUrl = baseUrl ?? AppConstants.defaultApiHost,
        _session = session,
        _client = LoggingHttpClient(http.Client());

  /// Раскрыто для тестов и `auth_bloc`, чтобы можно было прокинуть custom session.
  AuthSession? get session => _session;

  // --- Товары ---

  Future<Map<String, dynamic>> listProducts({
    String? categoryId,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    if (categoryId != null) params['category_id'] = categoryId;
    return _get('/api/products', params);
  }

  Future<Map<String, dynamic>> getProduct(String id) async {
    return _get('/api/products/$id');
  }

  Future<Map<String, dynamic>> searchProducts(String query, {int limit = 20}) async {
    return _get('/api/products/search', {'q': query, 'limit': '$limit'});
  }

  Future<Map<String, dynamic>> getProductByBarcode(String barcode) async {
    return _get('/api/products/barcode/$barcode');
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> product) async {
    return _post('/api/products', product);
  }

  // --- Категории ---

  Future<Map<String, dynamic>> listCategories({String? parentId}) async {
    final params = <String, String>{};
    if (parentId != null) params['parent_id'] = parentId;
    return _get('/api/categories', params);
  }

  // --- Авторизация ---
  // На .NET central два варианта входа:
  //   - owner / admin: email + пароль → /api/auth/login
  //   - кассир / менеджер: tenant_id + login + pin → /api/auth/cashier-login
  // Регистрация на кассе НЕ происходит — тенант создаётся через web-админку
  // (POST /api/signup), либо касса активируется заранее выданным кодом
  // через /api/register/activate (P2.5).

  /// Owner / admin login. Возвращает полный токен-пакет (access, refresh,
  /// tenant_id, user_id, role, store_id?). Дёргает `/api/auth/login`.
  /// [deviceFingerprint] — стабильный hash платформенного id, привязывается
  /// к refresh-токену на сервере; при следующем refresh клиент должен
  /// прислать тот же fingerprint, иначе 401 device_mismatch.
  Future<Map<String, dynamic>> ownerLogin({
    required String email,
    required String password,
    String? deviceFingerprint,
  }) async {
    return _post('/api/auth/login', {
      'email': email.trim(),
      'password': password,
      'device_fingerprint': ?deviceFingerprint,
    }, AuthFlavor.none);
  }

  /// Cashier / manager login. Требует `tenant_id`, который можно взять из
  /// owner-токена (после владельческого логина) или из активации кассы.
  /// Дёргает `/api/auth/cashier-login`.
  Future<Map<String, dynamic>> cashierLogin({
    required String tenantId,
    required String login,
    required String pin,
    String? deviceId,
    String? deviceFingerprint,
  }) async {
    return _post('/api/auth/cashier-login', {
      'tenant_id': tenantId,
      'login': login.trim(),
      'pin': pin,
      'device_id': deviceId,
      'device_fingerprint': ?deviceFingerprint,
    }, AuthFlavor.none);
  }

  /// Logout — клиентский. Очищает только user-слот в [AuthSession];
  /// device-слот переживает logout, так что cashier-grid и фоновая sync
  /// продолжают работать без повторной активации. Сервер refresh-токены
  /// инвалидирует на следующем refresh (rotation reuse-detection).
  Future<void> logout() async {
    await _session?.clearUserSession();
  }

  /// Activate a fresh register against a short one-time code minted on the
  /// web admin (POST /api/stores/{storeId}/activation-codes). Response:
  /// `{workstation_id, tenant_id, store_id, store_name}`. No access token
  /// is issued — the device still needs a user login (cashier or owner)
  /// before it can make authorised calls.
  ///
  /// Anonymous endpoint — no Authorization header required.
  Future<Map<String, dynamic>> activateRegister({
    required String code,
    required String deviceId,
    required String deviceName,
    String? deviceFingerprint,
  }) async {
    return _post('/api/register/activate', {
      'code': code,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_fingerprint': ?deviceFingerprint,
    }, AuthFlavor.none);
  }

  Future<Map<String, dynamic>> listCashiers() async {
    return _get('/api/cashiers', null, AuthFlavor.device);
  }

  Future<Map<String, dynamic>> createCashier({
    required String name,
    required String pin,
    String role = 'cashier',
  }) async {
    return _post('/api/cashiers', {'name': name, 'pin': pin, 'role': role});
  }

  // --- Смены ---

  Future<Map<String, dynamic>> openShift({
    required String cashierId,
    int cashStart = 0,
  }) async {
    return _post('/api/shifts/open', {
      'cashier_id': cashierId,
      'cash_start': cashStart,
    });
  }

  Future<Map<String, dynamic>> closeShift({
    required String shiftId,
    int cashEnd = 0,
  }) async {
    return _post('/api/shifts/close', {
      'shift_id': shiftId,
      'cash_end': cashEnd,
    });
  }

  Future<Map<String, dynamic>> getCurrentShift(String cashierId) async {
    return _get('/api/shifts/current/$cashierId');
  }

  Future<Map<String, dynamic>> listOpenShifts() async {
    return _get('/api/shifts/open', null, AuthFlavor.device);
  }

  Future<Map<String, dynamic>> shiftDeposit(String shiftId, int amountTiyin) async {
    return _post('/api/shifts/$shiftId/deposit', {'amount': amountTiyin});
  }

  Future<Map<String, dynamic>> shiftWithdraw(String shiftId, int amountTiyin) async {
    return _post('/api/shifts/$shiftId/withdraw', {'amount': amountTiyin});
  }

  Future<Map<String, dynamic>> listReceiptsByShift(String shiftId) async {
    return _get('/api/receipts', {'shift_id': shiftId});
  }

  Future<Map<String, dynamic>> resetCashierPin(String cashierId, String newPin) async {
    return _put('/api/cashiers/$cashierId/reset-pin', {'new_pin': newPin});
  }

  Future<Map<String, dynamic>> updateCashier(String cashierId, {required String name, required String role}) async {
    return _put('/api/cashiers/$cashierId', {'name': name, 'role': role});
  }

  Future<Map<String, dynamic>> deactivateCashier(String cashierId) async {
    return _post('/api/cashiers/$cashierId/deactivate', {});
  }

  // --- Чеки ---

  Future<Map<String, dynamic>> createReceipt(Map<String, dynamic> receipt) async {
    return _post('/api/receipts', receipt);
  }

  Future<Map<String, dynamic>> getReceipt(String id) async {
    return _get('/api/receipts/$id');
  }

  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> product) async {
    return _put('/api/products/$id', product);
  }

  Future<Map<String, dynamic>> deleteProduct(String id) async {
    return _delete('/api/products/$id');
  }

  // --- Клиенты ---

  Future<Map<String, dynamic>> listClients() async {
    return _get('/api/clients');
  }

  Future<Map<String, dynamic>> createClient(Map<String, dynamic> client) async {
    return _post('/api/clients', client);
  }

  // --- Долги ---

  Future<Map<String, dynamic>> listDebts({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    return _get('/api/debts', params);
  }

  Future<Map<String, dynamic>> createDebt(Map<String, dynamic> debt) async {
    return _post('/api/debts', debt);
  }

  Future<Map<String, dynamic>> payDebt(String debtId, Map<String, dynamic> payment) async {
    return _post('/api/debts/$debtId/pay', payment);
  }

  // --- НКТ -----------------------------------------------------------------
  // Central-side proxy (T6.5). Register never holds nct.kz credentials; the
  // `.NET` central reads per-tenant creds (saved via web admin) or falls
  // back to POS-pooled creds. Routes match `Pos.Api.Endpoints.NktEndpoints`.

  Future<Map<String, dynamic>> nktSearchByGTIN(String gtin) async {
    return _get('/api/nkt/gtin/$gtin');
  }

  Future<Map<String, dynamic>> nktSearchByNTIN(String ntin) async {
    return _get('/api/nkt/ntin/$ntin');
  }

  Future<Map<String, dynamic>> nktSearchByName(String query) async {
    return _get('/api/nkt/search', {'q': query});
  }

  // --- Аналитика ---

  Future<Map<String, dynamic>> getSalesSummary() async {
    return _get('/api/analytics/sales-summary');
  }

  Future<Map<String, dynamic>> getTopProducts({int limit = 10}) async {
    return _get('/api/analytics/top-products', {'limit': '$limit'});
  }

  Future<Map<String, dynamic>> getPaymentBreakdown() async {
    return _get('/api/analytics/payment-breakdown');
  }

  Future<Map<String, dynamic>> getInventoryAlerts({int threshold = 5}) async {
    return _get('/api/analytics/inventory-alerts', {'threshold': '$threshold'});
  }

  Future<Map<String, dynamic>> getDebtSummary() async {
    return _get('/api/analytics/debt-summary');
  }

  Future<Map<String, dynamic>> getCashierPerformance({String? dateFrom, String? dateTo}) async {
    final params = <String, String>{};
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    return _get('/api/analytics/cashier-performance', params.isNotEmpty ? params : null);
  }

  Future<Map<String, dynamic>> getRevenueByProduct({String? dateFrom, String? dateTo, int limit = 50}) async {
    final params = <String, String>{'limit': '$limit'};
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    return _get('/api/analytics/revenue-by-product', params);
  }

  Future<Map<String, dynamic>> getAverageReceipt() async {
    return _get('/api/analytics/average-receipt');
  }

  // --- Поставщики ---

  Future<Map<String, dynamic>> listSuppliers() async {
    return _get('/api/suppliers');
  }

  Future<Map<String, dynamic>> createSupplier({required String name, String phone = '', String note = ''}) async {
    return _post('/api/suppliers', {'name': name, 'phone': phone, 'note': note});
  }

  // --- Аудит ---

  Future<Map<String, dynamic>> listAuditLog({
    String? cashierId,
    String? action,
    String? dateFrom,
    String? dateTo,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{'limit': '$limit', 'offset': '$offset'};
    if (cashierId != null) params['cashier_id'] = cashierId;
    if (action != null) params['action'] = action;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    return _get('/api/audit-log', params);
  }

  // --- Поставки ---

  Future<Map<String, dynamic>> createDelivery({
    required String cashierId,
    required String cashierName,
    required List<Map<String, dynamic>> items,
  }) async {
    return _post('/api/deliveries', {
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'items': items,
    });
  }

  Future<Map<String, dynamic>> listDeliveries({int limit = 50, int offset = 0}) async {
    return _get('/api/deliveries', {'limit': '$limit', 'offset': '$offset'});
  }

  // --- Одобрение товаров (НКТ) ---

  Future<Map<String, dynamic>> listPendingProducts({int limit = 50, int offset = 0}) async {
    return _get('/api/products/pending', {'limit': '$limit', 'offset': '$offset'});
  }

  Future<Map<String, dynamic>> countPendingProducts() async {
    return _get('/api/products/pending/count');
  }

  Future<Map<String, dynamic>> approveProduct(String id, {
    required String reviewerId,
    required String reviewerName,
    String? name,
    int? salePrice,
    String? categoryId,
  }) async {
    final body = <String, dynamic>{
      'reviewer_id': reviewerId,
      'reviewer_name': reviewerName,
    };
    if (name != null) body['name'] = name;
    if (salePrice != null) body['sale_price'] = salePrice;
    if (categoryId != null) body['category_id'] = categoryId;
    return _post('/api/products/$id/approve', body);
  }

  Future<Map<String, dynamic>> rejectProduct(String id, {
    required String reviewerId,
    required String reviewerName,
    String note = '',
  }) async {
    return _post('/api/products/$id/reject', {
      'reviewer_id': reviewerId,
      'reviewer_name': reviewerName,
      'note': note,
    });
  }

  // --- Разрешения кассиров ---

  Future<Map<String, dynamic>> getPermissions(String cashierId) async {
    return _get('/api/cashiers/$cashierId/permissions');
  }

  Future<Map<String, dynamic>> setPermissions(String cashierId, Map<String, bool> permissions) async {
    return _put('/api/cashiers/$cashierId/permissions', {'permissions': permissions});
  }

  // --- Асинхронные задачи ---

  Future<Map<String, dynamic>> getTask(String taskId) async {
    return _get('/api/tasks/$taskId');
  }

  Future<Map<String, dynamic>> cancelTask(String taskId) async {
    return _post('/api/tasks/$taskId/cancel', {});
  }

  Future<Map<String, dynamic>> listTasks({int limit = 20}) async {
    return _get('/api/tasks', {'limit': '$limit'});
  }

  // --- Рабочие места ---

  Future<Map<String, dynamic>> generateActivationCode() async {
    return _post('/api/workstations/generate-code', {});
  }

  Future<Map<String, dynamic>> activateWorkstation({required String code, required String deviceId, String name = 'Касса'}) async {
    return _post('/api/workstations/activate', {'code': code, 'device_id': deviceId, 'name': name});
  }

  Future<Map<String, dynamic>> listWorkstations() async {
    return _get('/api/workstations');
  }

  // --- Экспорт отчётов ---

  Future<Uint8List> exportReport(String reportType, {String format = 'xlsx', String? dateFrom, String? dateTo, String? status}) async {
    final params = <String, String>{'format': format};
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (status != null) params['status'] = status;
    final uri = Uri.parse('$baseUrl/api/export/$reportType').replace(queryParameters: params);
    final response = await _send(
      AuthFlavor.user,
      () => _client.get(uri, headers: _authHeaders(AuthFlavor.user)),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw ApiException(response.statusCode, response.body);
  }

  // --- Импорт товаров ---

  Future<Uint8List> downloadImportTemplate() async {
    final uri = Uri.parse('$baseUrl/api/products/import/template');
    final response = await _send(
      AuthFlavor.user,
      () => _client.get(uri, headers: _authHeaders(AuthFlavor.user)),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// Multipart upload — поток нельзя «перемотать», поэтому 401 в середине
  /// загрузки не ретраится (выбросится `ApiException(401)`). Тщательная
  /// предварительная активация / refresh — обязанность вызывающего; для
  /// admin-only операции редкого использования это приемлемо.
  Future<Map<String, dynamic>> uploadProductsExcel(Uint8List bytes, String filename) async {
    final uri = Uri.parse('$baseUrl/api/products/import');
    final response = await _send(AuthFlavor.user, () async {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(_authHeaders(AuthFlavor.user))
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    });
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>> confirmImport(String taskId) async {
    return _post('/api/products/import/$taskId/confirm', {});
  }

  Future<Map<String, dynamic>> cancelImport(String taskId) async {
    return _post('/api/products/import/$taskId/cancel', {});
  }

  // --- Soft-delete: деактивация/восстановление ---

  Future<Map<String, dynamic>> deactivateCategory(String id) async {
    return _post('/api/categories/$id/deactivate', {});
  }

  Future<Map<String, dynamic>> reactivateCategory(String id) async {
    return _post('/api/categories/$id/reactivate', {});
  }

  Future<Map<String, dynamic>> deactivateClient(String id) async {
    return _post('/api/clients/$id/deactivate', {});
  }

  Future<Map<String, dynamic>> reactivateClient(String id) async {
    return _post('/api/clients/$id/reactivate', {});
  }

  Future<Map<String, dynamic>> reactivateCashier(String id) async {
    return _post('/api/cashiers/$id/reactivate', {});
  }

  Future<Map<String, dynamic>> archiveReceipt(String id) async {
    return _post('/api/receipts/$id/archive', {});
  }

  Future<Map<String, dynamic>> restoreReceipt(String id) async {
    return _post('/api/receipts/$id/restore', {});
  }

  Future<Map<String, dynamic>> archiveShift(String id) async {
    return _post('/api/shifts/$id/archive', {});
  }

  Future<Map<String, dynamic>> restoreShift(String id) async {
    return _post('/api/shifts/$id/restore', {});
  }

  Future<Map<String, dynamic>> archiveDebt(String id) async {
    return _post('/api/debts/$id/archive', {});
  }

  Future<Map<String, dynamic>> restoreDebt(String id) async {
    return _post('/api/debts/$id/restore', {});
  }

  // --- Демо ---

  Future<Map<String, dynamic>> seedDemo() async {
    return _post('/api/demo/seed', {});
  }

  // --- Здоровье ---

  Future<bool> checkHealth() async {
    try {
      final response = await _get('/api/health', null, AuthFlavor.none);
      return response['status'] == 'ok';
    } on Exception catch (_) {
      return false;
    }
  }

  // --- Синхронизация ---

  Future<Map<String, dynamic>> pushChanges(List<Map<String, dynamic>> entries) async {
    return _post('/api/sync/push', {'entries': entries}, AuthFlavor.device);
  }

  Future<Map<String, dynamic>> pullChanges({String? since, int limit = 500}) async {
    final params = <String, String>{'limit': '$limit'};
    if (since != null) params['since'] = since;
    return _get('/api/sync/pull', params, AuthFlavor.device);
  }

  Future<Map<String, dynamic>> syncStatus() async {
    return _get('/api/sync/status', null, AuthFlavor.device);
  }

  // --- Ценники ---

  Future<Uint8List> generateLabels({required List<String> productIds, String size = 'shelf'}) async {
    final uri = Uri.parse('$baseUrl/api/labels/generate');
    final response = await _send(
      AuthFlavor.user,
      () => _client.post(
        uri,
        headers: _authHeaders(AuthFlavor.user, json: true),
        body: json.encode({'product_ids': productIds, 'size': size}),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw ApiException(response.statusCode, response.body);
  }

  // --- Настройки ---

  Future<String> getSetting(String key) async {
    final response = await _get('/api/settings/$key', null, AuthFlavor.device);
    return response['value'] as String? ?? '';
  }

  Future<void> setSetting(String key, String value) async {
    await _put('/api/settings/$key', {'value': value});
  }

  // --- HTTP утилиты ---

  /// Builds Authorization header for the requested flavor. `none` returns
  /// only Content-Type (login/activate endpoints don't carry a Bearer).
  Map<String, String> _authHeaders(AuthFlavor flavor, {bool json = false}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (flavor == AuthFlavor.none) return h;
    final session = _session;
    if (session != null) {
      h.addAll(session.headers(flavor));
    }
    return h;
  }

  /// Core request helper: runs [doRequest], on 401 calls
  /// `session.refresh(flavor)` and retries once. The per-slot epoch is
  /// captured before the call so a slot rewritten under us (logout, manual
  /// re-login) bypasses the retry — we don't want to send a freshly-issued
  /// token for a request that was queued under the old session.
  Future<http.Response> _send(
    AuthFlavor flavor,
    Future<http.Response> Function() doRequest,
  ) async {
    final session = _session;
    final epoch = session?.epochOf(flavor) ?? 0;
    final resp = await doRequest().timeout(AppConstants.apiTimeout);

    if (resp.statusCode != 401 || flavor == AuthFlavor.none || session == null) {
      return resp;
    }
    if (epoch != session.epochOf(flavor)) {
      return resp; // slot was rewritten under us — don't retry
    }

    try {
      await session.refresh(flavor);
    } on Exception {
      // Refresh failed (SessionExpired or SessionUnavailable). Surface the
      // original 401 so the caller's existing error path runs; the typed
      // exception bubbles up via the next request attempt and is handled
      // by auth_bloc.
      return resp;
    }
    if (epoch + 1 != session.epochOf(flavor)) {
      return resp; // someone else also wrote during refresh
    }

    return doRequest().timeout(AppConstants.apiTimeout);
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? params,
    AuthFlavor flavor = AuthFlavor.user,
  ]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final response = await _send(
      flavor,
      () => _client.get(uri, headers: _authHeaders(flavor)),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, [
    AuthFlavor flavor = AuthFlavor.user,
  ]) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _send(
      flavor,
      () => _client.post(
        uri,
        headers: _authHeaders(flavor, json: true),
        body: json.encode(body),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body, [
    AuthFlavor flavor = AuthFlavor.user,
  ]) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _send(
      flavor,
      () => _client.put(
        uri,
        headers: _authHeaders(flavor, json: true),
        body: json.encode(body),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, dynamic>> _delete(
    String path, [
    AuthFlavor flavor = AuthFlavor.user,
  ]) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _send(
      flavor,
      () => _client.delete(uri, headers: _authHeaders(flavor)),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, response.body);
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
