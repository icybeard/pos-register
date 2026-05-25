import '../../data/database.dart';
import '../../data/repositories/cashier_repository.dart';

/// Outcome of [ManagerOverrideService.verify]. Distinct values so the UI can
/// show a precise message per failure mode — critical for cashier training,
/// since "wrong PIN" and "your role can't authorise this" look the same to a
/// harried cashier otherwise.
enum OverrideResult {
  /// PIN matched a user whose role is manager-or-above. Proceed with the
  /// oversell. Caller should stamp this user's id onto the stock_movement's
  /// `override_by_user_id` field so EOD reports flag the override.
  ok,

  /// No user found with that login (typo, or cashier of a different tenant).
  notFound,

  /// Login exists but the PIN hash didn't match.
  wrongPin,

  /// Login + PIN are valid but the user's role cannot authorise oversells.
  /// Plain cashiers can't override their own shortage — a senior cashier,
  /// manager, admin, or owner must step in.
  insufficientRole,

  /// User exists and PIN matches but the account is deactivated. Don't
  /// silently succeed — surface so admin can reactivate or the cashier can
  /// find a different manager.
  inactive,
}

/// Signature of a PIN-hash checker. Production wires bcrypt (pointycastle);
/// tests inject a stub like `(pin, hash) => pin == hash` to avoid bcrypt's
/// 100ms+ per-call cost in a test loop.
typedef PinVerifier = bool Function(String pin, String storedHash);

/// Register-side manager-PIN override for oversell + void + discount over
/// limit. Verifies locally against the drift [UsersTable] — runs offline,
/// which matters because oversell happens precisely when inventory and
/// network are both stressed.
///
/// **Authoritative on the server side**: the register accepting an override
/// only stamps `override_by_user_id` on the stock_movement. Central re-runs
/// the role check on sync-push and rejects the row if the user's role no
/// longer qualifies (e.g. demoted between the offline override and the
/// sync). That's defense in depth — not handled here.
class ManagerOverrideService {
  ManagerOverrideService(
    this._cashiers, {
    required PinVerifier verifier,
    this.maxFailedAttempts = 3,
    this.lockoutDuration = const Duration(seconds: 30),
  }) : _verify = verifier;

  final CashierRepository _cashiers;
  final PinVerifier _verify;

  /// Number of failed attempts that triggers a lockout. Per-service state so
  /// dismissing and re-opening the dialog doesn't reset the counter — the
  /// guard would be useless otherwise.
  final int maxFailedAttempts;

  /// How long the service refuses verify() after [maxFailedAttempts] misses.
  final Duration lockoutDuration;

  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  /// True if the service is currently rate-limited and will short-circuit
  /// verify() with [OverrideResult.wrongPin] until [lockedUntil] passes.
  bool get isLocked => _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  /// Wall-clock instant when the current lockout expires. Null if not locked.
  /// The UI reads this to render a countdown / disable the submit button.
  DateTime? get lockedUntil => _lockedUntil;

  /// Roles that may authorise an oversell. Matches the locked decision in the
  /// plan (Section 2, #11): cashiers can't override; everyone senior can.
  static const _overrideRoles = {
    'owner',
    'admin',
    'manager',
    'senior_cashier',
  };

  /// Look up `login` in the local users table and verify `pin`. Returns an
  /// [OverrideResult] describing the outcome + the matched [UserRow] when
  /// [OverrideResult.ok] (for stamping override_by_user_id).
  Future<ManagerOverrideOutcome> verify({
    required String login,
    required String pin,
  }) async {
    // Service-level rate limit. State survives dialog dismissal/re-open so
    // a guesser can't reset by tapping Cancel and trying again.
    if (isLocked) {
      return const ManagerOverrideOutcome(result: OverrideResult.wrongPin);
    }

    final normalized = login.trim().toLowerCase();
    final outcome = await _verifyInner(normalized, pin);

    if (outcome.isOk) {
      // Success unconditionally resets the counter.
      _failedAttempts = 0;
      _lockedUntil = null;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= maxFailedAttempts) {
        _lockedUntil = DateTime.now().add(lockoutDuration);
        _failedAttempts = 0; // restart counter after the lockout expires
      }
    }
    return outcome;
  }

  Future<ManagerOverrideOutcome> _verifyInner(String normalized, String pin) async {
    if (normalized.isEmpty || pin.isEmpty) {
      return const ManagerOverrideOutcome(result: OverrideResult.notFound);
    }
    final user = await _cashiers.findByLogin(normalized);
    if (user == null) {
      return const ManagerOverrideOutcome(result: OverrideResult.notFound);
    }
    if (user.pinHash == null || user.pinHash!.isEmpty) {
      // A user row with no local PIN hash — e.g. owner who only uses
      // email+password on the web. Can't verify locally.
      return const ManagerOverrideOutcome(result: OverrideResult.wrongPin);
    }
    if (!_verify(pin, user.pinHash!)) {
      return const ManagerOverrideOutcome(result: OverrideResult.wrongPin);
    }
    if (!_overrideRoles.contains(user.role)) {
      return ManagerOverrideOutcome(result: OverrideResult.insufficientRole, user: user);
    }
    if (!user.isActive) {
      return ManagerOverrideOutcome(result: OverrideResult.inactive, user: user);
    }
    return ManagerOverrideOutcome(result: OverrideResult.ok, user: user);
  }
}

/// Pairs [OverrideResult] with the matched user (when relevant). Callers
/// stamp `user.id` onto `stock_movement.override_by_user_id` on success;
/// for the soft-fail cases (insufficientRole, inactive) the user row is
/// still returned so the UI can show "User X is a cashier, not a manager".
class ManagerOverrideOutcome {
  const ManagerOverrideOutcome({required this.result, this.user});

  final OverrideResult result;
  final UserRow? user;

  bool get isOk => result == OverrideResult.ok;
}
