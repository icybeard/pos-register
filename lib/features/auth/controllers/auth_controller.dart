import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, listEquals, mapEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../services/api_client.dart';
import '../../../services/auth/auth_session.dart' show AuthFlavor, SessionExpiredException;
import '../../../services/auth/auth_token_store.dart';
import '../../../services/auth/biometric_auth_service.dart';
import '../../../services/auth/device_id_store.dart';
import '../../../services/auth/local_auth_service.dart';
import '../../../services/auth/lockout_store.dart';
import '../../../services/auth/standalone_store.dart';
import '../../../services/auth/workstation_store.dart';

// === States ===
//
// Hand-rolled `==` (replaces equatable). Necessary so Notifier short-circuits
// rebuilds when the same logical state is re-assigned — e.g. each PIN digit
// press would otherwise rebuild even though the displayed pin string is the
// only change vs. last frame, because identity differs.

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  final String pin;
  final String? error;
  final bool isFirstRun;

  /// Available cashier accounts for profile selection
  final List<Map<String, dynamic>> cashiers;

  /// Map of cashierID → shift openedAt (only for cashiers with open shifts)
  final Map<String, String> openShifts;

  /// Currently selected cashier name (visual only — PIN auth is server-side)
  final String? selectedCashierName;

  /// Number of consecutive failed PIN attempts.
  final int failedAttempts;

  /// If locked out, the timestamp when lockout expires.
  final DateTime? lockedUntil;

  const AuthInitial({
    this.pin = '',
    this.error,
    this.isFirstRun = false,
    this.cashiers = const [],
    this.openShifts = const {},
    this.selectedCashierName,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  bool get isLockedOut =>
      lockedUntil != null && DateTime.now().isBefore(lockedUntil!);

  Duration get lockoutRemaining =>
      isLockedOut ? lockedUntil!.difference(DateTime.now()) : Duration.zero;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthInitial &&
        pin == other.pin &&
        error == other.error &&
        isFirstRun == other.isFirstRun &&
        listEquals(cashiers, other.cashiers) &&
        mapEquals(openShifts, other.openShifts) &&
        selectedCashierName == other.selectedCashierName &&
        failedAttempts == other.failedAttempts &&
        lockedUntil == other.lockedUntil;
  }

  @override
  int get hashCode => Object.hash(
        pin,
        error,
        isFirstRun,
        Object.hashAll(cashiers),
        Object.hashAllUnordered(
            openShifts.entries.map((e) => Object.hash(e.key, e.value))),
        selectedCashierName,
        failedAttempts,
        lockedUntil,
      );
}

class AuthLoading extends AuthState {
  const AuthLoading();
  @override
  bool operator ==(Object other) => other is AuthLoading;
  @override
  int get hashCode => 0;
}

class AuthAuthenticated extends AuthState {
  final String cashierId;
  final String cashierName;
  final String role;
  const AuthAuthenticated({
    required this.cashierId,
    required this.cashierName,
    required this.role,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthAuthenticated &&
        cashierId == other.cashierId &&
        cashierName == other.cashierName &&
        role == other.role;
  }

  @override
  int get hashCode => Object.hash(cashierId, cashierName, role);
}

/// Fresh / never-activated device. Boot lands here the first time the app
/// runs; the [ActivationScreen] widget reacts to it.
class RegisterNotActivated extends AuthState {
  /// Error from the last failed activation attempt (wrong code, expired,
  /// already used, network). Null on the very first render.
  final String? error;
  final bool busy;
  const RegisterNotActivated({this.error, this.busy = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegisterNotActivated &&
        error == other.error &&
        busy == other.busy;
  }

  @override
  int get hashCode => Object.hash(error, busy);
}

/// Owner chose «работать автономно» on the connect screen but the local
/// owner account hasn't been created yet. Routes to StandaloneSetupScreen.
class StandaloneSetupRequired extends AuthState {
  final String? error;
  final bool busy;
  const StandaloneSetupRequired({this.error, this.busy = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StandaloneSetupRequired &&
        error == other.error &&
        busy == other.busy;
  }

  @override
  int get hashCode => Object.hash(error, busy);
}

/// Device is activated but no user is logged in. Shows the login chooser
/// ("Cashier" vs "Admin"). Carries the workstation payload so downstream
/// screens don't have to re-load it from secure storage on every rebuild.
class RegisterActivated extends AuthState {
  final WorkstationInfo workstation;
  /// Error from the last failed cashier-login attempt, surfaced by
  /// [CashierLoginScreen]. Null otherwise.
  final String? error;
  final bool busy;
  const RegisterActivated(this.workstation, {this.error, this.busy = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegisterActivated &&
        workstation == other.workstation &&
        error == other.error &&
        busy == other.busy;
  }

  @override
  int get hashCode => Object.hash(workstation, error, busy);
}

// ═══════════════════════════════════════════════════════════════
// Controller (was: AuthBloc — flutter_bloc → Riverpod migration P0b)
// ═══════════════════════════════════════════════════════════════
//
// Method-per-former-event so call sites translate mechanically:
//   bloc.add(PinDigitPressed('1'))   → controller.pinDigit('1')
//   bloc.add(HydrateSession())       → controller.hydrate()
//   bloc.add(ActivateRegisterRequested(code)) → controller.activateRegister(code)
//
// State mutations go through `state = ...` instead of `emit(...)`.
// Inherited Notifier suppresses identical-state rewrites via `==` so the
// hand-rolled state equality above is what makes rebuild-suppression work
// — same effect Equatable + BlocBuilder gave us before.

class AuthController extends Notifier<AuthState> {
  late final ApiClient _api;
  late final AuthTokenStore? _tokens;
  late final AuthTokenStore? _deviceTokens;
  late final WorkstationStore? _workstation;
  late final DeviceIdStore _deviceIdStore;
  late final LockoutStore? _lockoutStore;
  late final BiometricAuthService _biometric;
  late final StandaloneStore? _standalone;
  late final LocalAuthService? _localAuth;

