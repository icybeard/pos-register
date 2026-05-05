import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Outcome of a biometric authentication attempt. Mapped to short Russian
/// strings by the caller for UI display.
enum BiometricOutcome {
  /// Biometric prompt succeeded — caller may now reveal protected data.
  success,

  /// User cancelled the prompt (pressed "Cancel" or navigated away).
  userCancelled,

  /// User tried too many times and the OS locked biometrics out temporarily.
  /// On iOS, fallback to device passcode is the OS's own choice; this
  /// surfaces only if the user rejects the passcode option too.
  lockedOut,

  /// Permanent lockout — user must unlock via device passcode in Settings
  /// before biometrics can be used again. Usually means 5+ failed attempts.
  permanentlyLockedOut,

  /// Device supports biometrics in hardware but none are enrolled
  /// (user hasn't set up Face ID / Touch ID / fingerprint).
  notEnrolled,

  /// Device hardware doesn't support biometrics at all.
  notSupported,

  /// Any other platform exception (OS-level error, plugin channel failure).
  otherError,
}

/// Thin wrapper around the `local_auth` plugin. Intentionally stateless —
/// the only side effect is the OS biometric prompt itself. The mapping to
/// stored credentials (which cashier, which token) is the caller's job;
/// this service answers one question: "did the device's enrolled biometric
/// just succeed?"
class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// True if the device has biometric hardware AND can authenticate (i.e.
  /// the user has enrolled a biometric OR a device passcode is set so
  /// biometrics can fall back to it). False on simulators without hardware.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } on PlatformException {
      return false;
    }
  }

  /// Returns the enrolled biometric types — used to show the right icon
  /// (fingerprint vs face) and label ("Touch ID" vs "Face ID" on iOS).
  /// Empty list on simulators, devices with no enrollment, or errors.
  Future<List<BiometricType>> availableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return const <BiometricType>[];
    }
  }

  /// Returns true if Face ID specifically is the device's primary biometric
  /// (so the UI label can say "Face ID" instead of generic "Биометрия").
  /// Touch ID / fingerprint return false.
  Future<bool> hasFace() async {
    final types = await availableTypes();
    return types.contains(BiometricType.face)
        || types.contains(BiometricType.strong); // Android: fused face+fp
  }

  /// Prompt the user to authenticate. [reason] is shown as the prompt's
  /// subtitle on Android; on iOS it's read by VoiceOver.
  ///
  /// [stickyAuth]: if true, the prompt survives the app being backgrounded
  /// (phone lock / notification drag). Default false — for POS workflows
  /// a dismissed prompt is a deliberate cancel.
  Future<BiometricOutcome> authenticate({
    String reason = 'Войдите по биометрии',
    bool stickyAuth = false,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: false, // allow device-passcode fallback
          stickyAuth: stickyAuth,
          useErrorDialogs: true,
        ),
      );
      return ok ? BiometricOutcome.success : BiometricOutcome.userCancelled;
    } on PlatformException catch (e) {
      return _mapException(e);
    }
  }

  BiometricOutcome _mapException(PlatformException e) {
    // Codes are defined in auth_messages_*.dart of the local_auth plugin.
    switch (e.code) {
      case 'NotAvailable':
      case 'PasscodeNotSet':
        return BiometricOutcome.notSupported;
      case 'NotEnrolled':
        return BiometricOutcome.notEnrolled;
      case 'LockedOut':
        return BiometricOutcome.lockedOut;
      case 'PermanentlyLockedOut':
        return BiometricOutcome.permanentlyLockedOut;
      case 'auth_in_progress':
      case 'UserCancel':
      case 'no_fragment_activity': // Android dev error — should never reach prod
        return BiometricOutcome.userCancelled;
      default:
        return BiometricOutcome.otherError;
    }
  }
}
