import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../services/api_client.dart';
import '../../../services/auth/auth_token_store.dart';
import '../../../services/auth/biometric_auth_service.dart';
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

/// Prompt biometric (Face ID / Touch ID / fingerprint) and, on success,
/// unlock the previously-stored access token to re-establish the session
/// without re-typing the PIN.
///
/// Pre-conditions: the user must have logged in via PIN at least once on
/// this device so that [AuthTokenStore] has a token pair to restore from.
/// If no token is saved, or the saved access token is expired, the handler
/// surfaces a clear error and leaves the UI on [RegisterActivated] so the
/// user can fall back to PIN.
class BiometricLoginRequested extends AuthEvent {}

// === States ===
//
// Every state extends Equatable so BlocBuilder's `==` short-circuits
// rebuilds when the same logical state is emitted twice. Without this,
// e.g. each PIN digit press emits a fresh `AuthInitial(...)` whose fields
// are otherwise unchanged, but the rebuild still fires because identity
// differs. Subclasses override `props` to list every field that
// participates in equality.

sealed class AuthState extends Equatable {}

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

  @override
  List<Object?> get props => [
        pin,
        error,
        isFirstRun,
        cashiers,
        openShifts,
        selectedCashierName,
        failedAttempts,
        lockedUntil,
      ];
}

class AuthLoading extends AuthState {
  @override
  List<Object?> get props => const [];
}

class AuthAuthenticated extends AuthState {
  final String cashierId;
  final String cashierName;
  final String role;
  AuthAuthenticated({
    required this.cashierId,
    required this.cashierName,
    required this.role,
  });

  @override
  List<Object?> get props => [cashierId, cashierName, role];
}

/// Fresh / never-activated device. Boot lands here the first time the app
/// runs; the [ActivationScreen] widget reacts to it.
class RegisterNotActivated extends AuthState {
  /// Error from the last failed activation attempt (wrong code, expired,
  /// already used, network). Null on the very first render.
  final String? error;
  final bool busy;
  RegisterNotActivated({this.error, this.busy = false});

  @override
  List<Object?> get props => [error, busy];
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

  @override
  List<Object?> get props => [workstation, error, busy];
}