  /// Cached workstation info after activation — populated by hydrate /
  /// activation handlers so cashier-login has access to tenant_id without
  /// a secure-storage read on every keystroke.
  WorkstationInfo? _activeWorkstation;

  /// Standalone-mode marker (spec 03 R1/R2). Mutually exclusive with
  /// [_activeWorkstation]: linking adopts the real tenant and clears this.
  StandaloneInfo? _standaloneInfo;
  bool get isStandalone => _standaloneInfo != null && _activeWorkstation == null;

  /// Max failed attempts before lockout.
  static const int maxAttempts = 5;

  /// Lockout durations by tier (escalating).
  static const _lockoutDurations = [
    Duration(seconds: 30), // after 5 failures
    Duration(minutes: 2), // after 10
    Duration(minutes: 5), // after 15
    Duration(minutes: 15), // after 20+
  ];

  /// Tracks total failed attempts across state transitions. Persisted to
  /// [_lockoutStore] so killing / restarting the app doesn't reset the
  /// counter — a common physical-device bypass.
  int _totalFailedAttempts = 0;
  DateTime? _lockedUntil;

  /// Timer that auto-unlocks after lockout expires.
  Timer? _lockoutTimer;

  /// Cached open shifts map (survives state transitions)
  Map<String, String> _openShifts = {};

  /// Tenant id captured from the owner login response. Required to switch
  /// to a cashier account via `/api/auth/cashier-login` later in the
  /// session — null until the owner logs in.
  String? _ownerTenantId;

  String? _savedCashierUserId;
  String? get savedCashierUserId => _savedCashierUserId;

  bool _biometricAvailable = false;
  bool get isBiometricAvailable => _biometricAvailable;

  WorkstationInfo? get activeWorkstation => _activeWorkstation;

  @override
  AuthState build() {
    _api = ref.read(authApiClientProvider);
    _tokens = ref.read(authUserTokenStoreProvider);
    _deviceTokens = ref.read(authDeviceTokenStoreProvider);
    _workstation = ref.read(authWorkstationStoreProvider);
    _deviceIdStore = ref.read(authDeviceIdStoreProvider);
    _lockoutStore = ref.read(authLockoutStoreProvider);
    _biometric = ref.read(authBiometricServiceProvider);
    _standalone = ref.read(authStandaloneStoreProvider);
    _localAuth = ref.read(authLocalAuthServiceProvider);

    // Notifier disposal hook — replaces Bloc.close().
    ref.onDispose(() {
      _lockoutTimer?.cancel();
    });

    return const AuthInitial();
  }

  // --- Error helpers -----------------------------------------------------

  String? _extractServerError(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['error'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } on Object {
      // Not JSON or malformed — fall through to null.
    }
    return null;
  }

  /// Reads the extra fields the server attaches to a 409 device-limit refusal
  /// ({error_code, linked_count, limit, blocks}). Returns null for any other
  /// error shape.
  Map<String, dynamic>? _extractDeviceLimit(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> &&
          decoded['error_code'] == 'device_limit_reached') {
        return decoded;
      }
    } on Object {
      // Not JSON or malformed — treat as a generic error.
    }
    return null;
  }

