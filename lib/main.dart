import 'dart:async' show Timer, runZonedGuarded, unawaited;
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/foundation.dart'
    show FlutterError, FlutterErrorDetails, kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'core/constants/app_constants.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/hifi.dart';
import 'core/widgets/sync_status_chip.dart';
import 'core/feature_flags.dart';
import 'data/database.dart';
import 'services/api_client.dart';
import 'package:http/http.dart' as http;
import 'services/auth/auth_session.dart';
import 'services/auth/auth_token_store.dart';
import 'services/auth/database_key_store.dart';
import 'services/auth/device_fingerprint.dart';
import 'services/auth/device_id_store.dart';
import 'services/auth/lockout_store.dart';
import 'services/auth/workstation_store.dart';
import 'services/locale/locale_store.dart';
import 'services/auth/bcrypt_pin_verifier.dart';
import 'services/products/product_catalog_service.dart';
import 'services/sales/sales_service.dart';
import 'services/sync/sync_status_service.dart';
import 'services/override/manager_override_service.dart';
import 'services/override/oversell_guard.dart';
import 'data/repositories/cashier_repository.dart';
import 'data/repositories/stock_movement_repository.dart';
import 'features/sales/sales_guards.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/screens/owner_login_screen.dart';
import 'features/auth/screens/activation_screen.dart';
import 'features/auth/screens/pin_screen.dart';
import 'features/sales/bloc/sales_bloc.dart';
import 'features/sales/screens/pos_screen.dart';
import 'features/products/screens/products_screen.dart';
import 'features/users/screens/cashiers_screen.dart';
import 'features/sales/screens/shift_screen.dart';
import 'features/clients/screens/debts_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/analytics/screens/analytics_screen.dart';
import 'features/delivery/screens/delivery_screen.dart';
import 'features/approval/screens/approval_screen.dart';
import 'features/audit/screens/audit_screen.dart';

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

void main() {
  // runZonedGuarded catches async errors that escape both
  // FlutterError.onError (framework lifecycle) and
  // PlatformDispatcher.instance.onError (engine-level). Stream subscriptions
  // and Timer callbacks that throw without an explicit handler land here —
  // without this wrapper they would silently disappear in release builds.
  // WidgetsFlutterBinding.ensureInitialized() must run inside the same zone
  // as runApp so hot-reload state survives across reloads.
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Refuse to boot a release build that was compiled with a cleartext host
    // (POS_API_HOST=http://...). The register would otherwise silently send
    // JWTs, PINs, and full sync payloads in the clear on a production network.
    AppConstants.assertApiHostIsSecure(isReleaseMode: kReleaseMode);

    // Global error plumbing. Without these, uncaught Flutter framework errors
    // either paint a red screen (debug) or a blank grey screen (release) and
    // never surface to operators / support. For a fiscal device that swallows
    // sale-path failures silently, that is unacceptable.
    // BLOCKER FOR BETA: wire to Sentry / Crashlytics so crashes leave a
    // remote breadcrumb. Until then we route every error through
    // `developer.log` so the OS log stream (Android logcat / iOS os_log /
    // desktop stderr) at least retains a trace in release builds — unlike
    // `debugPrint` which is a no-op outside debug.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      developer.log(
        details.exceptionAsString(),
        name: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      developer.log('uncaught platform error', name: 'PlatformError', error: error, stackTrace: stack);
      return true; // swallow — UI error screen shown via ErrorWidget.builder
    };
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kReleaseMode) {
        return const _FatalErrorScreen();
      }
      return ErrorWidget(details.exception);
    };

    // BLoC-level error observer. Without this, exceptions thrown inside an
    // event handler land in the default BlocObserver.onError which only
    // prints in debug — production loses bloc errors entirely. Forward to
    // Sentry / Crashlytics here once enabled.
    Bloc.observer = _AppBlocObserver();

    if (_isDesktop) {
      await windowManager.ensureInitialized();
      await windowManager.setFullScreen(true);
    }
    runApp(const PosApp());
  }, (Object error, StackTrace stack) {
    // BLOCKER FOR BETA: wire to Sentry / Crashlytics. Until then we route
    // through developer.log so the OS log stream retains a trace in
    // release builds — debugPrint is a no-op outside debug.
    developer.log('uncaught zone error', name: 'ZoneError', error: error, stackTrace: stack);
  });
}

