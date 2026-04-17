import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/api_client.dart';
import '../../../services/auth/auth_token_store.dart';
import '../../../services/auth/device_id_store.dart';
import '../../../services/auth/lockout_store.dart';
import '../../../services/auth/workstation_store.dart';

// === Events ===

sealed class AuthEvent {}

class PinDigitPressed extends AuthEvent {
  final String digit;
  PinDigitPressed(this.digit);
}

class PinBackspacePressed extends AuthEvent {}
/// Explicit submit fallback for the PIN keypad's OK key. The digit-4-autoloin
/// path covers the happy case; this event exists so a user who backspaces
/// and re-enters can still tap OK to re-submit without adding a 5th keypress.
class PinSubmitPressed extends AuthEvent {}
class PinCleared extends AuthEvent {}
class LogoutRequested extends AuthEvent {}
class CheckFirstRun extends AuthEvent {}

class CreateFirstCashier extends AuthEvent {
  final String name;
  final String pin;
  CreateFirstCashier(this.name, this.pin);
}

class SelectCashierProfile extends AuthEvent {
  final String cashierName;
  SelectCashierProfile(this.cashierName);
}

/// Owner / admin login (email + password). Primary entry point on first
/// boot — registration is web-admin only, the register no longer signs up
/// tenants. Hits `/api/auth/login` on .NET central and persists the
/// returned tokens via [AuthTokenStore].
class OwnerLoginRequested extends AuthEvent {
  final String email;
  final String password;
  OwnerLoginRequested({required this.email, required this.password});
}

/// Restore a previously saved session (called once at app boot).
/// Three-way hydrate:
///   - no workstation → [RegisterNotActivated]
///   - workstation + valid user token → [AuthAuthenticated]
///   - workstation + no user token → [RegisterActivated] (show login chooser)
class HydrateSession extends AuthEvent {}

/// Submit an activation code to `/api/register/activate`. On success stores
/// the workstation payload + transitions to [RegisterActivated].
class ActivateRegisterRequested extends AuthEvent {
  final String code;
  ActivateRegisterRequested(this.code);
}

/// Cashier / manager PIN login against the activated device. Requires
/// [RegisterActivated] as the current state (tenant id comes from there).
class CashierLoginRequested extends AuthEvent {
  final String login;
  final String pin;
  CashierLoginRequested({required this.login, required this.pin});
}

/// Wipe the activation payload (tenant+store binding) and return to the
/// activation screen. Dangerous — only the owner should surface this.
class DeactivateRegisterRequested extends AuthEvent {}

// === States ===

sealed class AuthState {}

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

  AuthInitial({
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
}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String cashierId;
  final String cashierName;
  final String role;
  AuthAuthenticated({
    required this.cashierId,
    required this.cashierName,
    required this.role,
  });
}

/// Fresh / never-activated device. Boot lands here the first time the app
/// runs; the [ActivationScreen] widget reacts to it.
class RegisterNotActivated extends AuthState {
  /// Error from the last failed activation attempt (wrong code, expired,
  /// already used, network). Null on the very first render.
  final String? error;
  final bool busy;
  RegisterNotActivated({this.error, this.busy = false});
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
  RegisterActivated(this.workstation, {this.error, this.busy = false});
}