  String _mapActivationError(int status, String? serverMsg, [String body = '']) {
    // The tariff ceiling is a specific, actionable refusal — say what to do,
    // not just what failed (spec 03 Phase C).
    final limit = _extractDeviceLimit(body);
    if (limit != null) {
      final linked = limit['linked_count'];
      final max = limit['limit'];
      final counts = (linked is int && max is int) ? ' ($linked из $max)' : '';
      return 'Достигнут лимит подключённых касс по тарифу$counts. '
          'Отключите неиспользуемую кассу в веб-админке или напишите нам, '
          'чтобы расширить тариф.';
    }

    final lc = (serverMsg ?? '').toLowerCase();
    if (lc.contains('already used')) {
      return 'Код уже использован — возможно, на другой кассе. Получите новый в веб-админке.';
    }
    if (lc.contains('expired') || lc.contains('истёк') || lc.contains('истек')) {
      return 'Код истёк. Получите новый в веб-админке.';
    }
    if (lc.contains('not found') || lc.contains('unknown')) {
      return 'Код не найден. Проверьте, что набрали правильно.';
    }
    if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;
    switch (status) {
      case 400:
        return 'Неверный формат кода';
      case 401:
        return 'Код отклонён — возможно уже использован или истёк';
      case 404:
      case 410:
        return 'Код не найден или уже использован';
      default:
        return status >= 500
            ? 'Ошибка сервера'
            : 'Подключение не удалось ($status)';
    }
  }

  // --- Standalone mode (spec 03 R1: skip linking, run fully local) ---------

  /// «Пропустить — работать автономно» on the connect screen.
  void skipToStandalone() {
    if (_activeWorkstation != null) return; // linked devices can't "skip"
    state = const StandaloneSetupRequired();
  }

  static const _uuid = Uuid();
  String _newUuid() => _uuid.v4();

  /// Back from the standalone wizard to the connect screen.
  void cancelStandaloneSetup() {
    if (_standaloneInfo != null) return; // setup already persisted — no way back
    state = const RegisterNotActivated();
  }

  /// Creates the local owner + persists the standalone marker, then lands on
  /// the PIN grid. Synthetic tenant/store UUIDs are re-stamped to the real
  /// tenant if the register is linked later (see [activateRegister]).
  Future<void> finishStandaloneSetup({
    required String ownerName,
    required String pin,
    required String storeName,
  }) async {
    final local = _localAuth;
    final store = _standalone;
    if (local == null || store == null) {
      state = const StandaloneSetupRequired(
          error: 'Локальная база недоступна — перезапустите кассу');
      return;
    }
    state = const StandaloneSetupRequired(busy: true);
    try {
      // Reuse a marker persisted by an earlier interrupted setup so local
      // rows never split across two synthetic tenants.
      final info = _standaloneInfo ??
          await store.load() ??
          StandaloneInfo(
            tenantId: _newUuid(),
            storeId: _newUuid(),
            storeName: storeName.trim(),
            createdAt: DateTime.now().toUtc(),
          );
      await store.save(info);
      _standaloneInfo = info;
      await local.createOwner(
        tenantId: info.tenantId,
        storeId: info.storeId,
        name: ownerName.trim(),
        pin: pin,
      );
      await checkFirstRun();
    } on Object {
      state = const StandaloneSetupRequired(
          error: 'Не удалось сохранить данные — попробуйте ещё раз');
    }
  }

  // --- Device activation (first boot) -------------------------------------

  Future<void> activateRegister(String code) async {
    final current = state;
    if (current is RegisterActivated) return;
    if (current is RegisterNotActivated && current.busy) return;

    final store = _workstation;

    state = const RegisterNotActivated(busy: true);
    WorkstationInfo? info;
    String? accessToken;
    String? refreshToken;
    String? accessExpiresAt;
    String? refreshExpiresAt;
    try {
      final deviceId = await _deviceIdStore.getOrCreate();
      final resp = await _api.activateRegister(
        code: code.trim().toUpperCase(),
        deviceId: deviceId,
        deviceName: _platformDeviceName(),
      );
      final wsId = resp['workstation_id'] as String?;
      final tnId = resp['tenant_id'] as String?;
      final stId = resp['store_id'] as String?;
      if (wsId == null || tnId == null || stId == null) {
        state = const RegisterNotActivated(
            error: 'Сервер вернул неполный ответ — обратитесь к администратору');
        return;
      }
      accessToken = resp['access_token'] as String?;
      refreshToken = resp['refresh_token'] as String?;
      accessExpiresAt = resp['access_expires_at'] as String?;
      refreshExpiresAt = resp['refresh_expires_at'] as String?;
      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty ||
          accessExpiresAt == null ||
          refreshExpiresAt == null) {
        state = const RegisterNotActivated(
            error: 'Сервер не выдал токены устройства — '
                'возможно нужно обновить серверную часть.');
        return;
      }
      info = WorkstationInfo(
        workstationId: wsId,
        tenantId: tnId,
        storeId: stId,
        storeName: (resp['store_name'] as String?) ?? '',
        activatedAt: DateTime.now().toUtc(),
      );
    } on ApiException catch (e) {
      final serverMsg = _extractServerError(e.body);
      final msg = _mapActivationError(e.statusCode, serverMsg, e.body);
      state = RegisterNotActivated(error: msg);
      return;
    } on Exception catch (_) {
      state = const RegisterNotActivated(error: 'Нет связи с сервером');
      return;
    }

