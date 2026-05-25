import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/hifi.dart';
import '../../../data/database.dart';
import '../../../services/override/manager_override_service.dart';

/// Section 06 — Manager PIN override dialog, styled to match the hi-fi design.
///
/// Rendered over the current context with a navy-lock icon, reason strip, and
/// a 3×4 PIN pad. Login is required because the service's verifier maps to a
/// user row; in the hi-fi mock the login is implicit (single-manager store),
/// but the real stack needs both login + PIN.
///
/// Lockout state lives on [ManagerOverrideService] — dismissing the dialog
/// does NOT reset the failure counter (would defeat the rate limit). This
/// widget is a thin view over that state.
class ManagerOverrideDialog extends StatefulWidget {
  const ManagerOverrideDialog({
    super.key,
    required this.service,
    this.subtitle,
    this.actionLabel,
  });

  final ManagerOverrideService service;
  final String? subtitle;

  /// If null, the default localised "Confirm" label is used.
  final String? actionLabel;

  static Future<UserRow?> show(
    BuildContext context, {
    required ManagerOverrideService service,
    String? subtitle,
  }) {
    return showDialog<UserRow>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ManagerOverrideDialog(service: service, subtitle: subtitle),
    );
  }

  @override
  State<ManagerOverrideDialog> createState() => _ManagerOverrideDialogState();
}

class _ManagerOverrideDialogState extends State<ManagerOverrideDialog> {
  final _loginCtrl = TextEditingController();
  String _pin = '';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _loginCtrl.dispose();
    super.dispose();
  }

  bool get _locked => widget.service.isLocked;

  Future<void> _submit() async {
    if (_busy || _locked || _pin.length != 4) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final outcome = await widget.service.verify(
      login: _loginCtrl.text,
      pin: _pin,
    );
    if (!mounted) return;
    if (outcome.isOk) {
      Navigator.of(context).pop(outcome.user);
      return;
    }
    setState(() {
      _busy = false;
      _pin = '';
      _error = _messageFor(outcome.result, outcome.user);
    });
  }

  String _messageFor(OverrideResult r, UserRow? user) {
    final l = AppLocalizations.of(context)!;
    switch (r) {
      case OverrideResult.ok:
        return '';
      case OverrideResult.notFound:
        return l.managerOverrideNotFound;
      case OverrideResult.wrongPin:
        return l.managerOverrideWrongPin;
      case OverrideResult.insufficientRole:
        final name = user?.name ?? l.managerOverrideThisUser;
        return l.managerOverrideInsufficientRole(name);
      case OverrideResult.inactive:
        return l.managerOverrideInactive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final actionLabel = widget.actionLabel ?? l.managerOverrideConfirm;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      // SingleChildScrollView guards against the dialog content exceeding
      // its max-height constraint (Material gives showDialog a ~512px
      // ceiling at the 600px viewport heights used in widget tests and on
      // smaller tablets). Without this the Column overflows with a
      // RenderFlex assertion and the PIN pad / submit row clip off-screen.
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _header(l),
          const SizedBox(height: 16),
          if (widget.subtitle != null) _reasonStrip(widget.subtitle!, l),
          if (widget.subtitle != null) const SizedBox(height: 16),
          TextField(
            controller: _loginCtrl,
            enabled: !_busy && !_locked,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: l.managerOverrideLoginLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Text(l.managerOverridePinLabel, style: Hifi.ui(size: 12, color: const Color(0xFF666666))),
          const SizedBox(height: 8),
          HifiPinDots(filled: _pin.length),
          const SizedBox(height: 16),
          HifiPinPad(
            onKey: (k) {
              if (_locked || _busy) return;
              if (_pin.length < 4) setState(() => _pin = _pin + k);
            },
            onBackspace: _locked || _busy
                ? null
                : () {
                    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
                  },
            onSubmit: _submit,
          ),
          if (_locked) ...[
            const SizedBox(height: 12),
            Text(
              l.managerOverrideLocked,
              style: Hifi.ui(size: 12, color: Hifi.danger),
            ),
          ] else if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: Hifi.ui(size: 12, color: Hifi.danger)),
          ],
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(null),
              child: Text(l.managerOverrideCancel),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 180,
              child: FilledButton(
                onPressed: _busy || _locked || _pin.length != 4 ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Hifi.chrome,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('✓ $actionLabel', style: Hifi.ui(size: 14, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ]),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l) => Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFDDB4),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.lock_outline, color: Hifi.warn, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(l.managerOverrideTitle,
                style: Hifi.ui(size: 16, weight: FontWeight.w700, color: Hifi.chrome)),
          ]),
        ),
      ]);

  Widget _reasonStrip(String text, AppLocalizations l) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Hifi.infoStrip,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Hifi.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(l.managerOverrideActionLabel,
              style: Hifi.ui(size: 10, color: const Color(0xFF666666)).copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(text, style: Hifi.ui(size: 13)),
        ]),
      );
}