// === BLoC ===

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _api;
  final AuthTokenStore? _tokens;
  final WorkstationStore? _workstation;
  final DeviceIdStore? _deviceIdStore;
  final LockoutStore? _lockoutStore;

  /// Cached workstation info after activation — populated by hydrate /
  /// activation handlers so cashier-login has access to tenant_id without
  /// a secure-storage read on every keystroke.
  WorkstationInfo? _activeWorkstation;

  /// Max failed attempts before lockout.
  static const int maxAttempts = 5;

  /// Lockout durations by tier (escalating).
  static const _lockoutDurations = [
    Duration(seconds: 30),  // after 5 failures
    Duration(minutes: 2),   // after 10
    Duration(minutes: 5),   // after 15
    Duration(minutes: 15),  // after 20+
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

  AuthBloc(
    this._api, {
    AuthTokenStore? tokens,
    WorkstationStore? workstation,
    DeviceIdStore? deviceIdStore,
    LockoutStore? lockoutStore,
  })  : _tokens = tokens,
        _workstation = workstation,
        _deviceIdStore = deviceIdStore,
        _lockoutStore = lockoutStore,
        super(AuthInitial()) {
    on<PinDigitPressed>(_onDigitPressed);
    on<PinBackspacePressed>(_onBackspace);
    on<PinSubmitPressed>(_onSubmitPressed);
    on<PinCleared>(_onCleared);
    on<LogoutRequested>(_onLogout);
    on<CheckFirstRun>(_onCheckFirstRun);
    on<CreateFirstCashier>(_onCreateFirst);
    on<SelectCashierProfile>(_onSelectProfile);
    on<OwnerLoginRequested>(_onOwnerLogin);
    on<HydrateSession>(_onHydrateSession);
    on<ActivateRegisterRequested>(_onActivateRegister);
    on<CashierLoginRequested>(_onCashierLogin);
    on<DeactivateRegisterRequested>(_onDeactivateRegister);
  }

  // --- Error helpers -----------------------------------------------------

  /// Pull `{"error": "…"}` out of an ApiException body. The central
  /// `ErrorEnvelopeMiddleware` emits this shape consistently; when the
  /// body isn't JSON or doesn't have the field, returns null.
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

  /// Map a failed `POST /api/register/activate` to a short Russian message
  /// the operator can act on. The server uses 401 for "already used / bad
  /// code" today (semantically wonky — should be 410 Gone — but we handle
  /// what the server actually sends).
  String _mapActivationError(int status, String? serverMsg) {
    final lc = (serverMsg ?? '').toLowerCase();
    if (lc.contains('already used')) {
      return 'Код уже использован. Получите новый в веб-админке.';
    }
    if (lc.contains('expired') || lc.contains('истёк') || lc.contains('истек')) {
      return 'Код истёк. Получите новый в веб-админке.';
    }
    if (lc.contains('not found') || lc.contains('unknown')) {
      return 'Код не найден. Проверьте, что набрали правильно.';
    }
    // Fall back to the server's own wording when it's there — usually
    // clearer than anything we'd invent.
    if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;
    switch (status) {
      case 400: return 'Неверный формат кода';
      case 401: return 'Код отклонён — возможно уже использован или истёк';
      case 404:
      case 410: return 'Код не найден или уже использован';
      default:  return status >= 500
          ? 'Ошибка сервера'
          : 'Активация не удалась ($status)';
    }
  }

  // --- Device activation (first boot) -------------------------------------

  Future<void> _onActivateRegister(
      ActivateRegisterRequested event, Emitter<AuthState> emit) async {
    final store = _workstation;
    emit(RegisterNotActivated(busy: true));
    WorkstationInfo? info;
    try {
      // Device fingerprint — stable UUID v4 held in platform secure storage.
      // The prior timestamp-based id was predictable to the ms and enabled
      // activation-code replay within the code's validity window.
      final deviceId = await (_deviceIdStore?.getOrCreate() ??
          Future.value('dev-unknown'));
      final resp = await _api.activateRegister(
        code: event.code.trim().toUpperCase(),
        deviceId: deviceId,
        deviceName: _platformDeviceName(),
      );
      info = WorkstationInfo(
        workstationId: resp['workstation_id'] as String,
        tenantId: resp['tenant_id'] as String,
        storeId: resp['store_id'] as String,
        storeName: (resp['store_name'] as String?) ?? '',
        activatedAt: DateTime.now().toUtc(),
      );
    } on ApiException catch (e) {
      // Map to a short operator-facing message. The server returns 401 for
      // "code already used / expired" (semantically wonky, but that's what
      // ActivateRegisterHandler does today). We look at both the status
      // AND the body's {"error": "…"} field so a new server message can
      // reach the UI without a bloc change.
      final serverMsg = _extractServerError(e.body);
      final msg = _mapActivationError(e.statusCode, serverMsg);
      emit(RegisterNotActivated(error: msg));
      return;
    } on Exception catch (_) {
      emit(RegisterNotActivated(error: 'Нет связи с сервером'));
      return;
    }
    // Wire succeeded — the rest (secure-storage save) is best-effort.
    // Keychain writes can fail on macOS without the Keychain Sharing
    // entitlement; we don't want to force the operator to re-type the
    // code just because persistence is off. In-memory state is valid for
    // the current session; next cold boot will re-prompt if keychain
    // actually stayed unwritten.
    _activeWorkstation = info;
    try {
      await store?.save(info);
    } on Object catch (_) {
      // Non-fatal — log-only would be ideal but we don't have a sink yet.
      // The user stays on the current session; if they restart before
      // we fix persistence, they'll re-activate with a fresh code.
    }
    emit(RegisterActivated(info));
  }

  Future<void> _onDeactivateRegister(
      DeactivateRegisterRequested event, Emitter<AuthState> emit) async {
    // Nuclear option — wipes workstation AND any user session.
    _api.setAccessToken(null);
    _ownerTenantId = null;
    _activeWorkstation = null;
    await _workstation?.clear();
    await _tokens?.clear();
    emit(RegisterNotActivated());
  }

  // --- Cashier login (after activation) -----------------------------------

  Future<void> _onCashierLogin(
      CashierLoginRequested event, Emitter<AuthState> emit) async {
    final ws = _activeWorkstation;
    if (ws == null) {
      emit(RegisterNotActivated(error: 'Сначала активируйте кассу'));
      return;
    }
    emit(RegisterActivated(ws, busy: true));
    try {
      final resp = await _api.cashierLogin(
        tenantId: ws.tenantId,
        login: event.login,
        pin: event.pin,
        deviceId: ws.workstationId,
      );
      final token = resp['access_token'] as String?;
      if (token == null || token.isEmpty) {
        emit(RegisterActivated(ws, error: 'Сервер не вернул токен'));
        return;
      }
      _api.setAccessToken(token);
      _ownerTenantId = ws.tenantId;
      try {
        await _tokens?.save(AuthTokens.fromJson(resp));
      } on Object catch (_) {
        // Non-fatal — keep in-memory token.
      }
      _totalFailedAttempts = 0;
      _lockedUntil = null;
      _clearPersistedLockout();
      emit(AuthAuthenticated(
        cashierId: (resp['user_id'] as String?) ?? '',
        cashierName: event.login,
        role: (resp['role'] as String?) ?? 'cashier',
      ));
    } on ApiException catch (e) {
      final msg = e.statusCode == 401
          ? 'Неверный логин или PIN'
          : e.statusCode == 423
              ? 'Слишком много попыток — попробуйте позже'
              : e.statusCode >= 500
                  ? 'Ошибка сервера'
                  : 'Не удалось войти (${e.statusCode})';
      // Only count actual credential failures toward the lockout — a 500 or
      // network blip should not lock the operator out of their own device.
      if (e.statusCode == 401) {
        _totalFailedAttempts++;
        _persistFailureCount();
      }
      emit(RegisterActivated(ws, error: msg));
    } on Exception catch (_) {
      emit(RegisterActivated(ws, error: 'Нет связи с сервером'));
    }
  }

  // --- Owner login (primary boot path on the register) -------------------

  Future<void> _onHydrateSession(
      HydrateSession event, Emitter<AuthState> emit) async {
    // Rehydrate the persistent lockout counter BEFORE any state emits — if
    // the user was mid-lockout at last shutdown the new UI must honour it.
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

    // Activation first — a device without it can't do anything.
    final wsInfo = await _workstation?.load();
    if (wsInfo == null) {
      emit(RegisterNotActivated());
      return;
    }
    _activeWorkstation = wsInfo;

    // Cold-boot policy: ALWAYS require a PIN / password. Even if a valid
    // access token is persisted, a stolen device must not auto-authenticate
    // into the active cashier's session. Background sync can still use the
    // stored token via [AuthTokenStore] directly; this handler only controls
    // whether the UI lands on the login chooser vs. the main shell.
    //
    // Tokens are still loaded into the in-memory ApiClient so the login
    // chooser can prefill the tenant id without a second round-trip when
    // the cashier types their PIN.
    final saved = await _tokens?.load();
    if (saved != null && !saved.isAccessExpired) {
      _ownerTenantId = saved.tenantId;
    }
    emit(RegisterActivated(wsInfo));
  }

  /// Emit `RegisterActivated(error)` when the device is already activated,
  /// `AuthInitial(error)` otherwise. Used by owner-login failure paths so
  /// the UI lands on the login chooser instead of bouncing to a blank
  /// "pre-activation" state.
  void _emitLoginFailure(String msg, Emitter<AuthState> emit) {
    final ws = _activeWorkstation;
    if (ws != null) {
      emit(RegisterActivated(ws, error: msg));
    } else {
      emit(AuthInitial(error: msg));
    }
  }

  Future<void> _onOwnerLogin(
      OwnerLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final resp = await _api.ownerLogin(
        email: event.email,
        password: event.password,
      );
      final token = resp['access_token'] as String?;
      if (token == null || token.isEmpty) {
        _emitLoginFailure('Сервер не вернул токен', emit);
        return;
      }
      _api.setAccessToken(token);
      _ownerTenantId = resp['tenant_id'] as String?;
      // Persist for subsequent boots.
      final store = _tokens;
      if (store != null) {
        try {
          await store.save(AuthTokens.fromJson(resp));
        } on Object catch (_) {
          // Token shape mismatch — non-fatal, keep the in-memory token.
        }
      }
      _totalFailedAttempts = 0;
      _lockedUntil = null;
      _clearPersistedLockout();
      emit(AuthAuthenticated(
        cashierId: (resp['user_id'] as String?) ?? '',
        cashierName: event.email,
        role: (resp['role'] as String?) ?? 'owner',
      ));
    } on ApiException catch (e) {
      final msg = e.statusCode == 401
          ? 'Неверный email или пароль'
          : e.statusCode >= 500
              ? 'Ошибка сервера'
              : 'Не удалось войти (${e.statusCode})';
      _emitLoginFailure(msg, emit);
    } on Exception catch (_) {
      _emitLoginFailure('Нет связи с сервером', emit);
    }
  }

  @override
  Future<void> close() {
    _lockoutTimer?.cancel();
    return super.close();
  }

  Duration _lockoutDuration() {
    final tier = (_totalFailedAttempts ~/ maxAttempts - 1)
        .clamp(0, _lockoutDurations.length - 1);
    return _lockoutDurations[tier];
  }

  void _startLockout(Emitter<AuthState> emit) {
    final duration = _lockoutDuration();
    _lockedUntil = DateTime.now().add(duration);

    emit(AuthInitial(
      failedAttempts: _totalFailedAttempts,
      lockedUntil: _lockedUntil,
      openShifts: _openShifts,
      error: 'Слишком много попыток. Подождите ${_formatDuration(duration)}',
    ));

    // Persist so the counter isn't reset by force-stopping the app.
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

  // --- Event Handlers ---

  Future<void> _onCheckFirstRun(
      CheckFirstRun event, Emitter<AuthState> emit) async {
    try {
      final response = await _api.listCashiers();
      final cashiers = response['cashiers'] as List?;
      if (cashiers == null || cashiers.isEmpty) {
        emit(AuthInitial(isFirstRun: true));
        return;
      }

      final typed = cashiers.cast<Map<String, dynamic>>();

      // Fetch open shifts in parallel
      await _loadOpenShifts();

      emit(AuthInitial(cashiers: typed, openShifts: _openShifts));
    } on Exception catch (_) {}
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

  void _onSelectProfile(SelectCashierProfile event, Emitter<AuthState> emit) {
    final current = state;
    if (current is! AuthInitial) return;
    emit(AuthInitial(
      cashiers: current.cashiers,
      openShifts: _openShifts,
      selectedCashierName: event.cashierName,
      failedAttempts: _totalFailedAttempts,
      lockedUntil: _lockedUntil,
    ));
  }

  Future<void> _onCreateFirst(
      CreateFirstCashier event, Emitter<AuthState> emit) async {
    // Legacy setup-wizard path. Registration now happens on the web admin —
    // see SignupPage on the React side. The wizard is no longer reachable
    // from the boot flow; keep the handler so an accidental dispatch
    // surfaces a clear message instead of crashing.
    emit(AuthInitial(error: 'Регистрация выполняется в web-админке. На кассе только вход.'));
  }

  Future<void> _onDigitPressed(
      PinDigitPressed event, Emitter<AuthState> emit) async {
    final current = state;
    if (current is! AuthInitial) return;

    // Block input during lockout
    if (current.isLockedOut) return;

    final newPin = current.pin + event.digit;
    if (newPin.length < 4) {
      emit(AuthInitial(
        pin: newPin,
        isFirstRun: current.isFirstRun,
        cashiers: current.cashiers,
        openShifts: _openShifts,
        selectedCashierName: current.selectedCashierName,
        failedAttempts: _totalFailedAttempts,
      ));
      return;
    }

    // 4 digits entered — attempt login via the shared submission path.
    await _attemptPinLogin(newPin, current, emit);
  }

  /// Explicit-submit handler for the OK keypad key. Only runs login when
  /// the current PIN is exactly 4 digits — tapping OK with 0-3 digits is
  /// a no-op (same guarantee the plan's P0-1 calls out).
  Future<void> _onSubmitPressed(
      PinSubmitPressed event, Emitter<AuthState> emit) async {
    final current = state;
    if (current is! AuthInitial) return;
    if (current.isLockedOut) return;
    if (current.pin.length != 4) return;
    await _attemptPinLogin(current.pin, current, emit);
  }

  /// Shared cashier-login submission. Called both from the digit-4 autologin
  /// path and from the explicit PinSubmitPressed (OK key) path.
  Future<void> _attemptPinLogin(
      String pin, AuthInitial current, Emitter<AuthState> emit) async {
    // TODO(P2): wire to /api/auth/cashier-login {tenant_id, login, pin}.
    // For now the boot path doesn't reach here (we go owner-first via
    // OwnerLoginScreen), so the PIN screen is dormant. Surface a clear
    // message if anyone hits it.
    emit(AuthLoading());
    try {
      final tenantId = _ownerTenantId;
      if (tenantId == null) {
        throw ApiException(
            401, 'Войдите как владелец, затем выберите кассира из списка');
      }
      final selectedLogin = current.selectedCashierName ?? '';
      final response = await _api.cashierLogin(
        tenantId: tenantId,
        login: selectedLogin,
        pin: pin,
      );
      final cashier = (response['user'] as Map<String, dynamic>?) ?? response;

      // Success — reset all counters
      _totalFailedAttempts = 0;
      _lockedUntil = null;
      _lockoutTimer?.cancel();
      _clearPersistedLockout();

      emit(AuthAuthenticated(
        cashierId: cashier['ID'] as String? ?? '',
        cashierName: cashier['Name'] as String? ?? '',
        role: cashier['Role'] as String? ?? 'cashier',
      ));
    } on ApiException catch (e) {
      _totalFailedAttempts++;
      _persistFailureCount();

      // Check if we've hit a lockout threshold
      if (_totalFailedAttempts > 0 &&
          _totalFailedAttempts % maxAttempts == 0) {
        _startLockout(emit);
      } else {
        final remaining = maxAttempts - (_totalFailedAttempts % maxAttempts);
        final errorMsg = e.statusCode == 401
            ? 'Неверный PIN ($remaining попыт${_pluralSuffix(remaining)})'
            : 'Ошибка сервера';
        emit(AuthInitial(
          error: errorMsg,
          cashiers: current.cashiers,
          openShifts: _openShifts,
          selectedCashierName: current.selectedCashierName,
          failedAttempts: _totalFailedAttempts,
        ));
      }
    } on Exception catch (_) {
      emit(AuthInitial(
        error: 'Нет связи с сервером',
        cashiers: current.cashiers,
        openShifts: _openShifts,
        selectedCashierName: current.selectedCashierName,
        failedAttempts: _totalFailedAttempts,
      ));
    }
  }

  /// Platform-derived human-readable device name. Server uses this only as
  /// a display hint, but it still shouldn't lie — the prior hardcoded
  /// 'POS macOS' showed up on Android / Linux / Windows registers too.
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

  String _pluralSuffix(int n) {
    if (n == 1) return 'ка';
    if (n >= 2 && n <= 4) return 'ки';
    return 'ок';
  }

  void _onBackspace(PinBackspacePressed event, Emitter<AuthState> emit) {
    final current = state;
    if (current is! AuthInitial || current.pin.isEmpty) return;
    if (current.isLockedOut) return;
    emit(AuthInitial(
      pin: current.pin.substring(0, current.pin.length - 1),
      isFirstRun: current.isFirstRun,
      cashiers: current.cashiers,
      openShifts: _openShifts,
      selectedCashierName: current.selectedCashierName,
      failedAttempts: _totalFailedAttempts,
      lockedUntil: _lockedUntil,
    ));
  }

  void _onCleared(PinCleared event, Emitter<AuthState> emit) {
    final current = state;
    emit(AuthInitial(
      isFirstRun: current is AuthInitial ? current.isFirstRun : false,
      openShifts: _openShifts,
      failedAttempts: _totalFailedAttempts,
      lockedUntil: _lockedUntil,
    ));
  }

  void _onLogout(LogoutRequested event, Emitter<AuthState> emit) {
    // Drop in-memory + on-wire credentials. Activation stays — the user
    // is just signing out, not un-activating the register. Persisted
    // tokens get cleared best-effort (fire-and-forget; failure here just
    // means the next boot will hydrate stale tokens that the server then
    // rejects, kicking the user back to the login screen anyway).
    _api.setAccessToken(null);
    _ownerTenantId = null;
    _tokens?.clear();

    final ws = _activeWorkstation;
    if (ws != null) {
      // Most common path — land on the login chooser for the same store.
      emit(RegisterActivated(ws));
    } else {
      // Edge case: logout fired before hydrate completed. Treat as
      // un-activated and let the boot flow re-hydrate.
      emit(RegisterNotActivated());
    }
  }
}