    // Linking a register that ran standalone: adopt the real tenant — local
    // rows are re-stamped from the synthetic id, the pre-link outbox is
    // dropped (sync is from-link-forward, spec 03 R5), and the standalone
    // marker is cleared so hydrate() takes the linked path from now on.
    final standalone = _standaloneInfo ?? await _standalone?.load();
    if (standalone != null) {
      try {
        await _localAuth?.adoptTenant(
          fromTenantId: standalone.tenantId,
          toTenantId: info.tenantId,
        );
        await _standalone?.clear();
        _standaloneInfo = null;
      } on Object {
        state = const RegisterNotActivated(
            error: 'Не удалось перенести локальные данные — '
                'попробуйте подключить кассу ещё раз');
        return;
      }
    }

    _activeWorkstation = info;

    String? persistWarning;
    final session = _api.session;
    final deviceTokens = AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessExpiresAt: DateTime.parse(accessExpiresAt).toUtc(),
      refreshExpiresAt: DateTime.parse(refreshExpiresAt).toUtc(),
      tenantId: info.tenantId,
      role: 'device',
      storeId: info.storeId,
      workstationId: info.workstationId,
    );
    if (session != null) {
      try {
        await session.useDeviceSession(deviceTokens);
      } on Object {
        persistWarning =
            'Касса подключена, но настройки не сохранены — '
            'не перезагружайте кассу до входа сотрудника.';
      }
    }

    try {
      await store?.save(info);
    } on Object {
      persistWarning ??=
          'Касса подключена, но настройки не сохранены — '
          'не перезагружайте кассу до входа сотрудника.';
    }

    state = RegisterActivated(info, error: persistWarning);
  }

  // --- Biometric login (reuse saved session) ----------------------------

  Future<void> biometricLogin() async {
    final ws = _activeWorkstation;
    if (ws == null) {
      state = const RegisterNotActivated(error: 'Сначала подключите кассу к платформе');
      return;
    }

    final saved = await _tokens?.load();
    if (saved == null) {
      state = RegisterActivated(ws,
          error: 'Сначала войдите по PIN — Face ID запомнит сессию');
      return;
    }
    if (saved.isAccessExpired) {
      state = RegisterActivated(ws, error: 'Сессия истекла — войдите по PIN');
      return;
    }

    final available = await _biometric.isAvailable();
    if (!available) {
      state = RegisterActivated(ws,
          error: 'Биометрия не настроена на этом устройстве');
      return;
    }

    state = RegisterActivated(ws, busy: true);
    final hasFace = await _biometric.hasFace();
    final outcome = await _biometric.authenticate(
      reason: hasFace
          ? 'Подтвердите вход по Face ID'
          : 'Подтвердите вход по отпечатку',
    );

    switch (outcome) {
      case BiometricOutcome.success:
        await _api.session?.useUserSession(saved);
        _ownerTenantId = saved.tenantId;
        _totalFailedAttempts = 0;
        _lockedUntil = null;
        _clearPersistedLockout();
        state = AuthAuthenticated(
          cashierId: saved.userId ?? '',
          cashierName: saved.userId ?? 'cashier',
          role: saved.role ?? 'cashier',
        );
      case BiometricOutcome.userCancelled:
        state = RegisterActivated(ws);
      case BiometricOutcome.notEnrolled:
        state = RegisterActivated(ws,
            error: 'Добавьте отпечаток / Face ID в настройках устройства');
      case BiometricOutcome.lockedOut:
      case BiometricOutcome.permanentlyLockedOut:
        state = RegisterActivated(ws,
            error: 'Биометрия временно заблокирована — разблокируйте устройство паролем');
      case BiometricOutcome.notSupported:
        state = RegisterActivated(ws, error: 'Устройство не поддерживает биометрию');
      case BiometricOutcome.otherError:
        state = RegisterActivated(ws, error: 'Не удалось выполнить вход по биометрии');
    }
  }

  /// «Отключить» in Settings → Платформа (spec 03 R5).
  ///
  /// Tells the server first so the tariff slot is actually freed, then drops
  /// the binding locally and keeps running standalone. ALL local data stays —
  /// the standalone marker carries the REAL tenant/store ids, so re-linking
  /// later re-stamps nothing and the register's history remains one continuous
  /// dataset. The undrained outbox is cleared: those deltas can never reach the
  /// server now, and re-linking is sync-from-that-point-forward anyway.
  ///
  /// Fails loudly when the server is unreachable — a register that thinks it is
  /// standalone while the server still counts it would quietly eat a paid slot.
  /// (Unreachable/lost devices are the admin's `POST /api/workstations/{id}/unlink`.)
  Future<void> unlinkFromPlatform() async {
    final ws = _activeWorkstation;
    if (ws == null) return;
    state = RegisterActivated(ws, busy: true);

    try {
      await _api.unlinkRegister();
    } on ApiException catch (e) {
      // 401/404/410 all mean the server no longer considers us linked — the
      // local cleanup below is exactly the right response.
      if (e.statusCode != 401 && e.statusCode != 404 && e.statusCode != 410) {
        state = RegisterActivated(ws,
            error: 'Не удалось отключить кассу ($e). Попробуйте позже.');
        return;
      }
    } on Exception catch (_) {
      state = RegisterActivated(ws,
          error: 'Нет связи с сервером — отключение возможно только онлайн');
      return;
    }

    await _applyLocalUnlink(ws);
  }