/// Forwards every bloc-level exception to the same crash-reporting pipeline
/// as the framework / async error hooks above. Kept private — registered
/// once via `Bloc.observer` in [main].
class _AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase<Object?> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    // BLOCKER FOR BETA: wire to Sentry / Crashlytics. developer.log
    // makes bloc errors visible in the platform log stream in release
    // builds (logcat / os_log / desktop stderr) — debugPrint is a no-op.
    developer.log(
      'bloc error',
      name: 'BlocError.${bloc.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Branded last-resort screen when the widget tree itself fails to build in
/// release. Operators get a clear instruction rather than a blank grey frame.
class _FatalErrorScreen extends StatelessWidget {
  const _FatalErrorScreen();

  @override
  Widget build(BuildContext context) {
    // Rendered from ErrorWidget.builder, which runs OUTSIDE the
    // MaterialApp's localizations tree — AppLocalizations.of(context) is
    // unavailable here. We can't pick a locale at runtime, so we show
    // both Russian and Kazakh stacked. The two-line block is short
    // enough that bilingual presentation isn't worse than picking one.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFF111827),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Произошла ошибка. Перезапустите приложение. '
              'Если проблема повторяется — обратитесь в поддержку.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Қате орын алды. Қолданбаны қайта іске қосыңыз. '
              'Қайталанса — қолдау қызметіне хабарласыңыз.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFC4C6CD), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class PosApp extends StatefulWidget {
  const PosApp({super.key});
  @override
  State<PosApp> createState() => _PosAppState();
}

class _PosAppState extends State<PosApp> {
  late final ApiClient _apiClient;
  late final AuthSession _authSession;
  late final AppDatabase _db;
  late final AuthTokenStore _tokenStore;
  /// Separate AuthTokenStore instance keyed under [AuthTokenStore.deviceKey].
  /// Holds the device JWT issued by /api/register/activate so authenticated
  /// calls (cashier list, cashier-login) work across cashier-logout boundaries.
  late final AuthTokenStore _deviceTokenStore;
  late final WorkstationStore _workstationStore;
  late final DeviceIdStore _deviceIdStore;
  late final LockoutStore _lockoutStore;
  late final LocaleStore _localeStore;
  late final SyncStatusService _syncStatusService;

  /// Current operator-selected UI locale. Defaults to `'ru'` (Kazakhstan
  /// retail-floor default); flipped to `'kk'` via the chrome bar locale
  /// chip and persisted across boots by [LocaleStore]. The async load in
  /// [initState] may transition this once if a different locale was saved
  /// previously.
  String _currentLocale = 'ru';

  /// Memoised SalesGuards bundle. Built once in [initState] and rebuilt
  /// only when `_activeTenantId` / `_activeWorkstationId` change (via
  /// [_loadTenantId]) so we don't churn `OversellGuard` /
  /// `ManagerOverrideService` instances on every widget rebuild.
  SalesGuards _salesGuards = const SalesGuards.disabled();

  /// Cached tenant id loaded from the secure store after successful login, used
  /// to construct tenant-scoped repositories. Null while unauth'd or before
  /// [_loadTenantId] resolves. Screens that need it should treat null as "fall
  /// back to the legacy HTTP path" — the factory already handles that.
  String? _activeTenantId;

  /// Workstation id from the register-activation payload (persisted alongside
  /// tokens). Stamped on every receipt/shift/stock_movement the register
  /// writes when running on the drift sales path. Null when this device hasn't
  /// been activated as a register (e.g. owner web admin running locally).
  String? _activeWorkstationId;

  /// Compile-time feature flag profile. Flip individual flags to `true` in
  /// beta builds to exercise drift-backed data sources. Production defaults
  /// to all-off until each screen has been smoke-tested. See [FeatureFlags].
  static const _flags = FeatureFlags();

  @override
  void initState() {
    super.initState();
    _tokenStore = AuthTokenStore();
    _deviceTokenStore = AuthTokenStore(key: AuthTokenStore.deviceKey);
    _workstationStore = WorkstationStore();
    _deviceIdStore = DeviceIdStore();
    _lockoutStore = LockoutStore();
    _localeStore = LocaleStore();
    // Fire-and-forget: secure-storage round-trip is fast (≪16ms) and the
    // first frame ships with the 'ru' default. If the operator previously
    // saved 'kk', setState swaps in the second frame.
    unawaited(_hydrateLocale());

    // Single AuthSession owns both token slots (device + user) and the
    // refresh-on-401 mutex. ApiClient consults it for headers + retry; the
    // bloc writes through it on activation/login/logout. Bootstrap loads
    // both persisted slots into memory before the first authenticated
    // request — fired-and-forgotten here because secure storage reads are
    // fast and the cashier-grid CheckFirstRun comes after a Material build.
    _authSession = AuthSession(
      baseUrl: AppConstants.defaultApiHost,
      // Unwrapped http.Client for the refresh round-trip — keeps refresh
      // traffic out of the LoggingHttpClient noise on the main client.
      httpClient: http.Client(),
      loadDevice: _deviceTokenStore.load,
      saveDevice: _deviceTokenStore.save,
      clearDevicePersisted: _deviceTokenStore.clear,
      loadUser: _tokenStore.load,
      saveUser: _tokenStore.save,
      clearUserPersisted: _tokenStore.clear,
      fingerprint: DeviceFingerprint(),
    );
    unawaited(_authSession.bootstrap());

    _apiClient = ApiClient(session: _authSession);

    // Single shared key store — the AppDatabase takes it as an argument
    // so tests can inject a deterministic key. In production each device
    // mints a fresh 256-bit key on first boot and keeps it in the
    // platform secure store (see DatabaseKeyStore).
    _db = AppDatabase(keyStore: DatabaseKeyStore());
    _syncStatusService = SyncStatusService(_db, _apiClient);
    _salesGuards = _buildSalesGuards();
    _loadTenantId();
  }

  /// Best-effort load of the persisted locale. Silently keeps the `'ru'`
  /// default if nothing is saved or secure-storage errors out — the operator
  /// can flip via the chrome chip and the save will fire next time.
  Future<void> _hydrateLocale() async {
    final saved = await _localeStore.load();
    if (saved != null && saved != _currentLocale && mounted) {
      setState(() => _currentLocale = saved);
    }
  }

  /// Flip the locale between the two supported values and persist. Called
  /// from the chrome bar `_LocaleChip` via the [_MainShell.onLocaleToggle]
  /// callback. The HifiChrome chip's own label logic shows the OTHER
  /// locale (e.g. "ҚЗ" when current is ru), so callers don't need to
  /// know which way the flip goes — they just invoke this.
  void _toggleLocale() {
    final next = _currentLocale == 'ru' ? 'kk' : 'ru';
    setState(() => _currentLocale = next);
    unawaited(_localeStore.save(next));
  }

  /// Best-effort load of the saved tenant + workstation ids. No-ops silently
  /// if the user hasn't logged in yet — the factories fall back to the legacy
  /// HTTP path when these are null, so this isn't blocking app boot.
  Future<void> _loadTenantId() async {
    try {
      final tokens = await _tokenStore.load();
      if (tokens != null && mounted) {
        setState(() {
          _activeTenantId = tokens.tenantId;
          _activeWorkstationId = tokens.workstationId;
          // Rebuild the guards bundle once we know the tenant — happens
          // exactly once per login, not per widget rebuild.
          _salesGuards = _buildSalesGuards();
        });
      }
    } on Object {
      // Secure storage unavailable — accept the legacy path.
    }
  }


  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  /// Build the [SalesGuards] bundle for the current device. Wired when both
  /// the drift-sales flag is on AND we know the tenant + workstation id from
  /// the register-activation payload. Otherwise returns [SalesGuards.disabled]
  /// — the cart's pay flow then bypasses the pre-check and dispatches
  /// `CompleteSale` immediately, preserving pre-T5.7 behaviour.
  ///
  /// The [PinVerifier] uses [bcryptVerify] (pointycastle-backed) so offline
  /// PIN gates verify against the hash minted by .NET/BCrypt.Net — see T5.7e.
  SalesGuards _buildSalesGuards() {
    final tenantId = _activeTenantId;
    if (!_flags.useDriftSales || tenantId == null) {
      return const SalesGuards.disabled();
    }
    final deviceId = _activeWorkstationId ?? 'unknown-device';
    return SalesGuards(
      guard: OversellGuard(
        StockMovementRepository(_db, tenantId: tenantId, deviceId: deviceId),
      ),
      overrideService: ManagerOverrideService(
        CashierRepository(_db, tenantId: tenantId),
        verifier: bcryptVerify,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _apiClient),
        // Real bundle when drift-sales + register activation are both in
        // place; disabled-default otherwise. The instance lives in state
        // (built once at boot, refreshed when tenant id loads from secure
        // storage) — calling _buildSalesGuards() on every build() would
        // leak the underlying repos on each frame.
        RepositoryProvider<SalesGuards>.value(value: _salesGuards),
        // Sync status aggregator — read by SyncStatusChip in the top
        // chrome of every screen to render the combined online/pull/
        // outbox indicator. Stateless service, safe to share app-wide.
        RepositoryProvider<SyncStatusService>.value(value: _syncStatusService),
        // Compile-time feature flag profile. Exposed via provider so leaf
        // screens (e.g. PaymentScreen) can gate their own rendering
        // without each upstream widget having to thread the flag down.
        RepositoryProvider<FeatureFlags>.value(value: _flags),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(
              _apiClient,
              tokens: _tokenStore,
              deviceTokens: _deviceTokenStore,
              workstation: _workstationStore,
              deviceIdStore: _deviceIdStore,
              lockoutStore: _lockoutStore,
            )..add(HydrateSession()),
          ),
          BlocProvider(
            create: (_) => SalesBloc(
              _apiClient,
              // T5.5b/c: route CompleteSale through the SalesService abstraction.
              // Factory picks drift vs. legacy HTTP based on FeatureFlags. Both
              // tenantId AND workstationId must be known for the drift path —
              // workstationId is supplied by `/api/register/activate` and stored
              // alongside tokens. Until that completes, fall back to the legacy
              // HTTP path. The fallback also covers the owner-web-admin case
              // where the device was never activated as a register at all.
              salesService:
                  (_activeTenantId == null || _activeWorkstationId == null)
                      ? LegacySalesService(_apiClient)
                      : createSalesService(
                          flags: _flags,
                          db: _db,
                          api: _apiClient,
                          tenantId: _activeTenantId!,
                          deviceId: _activeWorkstationId!,
                          workstationId: _activeWorkstationId!,
                        ),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'POS System',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          // Prevent the on-screen keyboard from resizing the app body on
          // iOS/Android. POS layouts are bottom-heavy (cart + payment
          // pad, activation-code numpad, Z-report KPIs) — letting the
          // keyboard push content up triggers RenderFlex overflows and
          // looks broken on an iPad. Keyboard floats ABOVE the UI instead.
          //
          // Trade-off: if an input field sits very close to the bottom
          // edge, the keyboard will cover it. iOS still echoes the typed
          // text in the field's "selection bar" so users can see what
          // they're typing; visible input fields should live in the
          // top/middle of the screen (they already do, by design).
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                viewInsets: EdgeInsets.zero,
                viewPadding: media.viewPadding,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(_currentLocale),
          // Boot routing — activation-first.
          //
          // Device registration happens on the web admin; the register
          // itself only activates against a one-time code. Decision tree:
          //   RegisterNotActivated  → ActivationScreen (enter code)
          //   RegisterActivated     → PinScreen (cashier grid + admin tile)
          //   AuthAuthenticated     → main shell
          //   AuthLoading           → spinner
          //   AuthInitial (legacy)  → OwnerLoginScreen as a fallback
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              if (state is AuthAuthenticated) {
                return _MainShell(
                  api: _apiClient,
                  db: _db,
                  flags: _flags,
                  tenantId: _activeTenantId,
                  cashierId: state.cashierId,
                  cashierName: state.cashierName,
                  role: state.role,
                  // "Выйти из системы" — clear the session and route to the
                  // admin email+password screen. User's original wording:
                  // "when they press выйти из системы we show login with
                  // email password".
                  onLogout: () {
                    context.read<AuthBloc>().add(LogoutRequested());
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OwnerLoginScreen(),
                      ),
                    );
                  },
                  // "Сменить кассира" — clear the session and route
                  // straight to PinScreen, which shows the cashier grid
                  // (with admin tile) by default. Workstation + store
                  // bindings stay; next cashier just taps their face
                  // and enters PIN. Replaces the legacy CashierLoginScreen
                  // text-form.
                  onSwitchCashier: () {
                    context.read<AuthBloc>().add(LogoutRequested());
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PinScreen(),
                      ),
                    );
                  },
                  locale: _currentLocale,
                  onLocaleToggle: _toggleLocale,
                );
              }
              if (state is RegisterActivated) {
                // Activated device, no user logged in — show the cashier
                // grid (PinScreen) directly. Per user decision: replace
                // the LoginChooserScreen 2-tile chooser with a single
                // grid where admin is just one of the tiles.
                return const PinScreen();
              }
              if (state is RegisterNotActivated) {
                return const ActivationScreen();
              }
              if (state is AuthInitial) {
                // PinScreen also owns the AuthInitial state — it's what
                // _onCheckFirstRun emits after the cashier list loads
                // (state.cashiers / state.isFirstRun / lockout fields).
                // Without this branch the BlocBuilder would fall through
                // to OwnerLoginScreen and the user would land on
                // email + password right after activation succeeds.
                return const PinScreen();
              }
              // Truly unreachable now, but keep as a safety net.
              return const OwnerLoginScreen();
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// View mode + page identifiers
// ---------------------------------------------------------------------------

enum ViewMode { cashier, owner }

enum _PageId {
  pos,
  shift,
  products,
  cashiers,
  debts,
  analytics,
  delivery,
  approval,
  audit,
  settings,
}

class _NavEntry {
  final _PageId page;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavEntry(this.page, this.icon, this.activeIcon, this.label);
}

// All possible nav entries — filtered dynamically by ViewMode
List<_NavEntry> _allNav(AppLocalizations l) => [
  _NavEntry(_PageId.pos,      Icons.point_of_sale_outlined,         Icons.point_of_sale,            l.navPos),
  _NavEntry(_PageId.shift,    Icons.history_outlined,               Icons.history,                  l.navShift),
  _NavEntry(_PageId.products, Icons.inventory_2_outlined,           Icons.inventory_2,              l.navProducts),
  _NavEntry(_PageId.cashiers, Icons.people_outline,                 Icons.people,                   l.navStaff),
  _NavEntry(_PageId.debts,    Icons.account_balance_wallet_outlined,Icons.account_balance_wallet,   l.navDebts),
  _NavEntry(_PageId.analytics,Icons.bar_chart_outlined,             Icons.bar_chart,                l.navAnalytics),
  _NavEntry(_PageId.delivery, Icons.local_shipping_outlined,        Icons.local_shipping,           l.navDelivery),
  _NavEntry(_PageId.approval, Icons.verified_outlined,              Icons.verified,                 l.navApproval),
  _NavEntry(_PageId.audit,    Icons.manage_search_outlined,         Icons.manage_search,            l.navAudit),
  _NavEntry(_PageId.settings, Icons.settings_outlined,              Icons.settings,                 l.navSettings),
];

// ---------------------------------------------------------------------------
// _MainShell
// ---------------------------------------------------------------------------

class _MainShell extends StatefulWidget {
  final ApiClient api;
  final AppDatabase db;
  final FeatureFlags flags;
  final String? tenantId;
  final String cashierId;
  final String cashierName;
  final String role;

  /// "Выйти из системы" — full sign-out, routes to owner email+password
  /// login. Called from the bottom-sheet "Logout" item.
  final VoidCallback onLogout;

  /// "Сменить кассира" — session drop that routes straight to the cashier
  /// PIN flow (activation stays, store stays). Called from the sidebar
  /// swap button and the escape keyboard shortcut.
  final VoidCallback onSwitchCashier;

  /// Current operator-selected UI locale (`'ru'` or `'kk'`). Threaded
  /// down to the chrome bar's `_LocaleChip`; the chip's label flips to
  /// show the OTHER locale so tapping it is obviously a switch.
  final String locale;

  /// Invoked when the chrome chip is tapped. The host (`_PosAppState`)
  /// flips the locale and persists via [LocaleStore]; the shell itself
  /// stays purely presentational.
  final VoidCallback onLocaleToggle;

  const _MainShell({
    required this.api,
    required this.db,
    required this.flags,
    required this.tenantId,
    required this.cashierId,
    required this.cashierName,
    required this.role,
    required this.onLogout,
    required this.onSwitchCashier,
    required this.locale,
    required this.onLocaleToggle,
  });

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  _PageId _currentPage = _PageId.pos;
  String? _currentShiftId;
  int _pendingCount = 0;
  late ViewMode _viewMode;

  /// Auto-lock after 5 minutes of inactivity
  static const _autoLockDuration = Duration(minutes: 5);
  Timer? _inactivityTimer;

  /// Memoized product-catalog service. Built once when the shell mounts
  /// (or when the tenant id changes via didUpdateWidget below). Without
  /// this, _buildPage() constructed a fresh service on every rebuild —
  /// each inactivity-timer reset triggered build(), which re-instantiated
  /// the service, leaking any drift watchers it set up internally.
  late ProductCatalogService _catalogService;

  bool get _isOwner => widget.role == 'owner' || widget.role == 'admin';

  /// Cashiers (including senior cashiers) are the only roles that ever
  /// have an open shift. Owners/admins/managers must NOT hit
  /// `/api/shifts/current/{id}` on boot — they don't have one and the
  /// endpoint isn't implemented server-side anyway, so the call always
  /// 404s. The exception is silently caught downstream, but the noisy
  /// log line confused real testing sessions.
  bool get _isCashier =>
      widget.role == 'cashier' || widget.role == 'senior_cashier';

  ProductCatalogService _buildCatalogService() {
    if (widget.tenantId == null) {
      return LegacyApiProductCatalogService(widget.api);
    }
    return createProductCatalogService(
      flags: widget.flags,
      db: widget.db,
      tenantId: widget.tenantId!,
      api: widget.api,
    );
  }

  @override
  void initState() {
    super.initState();
    _viewMode = _isOwner ? ViewMode.owner : ViewMode.cashier;
    _catalogService = _buildCatalogService();
    // Only cashiers have shifts. Owners/admins/managers don't poll
    // `/api/shifts/current/{id}` — see [_isCashier] for rationale.
    if (_isCashier) _loadShift();
    // Pending-products count is no longer polled eagerly on login. The
    // Approval screen refreshes its own count via the onCountChanged
    // callback when the owner actually opens that tab. Keeping the poll
    // in initState caused a noisy 404 in the log on every owner login
    // (the server-side approval queue isn't built yet) and delayed the
    // badge by exactly one round-trip for zero user benefit.
    _resetInactivityTimer();
  }

  @override
  void didUpdateWidget(covariant _MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild the catalog service only when its inputs actually change —
    // tenant id is the only one that can flip (api/db/flags are owned by
    // the parent _PosAppState and are stable for the lifetime of the
    // process). This prevents stale closures over old tenantId after
    // owner login completes mid-session.
    if (oldWidget.tenantId != widget.tenantId) {
      _catalogService = _buildCatalogService();
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_autoLockDuration, _onInactivityTimeout);
  }

  void _onInactivityTimeout() {
    if (mounted) widget.onLogout();
  }

  /// Escape-key path to "switch cashier". Adds a confirmation prompt when
  /// the cart has items so a customer who reaches the keyboard can't
  /// silently drop an in-progress sale. No prompt when the cart is empty —
  /// that keeps the shortcut snappy for the normal handoff flow.
  void _handleEscapeSwitchCashier() {
    if (!mounted) return;
    final cartHasItems = context.read<SalesBloc>().state.items.isNotEmpty;
    if (!cartHasItems) {
      widget.onSwitchCashier();
      return;
    }
    final l = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.shellSwitchCashierTitle),
        content: Text(l.shellSwitchCashierMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l.shellSwitchCashierConfirm),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) widget.onSwitchCashier();
    });
  }

  Future<void> _loadShift() async {
    try {
      final resp = await widget.api.getCurrentShift(widget.cashierId);
      if (mounted) setState(() => _currentShiftId = resp['ID'] as String?);
    } on Exception catch (_) {
      // non-critical
    }
  }

  Future<void> _loadPendingCount() async {
    try {
      final resp = await widget.api.countPendingProducts();
      if (mounted) setState(() => _pendingCount = (resp['count'] as num?)?.toInt() ?? 0);
    } on Exception catch (_) {}
  }

  List<_NavEntry> _navItems(AppLocalizations l) {
    final all = _allNav(l);
    if (_viewMode == ViewMode.cashier) {
      return all.where((e) => e.page == _PageId.pos || e.page == _PageId.shift).toList();
    }
    return all;
  }

  void _switchMode(ViewMode mode) {
    setState(() {
      _viewMode = mode;
      _currentPage = _PageId.pos;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    // Wrap in Listener for auto-lock + CallbackShortcuts for keyboard nav
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.f1): () => setState(() => _currentPage = _PageId.pos),
        const SingleActivator(LogicalKeyboardKey.f2): () => setState(() => _currentPage = _PageId.shift),
        const SingleActivator(LogicalKeyboardKey.f3): () => setState(() => _currentPage = _PageId.products),
        const SingleActivator(LogicalKeyboardKey.f4): () => setState(() => _currentPage = _PageId.debts),
        const SingleActivator(LogicalKeyboardKey.escape): _handleEscapeSwitchCashier,
      },
      child: Focus(
        autofocus: true,
        // onKeyEvent: reset the inactivity timer on every key event and
        // return ignored so text fields + shortcuts still get the event.
        // P0-7: owners composing long product descriptions were getting
        // auto-locked at 5 min because typing didn't count as activity.
        onKeyEvent: (node, event) {
          _resetInactivityTimer();
          return KeyEventResult.ignored;
        },
        child: Listener(
          onPointerDown: (_) => _resetInactivityTimer(),
          onPointerMove: (_) => _resetInactivityTimer(),
          behavior: HitTestBehavior.translucent,
          child: isWide
              ? Scaffold(
                  body: Row(children: [
                    _buildSidebar(context),
                    Expanded(child: Column(children: [
                      _buildShellChrome(context),
                      Expanded(child: _buildPage(_currentPage)),
                    ])),
                  ]),
                )
              : Scaffold(
                  body: _buildPage(_currentPage),
                  bottomNavigationBar: _buildBottomNav(context),
                ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    // Mobile: always show POS + Shift + ... more
    return NavigationBar(
      selectedIndex: _currentPage == _PageId.pos ? 0 : _currentPage == _PageId.shift ? 1 : 2,
      onDestinationSelected: (i) {
        if (i == 0) { setState(() => _currentPage = _PageId.pos); }
        else if (i == 1) { setState(() => _currentPage = _PageId.shift); }
        else { _showMoreMenu(context); }
      },
      destinations: [
        NavigationDestination(icon: const Icon(Icons.point_of_sale_outlined), selectedIcon: const Icon(Icons.point_of_sale), label: AppLocalizations.of(context)!.navPosShort),
        NavigationDestination(icon: const Icon(Icons.history_outlined), selectedIcon: const Icon(Icons.history), label: AppLocalizations.of(context)!.navShiftShort),
        NavigationDestination(icon: const Icon(Icons.more_horiz), label: AppLocalizations.of(context)!.navMore),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return _MainShellSidebar(
      isOwner: _isOwner,
      viewMode: _viewMode,
      currentPage: _currentPage,
      navItems: _navItems(AppLocalizations.of(context)!),
      pendingCount: _pendingCount,
      currentShiftId: _currentShiftId,
      cashierName: widget.cashierName,
      role: widget.role,
      onViewModeChanged: _switchMode,
      onPageSelected: (page) => setState(() => _currentPage = page),
      onSwitchCashier: widget.onSwitchCashier,
    );
  }

  String _pageTitle(_PageId page, AppLocalizations l) => switch (page) {
    _PageId.pos       => l.navPos,
    _PageId.shift     => l.navShift,
    _PageId.products  => l.navProducts,
    _PageId.cashiers  => l.navStaff,
    _PageId.debts     => l.navDebts,
    _PageId.analytics => l.navAnalytics,
    _PageId.delivery  => l.navDelivery,
    _PageId.approval  => l.navApproval,
    _PageId.audit     => l.navAudit,
    _PageId.settings  => l.navSettings,
  };

  /// Single chrome bar rendered above every in-shell page. Replaces the
  /// older Material `_buildTopBar` — see "Unify shell chrome" appendix
  /// in the deploy plan for the rationale (two stacked top bars on POS,
  /// SyncStatusChip only visible on hi-fi screens, etc.).
  ///
  /// Owns: page-title breadcrumb, sync-status chip, notification bell +
  /// pendingCount badge, live clock, locale toggle (deferred). Per-page
  /// extras can later be threaded in via a `_PageId` → `Widget[]` map.
  Widget _buildShellChrome(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final syncStatus = context.read<SyncStatusService>();
    final shiftLabel = _currentShiftId != null
        ? l.shiftOpened // existing localised string; chrome shows it as a chip
        : null;

    return HifiChrome(
      title: _pageTitle(_currentPage, l),
      cashierName: widget.cashierName.isNotEmpty ? widget.cashierName : null,
      shiftNumber: shiftLabel,
      locale: widget.locale,
      onToggleLocale: widget.onLocaleToggle,
      extras: [
        // Live aggregated sync indicator (server reachability + outbox depth
        // + master-data freshness). Replaces the Material "system online"
        // pill that used to live in _buildTopBar — that was a static green
        // chip with no real signal.
        SyncStatusChip(service: syncStatus),
        // Notification bell with the approval-queue badge. The bell is a
        // stub (no notification list yet) but the badge is real:
        // _pendingCount comes from /api/products/pending/count via the
        // Approval screen's onCountChanged callback.
        _ChromeNotificationBell(
          pendingCount: _pendingCount,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.shellNoNotifications)),
            );
          },
        ),
      ],
      timestamp: null, // HifiLiveClock goes in extras when needed; the chip
                      // alongside the bell is enough density on iPad.
    );
  }

  void _showMoreMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: cs.outline.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2)),
            ),
            _BottomSheetItem(icon: Icons.inventory_2_outlined, label: l.navProductsShort,
              onTap: () { Navigator.pop(ctx); setState(() => _currentPage = _PageId.products); }),
            _BottomSheetItem(icon: Icons.people_outline, label: l.navStaffShort,
              onTap: () { Navigator.pop(ctx); setState(() => _currentPage = _PageId.cashiers); }),
            _BottomSheetItem(icon: Icons.account_balance_wallet_outlined, label: l.navDebtsShort,
              onTap: () { Navigator.pop(ctx); setState(() => _currentPage = _PageId.debts); }),
            if (_isOwner) ...[
              _BottomSheetItem(icon: Icons.bar_chart_outlined, label: l.navAnalyticsShort,
                onTap: () { Navigator.pop(ctx); setState(() => _currentPage = _PageId.analytics); }),
              _BottomSheetItem(icon: Icons.local_shipping_outlined, label: l.navDeliveryShort,
                onTap: () { Navigator.pop(ctx); setState(() => _currentPage = _PageId.delivery); }),
              _BottomSheetItem(icon: Icons.verified_outlined, label: l.navApprovalShort,
                onTap: () { Navigator.pop(ctx); setState(() => _currentPage = _PageId.approval); }),
              _BottomSheetItem(icon: Icons.manage_search_outlined, label: l.navAuditShort,
                onTap: () { Navigator.pop(ctx); setState(() => _currentPage = _PageId.audit); }),
            ],
            _BottomSheetItem(icon: Icons.settings_outlined, label: l.navSettingsShort,
              onTap: () { Navigator.pop(ctx); setState(() => _currentPage = _PageId.settings); }),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: cs.outlineVariant),
            ),
            _BottomSheetItem(icon: Icons.logout_rounded, label: l.logout,
              onTap: () { Navigator.pop(ctx); widget.onLogout(); }, isDestructive: true),
          ]),
        ),
      ),
    );
  }

  Widget _buildPage(_PageId page) => switch (page) {
    _PageId.pos      => PosScreen(shiftId: _currentShiftId, cashierId: widget.cashierId, role: widget.role),
    _PageId.shift    => ShiftScreen(api: widget.api, cashierId: widget.cashierId, cashierName: widget.cashierName, onShiftChanged: _loadShift),
    _PageId.products => ProductsScreen(
      api: widget.api,
      // T4.4c: factory picks drift vs. legacy HTTP based on FeatureFlags.
      // Memoized in initState/didUpdateWidget — see [_catalogService].
      // Building it inside _buildPage (which runs on every rebuild) leaked
      // a fresh drift-watching service on each inactivity-timer tick.
      catalog: _catalogService,
    ),
    _PageId.cashiers => CashiersScreen(api: widget.api),
    _PageId.debts    => DebtsScreen(api: widget.api, cashierId: widget.cashierId),
    _PageId.analytics=> AnalyticsScreen(api: widget.api),
    _PageId.delivery => DeliveryScreen(api: widget.api, cashierId: widget.cashierId, cashierName: widget.cashierName),
    _PageId.approval => ApprovalScreen(api: widget.api, reviewerId: widget.cashierId, reviewerName: widget.cashierName, onCountChanged: _loadPendingCount),
    _PageId.audit    => AuditScreen(api: widget.api),
    _PageId.settings => SettingsScreen(api: widget.api, onLogout: widget.onLogout, role: widget.role),
  };
}

