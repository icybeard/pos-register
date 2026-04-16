import 'package:pos_system/services/api_client.dart';

/// Manual mock for ApiClient — no external dependencies needed.
///
/// Configure behavior per-test by setting the `on*` callbacks.
/// Unconfigured methods throw [UnimplementedError].
class MockApiClient extends ApiClient {
  MockApiClient() : super(baseUrl: 'http://mock');

  // --- Configurable callbacks ---

  Future<Map<String, dynamic>> Function()? onListCashiers;
  Future<Map<String, dynamic>> Function(String name, String pin, String role)?
      onCreateCashier;
  Future<Map<String, dynamic>> Function(String cashierId)? onGetCurrentShift;
  Future<Map<String, dynamic>> Function(String cashierId, int cashStart)?
      onOpenShift;
  Future<Map<String, dynamic>> Function(String shiftId, int cashEnd)?
      onCloseShift;
  Future<Map<String, dynamic>> Function(String query, int limit)?
      onSearchProducts;
  Future<Map<String, dynamic>> Function(String barcode)?
      onGetProductByBarcode;
  Future<Map<String, dynamic>> Function(Map<String, dynamic> data)?
      onCreateReceipt;
  Future<bool> Function()? onCheckHealth;
  Future<String> Function(String key)? onGetSetting;
  Future<void> Function(String key, String value)? onSetSetting;
  Future<Map<String, dynamic>> Function(String gtin)? onNktSearchByGTIN;

  // --- New auth flow hooks (activation + owner + cashier login) ------------

  Future<Map<String, dynamic>> Function({
    required String email,
    required String password,
  })? onOwnerLogin;
  Future<Map<String, dynamic>> Function({
    required String tenantId,
    required String login,
    required String pin,
    String? deviceId,
  })? onCashierLogin;
  Future<Map<String, dynamic>> Function({
    required String code,
    required String deviceId,
    required String deviceName,
  })? onActivateRegister;

  // --- Overrides ---

  @override
  Future<Map<String, dynamic>> ownerLogin({
    required String email,
    required String password,
  }) async {
    if (onOwnerLogin != null) {
      return onOwnerLogin!(email: email, password: password);
    }
    throw UnimplementedError('MockApiClient.ownerLogin not configured');
  }

  @override
  Future<Map<String, dynamic>> cashierLogin({
    required String tenantId,
    required String login,
    required String pin,
    String? deviceId,
  }) async {
    if (onCashierLogin != null) {
      return onCashierLogin!(
          tenantId: tenantId, login: login, pin: pin, deviceId: deviceId);
    }
    throw UnimplementedError('MockApiClient.cashierLogin not configured');
  }

  @override
  Future<Map<String, dynamic>> activateRegister({
    required String code,
    required String deviceId,
    required String deviceName,
  }) async {
    if (onActivateRegister != null) {
      return onActivateRegister!(
          code: code, deviceId: deviceId, deviceName: deviceName);
    }
    throw UnimplementedError('MockApiClient.activateRegister not configured');
  }

  @override
  Future<Map<String, dynamic>> listCashiers() async {
    if (onListCashiers != null) return onListCashiers!();
    throw UnimplementedError('MockApiClient.listCashiers not configured');
  }

  @override
  Future<Map<String, dynamic>> createCashier({
    required String name,
    required String pin,
    String role = 'cashier',
  }) async {
    if (onCreateCashier != null) return onCreateCashier!(name, pin, role);
    throw UnimplementedError('MockApiClient.createCashier not configured');
  }

  @override
  Future<Map<String, dynamic>> getCurrentShift(String cashierId) async {
    if (onGetCurrentShift != null) return onGetCurrentShift!(cashierId);
    throw UnimplementedError('MockApiClient.getCurrentShift not configured');
  }

  @override
  Future<Map<String, dynamic>> openShift({
    required String cashierId,
    int cashStart = 0,
  }) async {
    if (onOpenShift != null) return onOpenShift!(cashierId, cashStart);
    throw UnimplementedError('MockApiClient.openShift not configured');
  }

  @override
  Future<Map<String, dynamic>> closeShift({
    required String shiftId,
    int cashEnd = 0,
  }) async {
    if (onCloseShift != null) return onCloseShift!(shiftId, cashEnd);
    throw UnimplementedError('MockApiClient.closeShift not configured');
  }

  @override
  Future<Map<String, dynamic>> searchProducts(String query,
      {int limit = 20}) async {
    if (onSearchProducts != null) return onSearchProducts!(query, limit);
    throw UnimplementedError('MockApiClient.searchProducts not configured');
  }

  @override
  Future<Map<String, dynamic>> getProductByBarcode(String barcode) async {
    if (onGetProductByBarcode != null) return onGetProductByBarcode!(barcode);
    throw UnimplementedError(
        'MockApiClient.getProductByBarcode not configured');
  }

  @override
  Future<Map<String, dynamic>> createReceipt(
      Map<String, dynamic> receipt) async {
    if (onCreateReceipt != null) return onCreateReceipt!(receipt);
    throw UnimplementedError('MockApiClient.createReceipt not configured');
  }

  @override
  Future<bool> checkHealth() async {
    if (onCheckHealth != null) return onCheckHealth!();
    throw UnimplementedError('MockApiClient.checkHealth not configured');
  }

  @override
  Future<String> getSetting(String key) async {
    if (onGetSetting != null) return onGetSetting!(key);
    throw UnimplementedError('MockApiClient.getSetting not configured');
  }

  @override
  Future<void> setSetting(String key, String value) async {
    if (onSetSetting != null) return onSetSetting!(key, value);
    throw UnimplementedError('MockApiClient.setSetting not configured');
  }

  @override
  Future<Map<String, dynamic>> nktSearchByGTIN(String gtin) async {
    if (onNktSearchByGTIN != null) return onNktSearchByGTIN!(gtin);
    throw UnimplementedError('MockApiClient.nktSearchByGTIN not configured');
  }
}