  /// Local half of unlinking: drop the binding, keep the data, land standalone.
  /// Shared by the explicit action and the "an admin unlinked us" discovery.
  Future<void> _applyLocalUnlink(WorkstationInfo ws, {String? notice}) async {
    final info = StandaloneInfo(
      tenantId: ws.tenantId,
      storeId: ws.storeId,
      storeName: ws.storeName,
      createdAt: DateTime.now().toUtc(),
    );
    await _standalone?.save(info);
    _standaloneInfo = info;

    await _api.session?.clearAll();
    await _workstation?.clear();
    await _localAuth?.clearOutbox();
    _ownerTenantId = null;
    _activeWorkstation = null;

    await checkFirstRun();
    if (notice != null && state is RegisterActivated) {
      state = RegisterActivated((state as RegisterActivated).workstation,
          error: notice);
    }
  }

  // --- Cashier login (after activation) -----------------------------------

  Future<void> cashierLogin({required String login, required String pin}) async {
    final ws = _activeWorkstation;
    if (ws == null) {
      state = const RegisterNotActivated(error: 'Сначала подключите кассу к платформе');
      return;
    }
    state = RegisterActivated(ws, busy: true);
    try {
      final resp = await _api.cashierLogin(
        tenantId: ws.tenantId,
        login: login,
        pin: pin,
        deviceId: ws.workstationId,
      );
      final token = resp['access_token'] as String?;
      if (token == null || token.isEmpty) {
        state = RegisterActivated(ws, error: 'Сервер не вернул токен');
        return;
      }
      _ownerTenantId = ws.tenantId;
      _savedCashierUserId = resp['user_id'] as String?;
      try {
        await _api.session?.useUserSession(AuthTokens.fromJson(resp));
      } on Object catch (_) {
        // Non-fatal — session still has in-memory token via the failed write
        // path; persistence will retry on the next refresh.
      }
      _totalFailedAttempts = 0;
      _lockedUntil = null;
      _clearPersistedLockout();
      state = AuthAuthenticated(
        cashierId: (resp['user_id'] as String?) ?? '',
        cashierName: login,
        role: (resp['role'] as String?) ?? 'cashier',
      );
    } on ApiException catch (e) {
      final msg = e.statusCode == 401
          ? 'Неверный логин или PIN'
          : e.statusCode == 423
              ? 'Слишком много попыток — попробуйте позже'
              : e.statusCode >= 500
                  ? 'Ошибка сервера'
                  : 'Не удалось войти (${e.statusCode})';
      if (e.statusCode == 401) {
        _totalFailedAttempts++;
        _persistFailureCount();
      }
      state = RegisterActivated(ws, error: msg);
    } on SessionExpiredException catch (e) {
      await handleDeviceSessionExpired(e);
    } on Exception catch (_) {
      state = RegisterActivated(ws, error: 'Нет связи с сервером');
    }
  }

  /// The device refresh token stopped working while a binding still exists —
  /// which is exactly what an owner unlinking this register from the web admin
  /// looks like from here (the server revokes the refresh row and the
  /// workstation goes inactive). Land standalone with all data intact and say
  /// so, rather than dropping the cashier on a dead activation screen.
  ///
  /// Returns true when it handled the case.
  Future<bool> handleDeviceSessionExpired(SessionExpiredException e) async {
    if (e.flavor != AuthFlavor.device) return false;
    final ws = _activeWorkstation;
    if (ws == null) return false;
    await _applyLocalUnlink(ws, notice: _unlinkedByAdminNotice);
    return true;
  }

  static const _unlinkedByAdminNotice =
      'Касса отключена от платформы администратором. '
      'Данные сохранены — касса работает автономно.';

  // --- Hydrate / owner login --------------------------------------------

