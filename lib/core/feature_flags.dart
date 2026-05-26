/// Per-screen feature flags driving the gradual cutover from the legacy Go
/// localhost:8080 server to the new local-first drift + .NET central architecture.
///
/// **Lifecycle of a flag**:
///   1. Set to `false` while the new repository / data path is built.
///   2. Flip to `true` on a single dev build → smoke test the screen.
///   3. Per-tenant rollout: pull flag values from `/api/settings/flags` on app boot
///      so we can flip a tenant without shipping a new binary (planned in P2.T2).
///   4. After 48h green in beta, flip in default for everyone.
///   5. Once stable for 30 days across all tenants, the corresponding Go endpoint
///      can be retired (one of the P9 cleanup steps).
///
/// **Hard rules**:
///   - Adding a flag here is a routine PR. Removing one (after a screen is fully
///     migrated and Go is dead for that endpoint) is also a routine PR.
///   - Never branch on a flag at the UI layer. Branching belongs at the data-source
///     layer (Repository factory). The widget should be agnostic.
///   - Each flag corresponds to ONE Flutter screen / feature folder.
class FeatureFlags {
  const FeatureFlags({
    this.useDriftSettings = false,
    this.useDriftCashiers = false,
    this.useDriftCategories = false,
    this.useDriftProducts = false,
    this.useDriftClients = false,
    this.useDriftDebts = false,
    this.useDriftSuppliers = false,
    this.useDriftDelivery = false,
    this.useDriftShifts = false,
    this.useDriftSales = false, // critical path — flip last
    this.useDriftAnalytics = false,
    this.useDriftAudit = false,
    this.useDriftApproval = false,
    this.useDriftNkt = false,
    this.useNewCentralAuth = false, // when true, login/refresh hit .NET /api/auth/* instead of Go
    // Gates the card / Kaspi QR payment path. Defaults to OFF until a real
    // terminal SDK is wired in — the current "card payment" code is a
    // 2-second Future.delayed auto-success stub that would create
    // unrecoverable fiscal records for declined transactions if exposed.
    // When false, the payment-screen card + Kaspi QR tiles render as
    // disabled (greyed, non-tappable). Flip to true only on a build that
    // talks to a real PED.
    this.cardTerminalEnabled = false,
  });

  /// All-on configuration — used in dev / staging once a screen is ready to test
  /// against drift end-to-end. Production builds default to all-off until each
  /// screen flips individually.
  static const FeatureFlags allDrift = FeatureFlags(
    useDriftSettings: true,
    useDriftCashiers: true,
    useDriftCategories: true,
    useDriftProducts: true,
    useDriftClients: true,
    useDriftDebts: true,
    useDriftSuppliers: true,
    useDriftDelivery: true,
    useDriftShifts: true,
    useDriftSales: true,
    useDriftAnalytics: true,
    useDriftAudit: true,
    useDriftApproval: true,
    useDriftNkt: true,
    useNewCentralAuth: true,
  );

  /// All-off — the current default, matches today's behavior (everything via Go).
  static const FeatureFlags legacy = FeatureFlags();

  final bool useDriftSettings;
  final bool useDriftCashiers;
  final bool useDriftCategories;
  final bool useDriftProducts;
  final bool useDriftClients;
  final bool useDriftDebts;
  final bool useDriftSuppliers;
  final bool useDriftDelivery;
  final bool useDriftShifts;
  final bool useDriftSales;
  final bool useDriftAnalytics;
  final bool useDriftAudit;
  final bool useDriftApproval;
  final bool useDriftNkt;
  final bool useNewCentralAuth;
  final bool cardTerminalEnabled;

  /// Build a copy with selected flags overridden. Used by remote-config loader
  /// (`/api/settings/flags`) to apply per-tenant overrides on top of compile-time defaults.
  FeatureFlags copyWith({
    bool? useDriftSettings,
    bool? useDriftCashiers,
    bool? useDriftCategories,
    bool? useDriftProducts,
    bool? useDriftClients,
    bool? useDriftDebts,
    bool? useDriftSuppliers,
    bool? useDriftDelivery,
    bool? useDriftShifts,
    bool? useDriftSales,
    bool? useDriftAnalytics,
    bool? useDriftAudit,
    bool? useDriftApproval,
    bool? useDriftNkt,
    bool? useNewCentralAuth,
    bool? cardTerminalEnabled,
  }) {
    return FeatureFlags(
      useDriftSettings: useDriftSettings ?? this.useDriftSettings,
      useDriftCashiers: useDriftCashiers ?? this.useDriftCashiers,
      useDriftCategories: useDriftCategories ?? this.useDriftCategories,
      useDriftProducts: useDriftProducts ?? this.useDriftProducts,
      useDriftClients: useDriftClients ?? this.useDriftClients,
      useDriftDebts: useDriftDebts ?? this.useDriftDebts,
      useDriftSuppliers: useDriftSuppliers ?? this.useDriftSuppliers,
      useDriftDelivery: useDriftDelivery ?? this.useDriftDelivery,
      useDriftShifts: useDriftShifts ?? this.useDriftShifts,
      useDriftSales: useDriftSales ?? this.useDriftSales,
      useDriftAnalytics: useDriftAnalytics ?? this.useDriftAnalytics,
      useDriftAudit: useDriftAudit ?? this.useDriftAudit,
      useDriftApproval: useDriftApproval ?? this.useDriftApproval,
      useDriftNkt: useDriftNkt ?? this.useDriftNkt,
      useNewCentralAuth: useNewCentralAuth ?? this.useNewCentralAuth,
      cardTerminalEnabled: cardTerminalEnabled ?? this.cardTerminalEnabled,
    );
  }

  /// Apply a JSON-shaped settings dict (e.g. from `/api/settings/flags`) on top of `this`.
  /// Unknown keys are ignored. Non-bool values are ignored. Missing keys keep `this`'s value.
  FeatureFlags applyRemoteConfig(Map<String, dynamic> remote) {
    bool? bv(String k) {
      final v = remote[k];
      return v is bool ? v : (v is String ? (v == 'true' ? true : (v == 'false' ? false : null)) : null);
    }
    return copyWith(
      useDriftSettings: bv('use_drift_settings'),
      useDriftCashiers: bv('use_drift_cashiers'),
      useDriftCategories: bv('use_drift_categories'),
      useDriftProducts: bv('use_drift_products'),
      useDriftClients: bv('use_drift_clients'),
      useDriftDebts: bv('use_drift_debts'),
      useDriftSuppliers: bv('use_drift_suppliers'),
      useDriftDelivery: bv('use_drift_delivery'),
      useDriftShifts: bv('use_drift_shifts'),
      useDriftSales: bv('use_drift_sales'),
      useDriftAnalytics: bv('use_drift_analytics'),
      useDriftAudit: bv('use_drift_audit'),
      useDriftApproval: bv('use_drift_approval'),
      useDriftNkt: bv('use_drift_nkt'),
      useNewCentralAuth: bv('use_new_central_auth'),
      cardTerminalEnabled: bv('card_terminal_enabled'),
    );
  }
}