// ---------------------------------------------------------------------------
// Sidebar (extracted from _MainShellState._buildSidebar for narrow rebuild
// boundaries — without this, the 200-line sidebar tree rebuilt on every
// inactivity-timer tick, every page swap, every pending-count refresh).
// ---------------------------------------------------------------------------

class _MainShellSidebar extends StatelessWidget {
  const _MainShellSidebar({
    required this.isOwner,
    required this.viewMode,
    required this.currentPage,
    required this.navItems,
    required this.pendingCount,
    required this.currentShiftId,
    required this.cashierName,
    required this.role,
    required this.onViewModeChanged,
    required this.onPageSelected,
    required this.onSwitchCashier,
  });

  final bool isOwner;
  final ViewMode viewMode;
  final _PageId currentPage;
  final List<_NavEntry> navItems;
  final int pendingCount;
  final String? currentShiftId;
  final String cashierName;
  final String role;
  final ValueChanged<ViewMode> onViewModeChanged;
  final ValueChanged<_PageId> onPageSelected;
  final VoidCallback onSwitchCashier;

  String _roleLabel(AppLocalizations l) => switch (role) {
        'owner' => l.roleOwner,
        'admin' => l.roleAdmin,
        'senior_cashier' => l.roleSeniorCashier,
        _ => l.roleCashier,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: 240,
      // Sidebar reskinned to Hifi.chrome (the same navy as the top chrome
      // bar) so the two pieces of the shell share one visual language.
      // `AppTheme.sidebarText` is intentionally kept as the muted-grey
      // foreground; over Hifi.chrome it gives the same WCAG contrast as
      // it did over the slate AppTheme.sidebarBg.
      color: Hifi.chrome,
      child: Column(
        children: [
          // Branding header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.point_of_sale_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('POS System',
                    style: Hifi.ui(size: 16, weight: FontWeight.w700, color: Colors.white)
                        .copyWith(letterSpacing: -0.3)),
                Text('KAZAKHSTAN',
                    style: Hifi.ui(size: 9, weight: FontWeight.w600, color: AppTheme.sidebarText)
                        .copyWith(letterSpacing: 2)),
              ])),
            ]),
          ),

          if (isOwner) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _ModeToggle(mode: viewMode, onChanged: onViewModeChanged),
          ),
          if (isOwner) const SizedBox(height: 12),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: navItems.map((entry) {
                final selected = currentPage == entry.page;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _SidebarNavItem(
                    icon: selected ? entry.activeIcon : entry.icon,
                    label: entry.label,
                    selected: selected,
                    badge: entry.page == _PageId.approval && pendingCount > 0
                        ? pendingCount
                        : null,
                    onTap: () => onPageSelected(entry.page),
                  ),
                );
              }).toList(),
            ),
          ),

          // Shift status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentShiftId != null
                        ? const Color(0xFF4EDEA3)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentShiftId != null ? l.shiftOpened : l.shiftClosed,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.sidebarText),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Switch cashier button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onSwitchCashier,
                borderRadius: BorderRadius.circular(10),
                hoverColor: Colors.white.withValues(alpha: 0.06),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(Icons.swap_horiz_rounded,
                        size: 16,
                        color: AppTheme.sidebarText.withValues(alpha: 0.8)),
                    const SizedBox(width: 10),
                    Text(
                      l.switchCashier,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.sidebarText),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // User profile card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      cashierName.isNotEmpty ? cashierName[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cashierName,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _roleLabel(l),
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppTheme.sidebarText,
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                )),
              ]),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mode toggle widget