  Future<void> hydrate() async {
    final lockout = await _lockoutStore?.load();
    if (lockout != null) {
      _totalFailedAttempts = lockout.failedAttempts;
      final until = lockout.lockedUntil;
      if (until != null && until.isAfter(DateTime.now())) {
        _lockedUntil = until;
        _lockoutTimer?.cancel();
        _lockoutTimer = Timer(until.difference(DateTime.now()), () {
          _lockedUntil = null;
        });
      }
    }

    final wsInfo = await _workstation?.load();
    if (wsInfo == null) {
      // No workstation binding — standalone (автономный) register? (spec 03 R1)
      final standalone = await _standalone?.load();
      if (standalone != null) {
        _standaloneInfo = standalone;
        final hasOwner =
            await _localAuth?.hasAnyUser(standalone.tenantId) ?? false;
        if (!hasOwner) {
          // Skip was chosen but setup never finished (killed mid-wizard).
          state = const StandaloneSetupRequired();
          return;
        }
        await checkFirstRun();
        return;
      }
      state = const RegisterNotActivated();
      return;
    }

    final savedDevice = await _deviceTokens?.load();
    final deviceTokensUnusable = savedDevice == null ||
        (savedDevice.isAccessExpired && savedDevice.isRefreshExpired);
    if (deviceTokensUnusable) {
      await _workstation?.clear();
      await _tokens?.clear();
      await _deviceTokens?.clear();
      _activeWorkstation = null;
      state = const RegisterNotActivated();
      return;
    }

    _activeWorkstation = wsInfo;

    await _api.session?.useDeviceSession(savedDevice);

    final saved = await _tokens?.load();
    if (saved != null && !saved.isAccessExpired) {
      _ownerTenantId = saved.tenantId;
    }
    _savedCashierUserId = saved?.userId;

    try {
      _biometricAvailable = await _biometric.isAvailable();
    } on Object {
      _biometricAvailable = false;
    }

    state = RegisterActivated(wsInfo);
  }

  void _setLoginFailure(String msg) {
    final ws = _activeWorkstation;
    if (ws != null) {
      state = RegisterActivated(ws, error: msg);
    } else {
      state = AuthInitial(error: msg);
    }
  }

  Future<void> ownerLogin({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final resp = await _api.ownerLogin(email: email, password: password);
      final token = resp['access_token'] as String?;
      if (token == null || token.isEmpty) {
        _setLoginFailure('Сервер не вернул токен');
        return;
      }
      _ownerTenantId = resp['tenant_id'] as String?;
      try {
        await _api.session?.useUserSession(AuthTokens.fromJson(resp));
      } on Object catch (_) {
        // Token shape mismatch — non-fatal; in-memory state still works
        // until the access token expires.
      }
      _totalFailedAttempts = 0;
      _lockedUntil = null;
      _clearPersistedLockout();
      state = AuthAuthenticated(
        cashierId: (resp['user_id'] as String?) ?? '',
        cashierName: email,
        role: (resp['role'] as String?) ?? 'owner',
      );
    } on ApiException catch (e) {
      final msg = e.statusCode == 401
          ? 'Неверный email или пароль'
          : e.statusCode >= 500
              ? 'Ошибка сервера'
              : 'Не удалось войти (${e.statusCode})';
      _setLoginFailure(msg);
    } on Exception catch (_) {
      _setLoginFailure('Нет связи с сервером');
    }
  }

  // --- Lockout helpers --------------------------------------------------

  Duration _lockoutDuration() {
    final tier = (_totalFailedAttempts ~/ maxAttempts - 1)
        .clamp(0, _lockoutDurations.length - 1);
    return _lockoutDurations[tier];
  }

  void _startLockout() {
    final duration = _lockoutDuration();
    _lockedUntil = DateTime.now().add(duration);

    state = AuthInitial(
      failedAttempts: _totalFailedAttempts,
      lockedUntil: _lockedUntil,
      openShifts: _openShifts,
      error: 'Слишком много попыток. Подождите ${_formatDuration(duration)}',
    );

    unawaited(_lockoutStore?.save(LockoutState(
      failedAttempts: _totalFailedAttempts,
      lockedUntil: _lockedUntil,
    )));

    _lockoutTimer?.cancel();
    _lockoutTimer = Timer(duration, () {
      _lockedUntil = null;
    });
  }

  void _persistFailureCount() {
    unawaited(_lockoutStore?.save(LockoutState(
      failedAttempts: _totalFailedAttempts,
      lockedUntil: _lockedUntil,
    )));
  }