// === BLoC ===

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _api;
  final AuthTokenStore? _tokens;
  /// Device JWT store. Persists the access + refresh pair issued by
  /// /api/register/activate so that authenticated calls (cashier list,
  /// cashier-login) work immediately on next boot without re-activation.
  /// Distinct from [_tokens] (user session) — survives cashier logout.
  final AuthTokenStore? _deviceTokens;
  final WorkstationStore? _workstation;
  // Non-nullable: a real DeviceIdStore (or one supplied by the test) is
  // always present so we never have to fall back to a literal device id.
  // Two registers sharing a fixed string would collide on the server's
  // uniqueness checks and either reject the second activation or silently
  // overwrite the first.
  final DeviceIdStore _deviceIdStore;
  final LockoutStore? _lockoutStore;
  final BiometricAuthService _biometric;

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

  /// User-id of the cashier whose session is currently persisted in
  /// [AuthTokenStore] (the "last logged-in cashier" on this device). Drives
  /// the per-tile Face ID badge in the cashier grid: only the matching
  /// tile renders the bio shortcut, since `BiometricLoginRequested` unlocks
  /// the saved session — not an arbitrary cashier's session.
  String? _savedCashierUserId;
  String? get savedCashierUserId => _savedCashierUserId;

  /// Whether the platform reports an enrolled biometric (Face ID / Touch ID
  /// / fingerprint). Probed once during hydrate; cached here so the grid
  /// doesn't have to pay a platform-channel round-trip per tile build.
  bool _biometricAvailable = false;
  bool get isBiometricAvailable => _biometricAvailable;

  /// Cached workstation info from the most recent activation / hydrate.
  /// Surfaced for the chrome bar on PinScreen so it can display the real
  /// store + terminal binding instead of a hardcoded placeholder.
  WorkstationInfo? get activeWorkstation => _activeWorkstation;

  AuthBloc(
    this._api, {
    AuthTokenStore? tokens,
    AuthTokenStore? deviceTokens,
    WorkstationStore? workstation,
    DeviceIdStore? deviceIdStore,
    LockoutStore? lockoutStore,
    BiometricAuthService? biometric,
  })  : _tokens = tokens,
        _deviceTokens = deviceTokens,
        _workstation = workstation,
        _deviceIdStore = deviceIdStore ?? DeviceIdStore(),
        _lockoutStore = lockoutStore,
        _biometric = biometric ?? BiometricAuthService(),
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
    on<BiometricLoginRequested>(_onBiometricLogin);
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
      // The cross-register race lands here too: if the same code was typed
      // into two devices, only one wins and the loser sees this. Hint at
      // that so the operator doesn't assume they're holding a stale code.
      return 'Код уже использован — возможно, на другой кассе. Получите новый в веб-админке.';
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
    // Re-entry guard. The TextField's Enter key bypasses the disabled-button
    // path, so two ActivateRegisterRequested events can land back-to-back.
    // Without this, the second call posts the now-consumed code and
    // surfaces a misleading "уже использован" on top of the just-succeeded
    // first call.
    final current = state;
    if (current is RegisterActivated) return;
    if (current is RegisterNotActivated && current.busy) return;

    final store = _workstation;
    // No `dev-unknown` fallback — _deviceIdStore is non-nullable now, so
    // every activation carries a unique UUID. A literal fallback would
    // collide across registers on the tenant and the server's uniqueness
    // checks would either reject the second activation or silently
    // overwrite the first.

    emit(RegisterNotActivated(busy: true));
    WorkstationInfo? info;
    // Device JWT pair returned by the server. Lifted out of the try-block so
    // the persistence section below can see them without restructuring.
    String? accessToken;
    String? refreshToken;
    String? accessExpiresAt;
    String? refreshExpiresAt;
    try {
      // Device fingerprint — stable UUID v4 held in platform secure storage.
      // The prior timestamp-based id was predictable to the ms and enabled
      // activation-code replay within the code's validity window.
      final deviceId = await _deviceIdStore.getOrCreate();
      final resp = await _api.activateRegister(
        code: event.code.trim().toUpperCase(),
        deviceId: deviceId,
        deviceName: _platformDeviceName(),
      );
      // Safe casts — if the server ever drops a field or returns null, fall
      // into a clear "bad response" path instead of letting a TypeError get
      // caught by the network branch and shown as "Нет связи с сервером".
      final wsId = resp['workstation_id'] as String?;
      final tnId = resp['tenant_id'] as String?;
      final stId = resp['store_id'] as String?;
      if (wsId == null || tnId == null || stId == null) {
        emit(RegisterNotActivated(
            error: 'Сервер вернул неполный ответ — обратитесь к администратору'));
        return;
      }
      // Tokens are mandatory in the new flow — without them the register
      // can't authenticate ANY follow-up call (cashier list, cashier-login).
      // Letting activation "succeed" without them lands the operator on a
      // dead PinScreen with an empty cashier list and a 401 in the logs.
      // The most common cause: the api container is running pre-device-JWT
      // code and didn't include the tokens in the response. Reject loudly
      // so the operator knows the server is stale.
      accessToken = resp['access_token'] as String?;
      refreshToken = resp['refresh_token'] as String?;
      accessExpiresAt = resp['access_expires_at'] as String?;
      refreshExpiresAt = resp['refresh_expires_at'] as String?;
      if (accessToken == null || accessToken.isEmpty
          || refreshToken == null || refreshToken.isEmpty
          || accessExpiresAt == null || refreshExpiresAt == null) {
        emit(RegisterNotActivated(
            error: 'Сервер не выдал токены устройства — '
                'возможно нужно обновить серверную часть.'));
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

    // Wire succeeded. Persistence is best-effort but the operator must be
    // told if it failed: the activation code on the server is now consumed,
    // so a cold-boot before we re-activate means they're stuck calling the
    // owner. Keychain writes fail on macOS without the Keychain Sharing
    // entitlement — that's the most common path here.
    _activeWorkstation = info;

    // Apply device JWT to the AuthSession immediately so the next call
    // (PinScreen → CheckFirstRun → listCashiers) carries Authorization.
    // useDeviceSession persists the row internally (keyed pos.device.tokens.v1)
    // and bumps the device-slot epoch.
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
            'Активация выполнена, но не сохранена на устройстве — '
            'не перезагружайте кассу до входа сотрудника.';
      }
    }

    try {
      await store?.save(info);
    } on Object {
      persistWarning ??=
          'Активация выполнена, но не сохранена на устройстве — '
          'не перезагружайте кассу до входа сотрудника.';
    }

    emit(RegisterActivated(info, error: persistWarning));
  }

  // --- Biometric login (reuse saved session) ----------------------------

  Future<void> _onBiometricLogin(
      BiometricLoginRequested event, Emitter<AuthState> emit) async {
    final ws = _activeWorkstation;
    if (ws == null) {
      emit(RegisterNotActivated(error: 'Сначала активируйте кассу'));
      return;
    }

    // Can't unlock a session we never had. Caller should hide the bio
    // button when tokens.load() == null; this guard is belt-and-braces.
    final saved = await _tokens?.load();
    if (saved == null) {
      emit(RegisterActivated(ws,
          error: 'Сначала войдите по PIN — Face ID запомнит сессию'));
      return;
    }
    if (saved.isAccessExpired) {
      // Could call /api/auth/refresh here once the client gets that method;
      // for now, PIN is the fallback. Short-lived cashier access tokens
      // mean this fires after ~15 min of idle — acceptable for MVP.
      emit(RegisterActivated(ws,
          error: 'Сессия истекла — войдите по PIN'));
      return;
    }

    final available = await _biometric.isAvailable();
    if (!available) {
      emit(RegisterActivated(ws,
          error: 'Биометрия не настроена на этом устройстве'));
      return;
    }

    emit(RegisterActivated(ws, busy: true));
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
        emit(AuthAuthenticated(
          cashierId: saved.userId ?? '',
          cashierName: saved.userId ?? 'cashier',
          role: saved.role ?? 'cashier',
        ));
      case BiometricOutcome.userCancelled:
        // Silent return — user dismissed deliberately, no error UI.
        emit(RegisterActivated(ws));
      case BiometricOutcome.notEnrolled:
        emit(RegisterActivated(ws,
            error: 'Добавьте отпечаток / Face ID в настройках устройства'));
      case BiometricOutcome.lockedOut:
      case BiometricOutcome.permanentlyLockedOut:
        emit(RegisterActivated(ws,
            error: 'Биометрия временно заблокирована — разблокируйте устройство паролем'));
      case BiometricOutcome.notSupported:
        emit(RegisterActivated(ws,
            error: 'Устройство не поддерживает биометрию'));
      case BiometricOutcome.otherError:
        emit(RegisterActivated(ws,
            error: 'Не удалось выполнить вход по биометрии'));
    }
  }

  Future<void> _onDeactivateRegister(
      DeactivateRegisterRequested event, Emitter<AuthState> emit) async {
    // Nuclear option — wipes workstation, device JWT, and any user session.
    // session.clearAll() clears both slots in-memory and on-disk in one call.
    await _api.session?.clearAll();
    _ownerTenantId = null;
    _activeWorkstation = null;
    await _workstation?.clear();
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
      _ownerTenantId = ws.tenantId;
      // Remember which cashier "owns" the saved session so the grid's
      // Face ID badge lands on the right tile next time.
      _savedCashierUserId = resp['user_id'] as String?;
      // Drop the user-session into AuthSession (persists + bumps user-slot
      // epoch). Device slot is untouched, so the cashier-grid keeps working
      // after a subsequent logout.
      try {
        await _api.session?.useUserSession(AuthTokens.fromJson(resp));
      } on Object catch (_) {
        // Non-fatal — session still has in-memory token via the failed write
        // path; persistence will retry on the next refresh.
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

    // Activation invariant: a workstation binding without a usable device
    // JWT pair is NOT really activated — every authenticated call (cashier
    // list, cashier-login) would 401. This case shows up in two ways:
    //   1. The device was activated under the pre-JWT anonymous flow, so
    //      no device tokens were ever saved.
    //   2. Both access + refresh tokens have expired (device offline for
    //      longer than the refresh window).
    // Either way the recovery is the same: wipe the stale binding and route
    // to ActivationScreen so the operator enters a fresh code. Without this
    // the register would show PinScreen with an empty cashier grid and no
    // way out.
    final savedDevice = await _deviceTokens?.load();
    final deviceTokensUnusable = savedDevice == null
        || (savedDevice.isAccessExpired && savedDevice.isRefreshExpired);
    if (deviceTokensUnusable) {
      await _workstation?.clear();
      await _tokens?.clear();
      await _deviceTokens?.clear();
      _activeWorkstation = null;
      emit(RegisterNotActivated());
      return;
    }

    _activeWorkstation = wsInfo;

    // Apply persisted device JWT so authenticated calls (cashier list,
    // cashier-login) work immediately. We hand the tokens to AuthSession
    // unconditionally — if the access is expired but refresh still valid,
    // the first 401 reactively refreshes via /api/register/refresh and
    // retries the original request. Boot stays fast and offline-tolerant
    // (offline → request fails fast and the slot stays intact).
    await _api.session?.useDeviceSession(savedDevice);

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
    // Remember the last-logged-in cashier even if the access token is now
    // expired — the refresh token may still be valid, and we want the Face
    // ID badge to point at the right tile so they can re-unlock without
    // typing their PIN.
    _savedCashierUserId = saved?.userId;

    // Probe biometric availability once at boot. The result is cached in
    // [_biometricAvailable] for the rest of the session — the platform
    // value doesn't change at runtime in any way that matters for a POS.
    try {
      _biometricAvailable = await _biometric.isAvailable();
    } on Object {
      _biometricAvailable = false;
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
      _ownerTenantId = resp['tenant_id'] as String?;
      // Hand the user-session pair to AuthSession (persists + bumps user-slot
      // epoch). Device slot is independent — survives the owner switching to
      // a cashier session and back.
      try {
        await _api.session?.useUserSession(AuthTokens.fromJson(resp));
      } on Object catch (_) {
        // Token shape mismatch — non-fatal; in-memory state still works
        // until the access token expires.
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
    } on ApiException catch (e) {
      // Don't swallow auth / server failures silently — without this the
      // grid renders empty (just admin + "+ new cashier") and the operator
      // has no idea why.
      final ws = _activeWorkstation;
      if (ws == null) return;
      final msg = e.statusCode == 401
          // Most common: device JWT missing / expired. Easiest recovery is
          // owner mints a fresh activation code and the register re-binds.
          ? 'Сессия устройства недействительна. Активируйте кассу заново.'
          : e.statusCode >= 500
              ? 'Ошибка сервера — список кассиров недоступен'
              : 'Не удалось загрузить кассиров (${e.statusCode})';
      emit(RegisterActivated(ws, error: msg));
    } on Exception catch (_) {
      final ws = _activeWorkstation;
      if (ws == null) return;
      emit(RegisterActivated(ws,
          error: 'Нет связи с сервером — список кассиров недоступен'));
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
        // Always thread the lockout deadline through. Without this the
        // UI countdown vanishes the moment a digit is queued during a
        // lockout race — a real bug observed on slow taps.
        lockedUntil: _lockedUntil,
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
    // PIN-flavor cashier login (digit-4 auto-submit + OK keypad path).
    // Pulls tenant_id from the activated workstation rather than from
    // _ownerTenantId — the latter is cleared on LogoutRequested, so
    // "Сменить кассира" (which logs out first) would otherwise fail
    // with "войдите как владелец". An activated register always has
    // _activeWorkstation set; fall back to the owner-driven path for
    // legacy callers that haven't activated.
    emit(AuthLoading());
    try {
      final tenantId = _activeWorkstation?.tenantId ?? _ownerTenantId;
      if (tenantId == null) {
        throw ApiException(
            401, 'Касса не активирована. Используйте код активации.');
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
            ? _attemptsErrorMessage(remaining)
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

  /// Russian-localized "wrong PIN, $n attempts remaining" message.
  ///
  /// Uses [Intl.plural] which follows the Unicode CLDR plural rules. The
  /// previous hand-rolled suffix function used the standard 1 / 2-4 / 5+
  /// rule, which is correct for most numbers but wrong for the 11..14 range
  /// (these inflect as "many", not "few", because of the Russian rule
  /// `n%100 in 11..14 → many`). With CLDR rules, n=11..14 correctly produces
  /// `попыток` instead of `попытки`.
  ///
  /// The message remains hardcoded Russian here because the bloc has no
  /// `BuildContext` to look up an `AppLocalizations` instance; the broader
  /// review tracks fully delegating user-facing strings to the UI layer.
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
    // Drop the cashier / owner session but keep the device activated.
    // AuthSession.clearUserSession() clears the user slot in-memory AND on
    // disk; the device slot stays loaded, so the cashier-grid keeps making
    // authenticated calls without a "swap" step. Pre-AuthSession we had to
    // re-read the device JWT from secure storage to put it back in the
    // single-token field; the two-slot model makes that a no-op.
    _ownerTenantId = null;
    unawaited(_api.session?.clearUserSession() ?? Future<void>.value());

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
