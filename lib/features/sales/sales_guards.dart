import '../../services/override/manager_override_service.dart';
import '../../services/override/oversell_guard.dart';

/// Bundle of the two services the cashier's "Pay" button runs BEFORE
/// dispatching `CompleteSale`:
///   1. `OversellGuard.check(...)` → list of shortages
///   2. `ManagerOverrideDialog.show(service: ...)` when non-empty
///
/// Both are null when this device hasn't finished the drift-on / register-
/// activation handshake (owner web admin on the same codebase, pre-login,
/// or `useDriftSales: false`). Null → skip the pre-check and dispatch
/// `CompleteSale` directly, preserving the pre-T5.7d behaviour.
///
/// Provided via `RepositoryProvider<SalesGuards>.value` at app boot so the
/// `_CartPanel` can `context.read<SalesGuards>()` without widget drilling.
class SalesGuards {
  const SalesGuards({this.guard, this.overrideService});

  /// Disabled profile — safe default when the device isn't on the drift
  /// sales path. Both getters return null; callers take the bypass branch.
  const SalesGuards.disabled()
      : guard = null,
        overrideService = null;

  final OversellGuard? guard;
  final ManagerOverrideService? overrideService;

  /// Convenience — true when BOTH pieces are wired. Cart widget checks this
  /// as a single atomic condition (having only one is an app-boot bug).
  bool get isWired => guard != null && overrideService != null;
}