  void _clearPersistedLockout() {
    unawaited(_lockoutStore?.clear());
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes >= 1) return '${d.inMinutes} мин.';
    return '${d.inSeconds} сек.';
  }

  // --- Event-equivalent methods -----------------------------------------

  Future<void> checkFirstRun() async {
    // Standalone mode: the cashier grid comes from the local drift users
    // table — no server involved (spec 03 R1).
    if (isStandalone) {
      final standalone = _standaloneInfo!;
      final local = _localAuth;
      if (local == null) {
        state = const StandaloneSetupRequired(
            error: 'Локальная база недоступна — перезапустите кассу');
        return;
      }
      final cashiers = await local.listCashiers(standalone.tenantId);
      if (cashiers.isEmpty) {
        state = const StandaloneSetupRequired();
        return;
      }
      state = AuthInitial(cashiers: cashiers, openShifts: _openShifts);
      return;
    }

    try {
      final response = await _api.listCashiers();
      final cashiers = response['cashiers'] as List?;
      if (cashiers == null || cashiers.isEmpty) {
        state = const AuthInitial(isFirstRun: true);
        return;
      }
      final typed = cashiers.cast<Map<String, dynamic>>();
      await _loadOpenShifts();
      state = AuthInitial(cashiers: typed, openShifts: _openShifts);
    } on ApiException catch (e) {
      final ws = _activeWorkstation;
      if (ws == null) return;
      final msg = e.statusCode == 401
          ? 'Сессия устройства недействительна. Подключите кассу заново.'
          : e.statusCode >= 500
              ? 'Ошибка сервера — список кассиров недоступен'
              : 'Не удалось загрузить кассиров (${e.statusCode})';
      state = RegisterActivated(ws, error: msg);
    } on Exception catch (_) {
      final ws = _activeWorkstation;
      if (ws == null) return;
      state = RegisterActivated(ws,
          error: 'Нет связи с сервером — список кассиров недоступен');
    }
  }

  Future<void> _loadOpenShifts() async {
    try {
      final resp = await _api.listOpenShifts();
      final shifts = resp['shifts'] as List?;
      if (shifts == null) {
        _openShifts = {};
        return;
      }
      final map = <String, String>{};
      for (final s in shifts) {
        final cashierId = s['CashierID'] as String? ?? '';
        final openedAt = s['OpenedAt'] as String? ?? '';
        if (cashierId.isNotEmpty) {
          map[cashierId] = openedAt;
        }
      }
      _openShifts = map;
    } on Exception catch (_) {
      _openShifts = {};
    }
  }

  void selectCashierProfile(String cashierName) {
    final current = state;
    if (current is! AuthInitial) return;
    state = AuthInitial(
      cashiers: current.cashiers,
      openShifts: _openShifts,
      selectedCashierName: cashierName,
      failedAttempts: _totalFailedAttempts,
      lockedUntil: _lockedUntil,
    );
  }

  void createFirstCashier(String name, String pin) {
    // Legacy setup-wizard path. Registration now happens on the web admin.
    state = const AuthInitial(
        error: 'Регистрация выполняется в web-админке. На кассе только вход.');
  }

  Future<void> pinDigit(String digit) async {
    final current = state;
    if (current is! AuthInitial) return;
    if (current.isLockedOut) return;

    final newPin = current.pin + digit;
    if (newPin.length < 4) {
      state = AuthInitial(
        pin: newPin,
        isFirstRun: current.isFirstRun,
        cashiers: current.cashiers,
        openShifts: _openShifts,
        selectedCashierName: current.selectedCashierName,
        failedAttempts: _totalFailedAttempts,
        lockedUntil: _lockedUntil,
      );
      return;
    }

    await _attemptPinLogin(newPin, current);
  }

  Future<void> pinSubmit() async {
    final current = state;
    if (current is! AuthInitial) return;
    if (current.isLockedOut) return;
    if (current.pin.length != 4) return;
    await _attemptPinLogin(current.pin, current);
  }

  Future<void> _attemptPinLogin(String pin, AuthInitial current) async {
    state = const AuthLoading();

    // Standalone mode: verify against the local drift users table (bcrypt).
    // Reuses the same failed-attempt counters + escalating lockout as the
    // online path — offline is not a brute-force loophole.
    if (isStandalone) {
      final standalone = _standaloneInfo!;
      final selectedName = current.selectedCashierName ??
          ((current.cashiers.isNotEmpty)
              ? (current.cashiers.first['Name'] as String? ?? '')
              : '');
      final row = await _localAuth?.verifyPinByName(
        tenantId: standalone.tenantId,
        name: selectedName,
        pin: pin,
      );
      if (row != null) {
        _totalFailedAttempts = 0;
        _lockedUntil = null;
        _lockoutTimer?.cancel();
        _clearPersistedLockout();
        state = AuthAuthenticated(
          cashierId: row.id,
          cashierName: row.name,
          role: row.role,
        );
        return;
      }
      _totalFailedAttempts++;
      _persistFailureCount();
      if (_totalFailedAttempts > 0 && _totalFailedAttempts % maxAttempts == 0) {
        _startLockout();
      } else {
        final remaining = maxAttempts - (_totalFailedAttempts % maxAttempts);
        state = AuthInitial(
          error: _attemptsErrorMessage(remaining),
          cashiers: current.cashiers,
          openShifts: _openShifts,
          selectedCashierName: current.selectedCashierName,
          failedAttempts: _totalFailedAttempts,
          lockedUntil: _lockedUntil,
        );
      }
      return;
    }

    try {
      final tenantId = _activeWorkstation?.tenantId ?? _ownerTenantId;
      if (tenantId == null) {
        throw ApiException(
            401, 'Касса не подключена к платформе. Используйте код подключения.');
      }
      final selectedLogin = current.selectedCashierName ?? '';
      final response = await _api.cashierLogin(
        tenantId: tenantId,
        login: selectedLogin,
        pin: pin,
      );
      final cashier = (response['user'] as Map<String, dynamic>?) ?? response;

      _totalFailedAttempts = 0;
      _lockedUntil = null;
      _lockoutTimer?.cancel();
      _clearPersistedLockout();

      state = AuthAuthenticated(
        cashierId: cashier['ID'] as String? ?? '',
        cashierName: cashier['Name'] as String? ?? '',
        role: cashier['Role'] as String? ?? 'cashier',
      );
    } on ApiException catch (e) {
      _totalFailedAttempts++;
      _persistFailureCount();

      if (_totalFailedAttempts > 0 &&
          _totalFailedAttempts % maxAttempts == 0) {
        _startLockout();
      } else {
        final remaining = maxAttempts - (_totalFailedAttempts % maxAttempts);
        final errorMsg = e.statusCode == 401
            ? _attemptsErrorMessage(remaining)
            : 'Ошибка сервера';
        state = AuthInitial(
          error: errorMsg,
          cashiers: current.cashiers,
          openShifts: _openShifts,
          selectedCashierName: current.selectedCashierName,
          failedAttempts: _totalFailedAttempts,
        );
      }
    } on Exception catch (_) {
      state = AuthInitial(
        error: 'Нет связи с сервером',
        cashiers: current.cashiers,
        openShifts: _openShifts,
        selectedCashierName: current.selectedCashierName,
        failedAttempts: _totalFailedAttempts,
      );
    }
  }

  String _platformDeviceName() {
    if (kIsWeb) return 'POS Web';
    try {
      if (Platform.isAndroid) return 'POS Android';
      if (Platform.isIOS) return 'POS iOS';
      if (Platform.isMacOS) return 'POS macOS';
      if (Platform.isWindows) return 'POS Windows';
      if (Platform.isLinux) return 'POS Linux';
    } on Object {
      // Platform isn't available (unusual) — fall through.
    }
    return 'POS Register';
  }

  String _attemptsErrorMessage(int n) {
    final noun = Intl.plural(
      n,
      locale: 'ru',
      one: 'попытка',
      few: 'попытки',
      many: 'попыток',
      other: 'попыток',
    );
    return 'Неверный PIN ($n $noun)';
  }

  void pinBackspace() {
    final current = state;
    if (current is! AuthInitial || current.pin.isEmpty) return;
    if (current.isLockedOut) return;
    state = AuthInitial(
      pin: current.pin.substring(0, current.pin.length - 1),
      isFirstRun: current.isFirstRun,
      cashiers: current.cashiers,
      openShifts: _openShifts,
      selectedCashierName: current.selectedCashierName,
      failedAttempts: _totalFailedAttempts,
      lockedUntil: _lockedUntil,
    );
  }

  void pinClear() {
    final current = state;
    state = AuthInitial(
      isFirstRun: current is AuthInitial ? current.isFirstRun : false,
      openShifts: _openShifts,
      failedAttempts: _totalFailedAttempts,
      lockedUntil: _lockedUntil,
    );
  }

  void logout() {
    _ownerTenantId = null;
    unawaited(_api.session?.clearUserSession() ?? Future<void>.value());

    final ws = _activeWorkstation;
    if (ws != null) {
      state = RegisterActivated(ws);
    } else if (isStandalone) {
      // Standalone register: back to the local cashier grid, never to the
      // connect screen — the device stays autonomous after logout.
      state = const AuthLoading();
      unawaited(checkFirstRun());
    } else {
      state = const RegisterNotActivated();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════
//
// One provider per construction-time dependency. main.dart's ProviderScope
// overrides supply real instances; tests override with mocks per-container.

final authApiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('authApiClientProvider must be overridden at app root');
});

final authUserTokenStoreProvider = Provider<AuthTokenStore?>((ref) => null);

final authDeviceTokenStoreProvider = Provider<AuthTokenStore?>((ref) => null);

final authWorkstationStoreProvider = Provider<WorkstationStore?>((ref) => null);

final authDeviceIdStoreProvider = Provider<DeviceIdStore>((ref) => DeviceIdStore());

final authLockoutStoreProvider = Provider<LockoutStore?>((ref) => null);

final authBiometricServiceProvider =
    Provider<BiometricAuthService>((ref) => BiometricAuthService());

/// Standalone-mode persistence (spec 03). Null in tests that don't care.
final authStandaloneStoreProvider = Provider<StandaloneStore?>((ref) => null);

/// Local (drift-backed) auth used while the register is standalone.
final authLocalAuthServiceProvider = Provider<LocalAuthService?>((ref) => null);

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
