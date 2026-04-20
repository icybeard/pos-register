import 'package:flutter/material.dart';

import '../../../core/theme/hifi.dart';
import '../../../data/database.dart';
import '../../../services/override/manager_override_service.dart';

/// Section 06 — Manager PIN override dialog, styled to match the hi-fi design.
///
/// Rendered over the current context with a navy-lock icon, reason strip, and
/// a 3×4 PIN pad. Login is required because the service's verifier maps to a
/// user row; in the hi-fi mock the login is implicit (single-manager store),
/// but the real stack needs both login + PIN.
class ManagerOverrideDialog extends StatefulWidget {
  const ManagerOverrideDialog({
    super.key,
    required this.service,
    this.subtitle,
    this.actionLabel = 'Подтвердить',
  });

  final ManagerOverrideService service;
  final String? subtitle;
  final String actionLabel;

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
  int _failed = 0;
  DateTime? _lockUntil;

  @override
  void dispose() {
    _loginCtrl.dispose();
    super.dispose();
  }

  bool get _locked => _lockUntil != null && DateTime.now().isBefore(_lockUntil!);

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
      _failed++;
      if (_failed >= 3) {
        _lockUntil = DateTime.now().add(const Duration(seconds: 30));
      }
    });
  }

  String _messageFor(OverrideResult r, UserRow? user) {
    switch (r) {
      case OverrideResult.ok:
        return '';
      case OverrideResult.notFound:
        return 'Логин не найден';
      case OverrideResult.wrongPin:
        return 'Неверный PIN';
      case OverrideResult.insufficientRole:
        final name = user?.name ?? 'Этот пользователь';
        return '$name не может авторизовать эту операцию';
      case OverrideResult.inactive:
        return 'Учётная запись отключена';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _header(),
          const SizedBox(height: 16),
          if (widget.subtitle != null) _reasonStrip(widget.subtitle!),
          if (widget.subtitle != null) const SizedBox(height: 16),
          TextField(
            controller: _loginCtrl,
            enabled: !_busy && !_locked,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Логин менеджера',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Text('PIN менеджера', style: Hifi.ui(size: 12, color: const Color(0xFF666666))),
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
              'Заблокировано на 30 сек после 3 неверных попыток',
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
              child: const Text('Отмена'),
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
                    : Text('✓ ${widget.actionLabel}', style: Hifi.ui(size: 14, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _header() => Row(children: [
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
            Text('Требуется подтверждение менеджера',
                style: Hifi.ui(size: 16, weight: FontWeight.w700, color: Hifi.chrome)),
          ]),
        ),
      ]);

  Widget _reasonStrip(String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Hifi.infoStrip,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Hifi.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('ДЕЙСТВИЕ', style: Hifi.ui(size: 10, color: const Color(0xFF666666)).copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(text, style: Hifi.ui(size: 13)),
        ]),
      );
}