// ---------------------------------------------------------------------------

class _ModeToggle extends StatelessWidget {
  final ViewMode mode;
  final ValueChanged<ViewMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        _ToggleBtn(
          label: AppLocalizations.of(context)!.modeCashier,
          selected: mode == ViewMode.cashier,
          onTap: () => onChanged(ViewMode.cashier),
        ),
        _ToggleBtn(
          label: AppLocalizations.of(context)!.modeOwner,
          selected: mode == ViewMode.owner,
          onTap: () => onChanged(ViewMode.owner),
        ),
      ]),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.sidebarText,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar nav item (with optional badge)
// ---------------------------------------------------------------------------

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon, required this.label, required this.selected,
    required this.onTap, this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: Colors.white.withValues(alpha: 0.06),
        splashColor: Colors.white.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppTheme.sidebarActiveBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(icon, size: 18,
              color: selected ? AppTheme.sidebarActiveText : AppTheme.sidebarText),
            const SizedBox(width: 14),
            Expanded(child: Text(label,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                color: selected ? Colors.white : AppTheme.sidebarText,
              ),
            )),
            if (badge != null && badge! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet item
// ---------------------------------------------------------------------------

class _BottomSheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _BottomSheetItem({
    required this.icon, required this.label, required this.onTap, this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final pos = PosColors.of(context);
    return ListTile(
      leading: Icon(icon, color: isDestructive ? pos.errorFg : null),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: isDestructive ? pos.errorFg : null)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }
}

/// Compact notification bell with red badge — chrome `extras` slot widget.
/// Visual style matches the navy chrome (white icon, white-tinted hover).
/// The badge count is the pending-products approval queue (`_pendingCount`).
class _ChromeNotificationBell extends StatelessWidget {
  const _ChromeNotificationBell({
    required this.pendingCount,
    required this.onTap,
  });

  final int pendingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Tooltip + Semantics so the icon-only bell is reachable to keyboard
    // and screen-reader users. Without these the only thing announced is
    // an unlabelled button. The pendingCount is folded into the announce
    // text when nonzero so screen-reader users learn the badge state too.
    final tooltip = pendingCount > 0
        ? '${l.shellNoNotifications} ($pendingCount)'
        : l.shellNoNotifications;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Stack(clipBehavior: Clip.none, children: [
              Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
          if (pendingCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$pendingCount',
                  textAlign: TextAlign.center,
                  style: Hifi.ui(size: 9, weight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
        ]),
          ),
        ),
      ),
    );
  }
}
