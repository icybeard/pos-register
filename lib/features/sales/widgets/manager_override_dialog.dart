import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/database.dart';
import '../../../services/override/manager_override_service.dart';

/// Modal the cashier sees when their cart would oversell stock. A manager
/// (senior_cashier / manager / admin / owner) types their login + PIN; on
/// success the dialog pops with their [UserRow] so the sales flow can stamp
/// `override_by_user_id` on the stock_movement.
///
/// The widget takes a [ManagerOverrideService] so tests can drive it with an
/// in-memory DB + plain-text verifier. Keeps the dialog's UX logic (message
/// mapping, PIN clearing, loading state) independent of the crypto path.
class ManagerOverrideDialog extends StatefulWidget {
  const ManagerOverrideDialog({
    super.key,
    required this.service,
    this.subtitle,
  });

  final ManagerOverrideService service;

  /// Optional free-form context line (e.g. "Продажа ниже остатка: Кола — 2 шт
  /// при остатке 1"). Rendered above the login field so the manager sees what
  /// they're authorising without asking the cashier.
  final String? subtitle;

  /// Convenience: pop the context's Navigator with `null` on cancel, `UserRow`
  /// on success. Returns null if the user dismissed the dialog without
  /// authorising (tap outside / Cancel button / back gesture).
  static Future<UserRow?> show(
    BuildContext context, {
    required ManagerOverrideService service,
    String? subtitle,
  }) {
    return showDialog<UserRow>(
      context: context,
      barrierDismissible: false, // oversell is a deliberate act; no accidental dismiss
      builder: (ctx) => ManagerOverrideDialog(service: service, subtitle: subtitle),
    );
  }

  @override
  State<ManagerOverrideDialog> createState() => _ManagerOverrideDialogState();
}

class _ManagerOverrideDialogState extends State<ManagerOverrideDialog> {
  final _loginCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String? _errorMessage;
  bool _busy = false;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final outcome = await widget.service.verify(
      login: _loginCtrl.text,
      pin: _pinCtrl.text,
    );
    if (!mounted) return;
    if (outcome.isOk) {
      Navigator.of(context).pop(outcome.user);
      return;
    }
    setState(() {
      _busy = false;
      _errorMessage = _messageFor(outcome.result, outcome.user);
      _pinCtrl.clear(); // always clear PIN on failure; login stays for retry
    });
  }

  void _cancel() {
    Navigator.of(context).pop(null);
  }

  /// Each [OverrideResult] gets its own Russian message. Critical for
  /// cashier training — "wrong PIN" and "your role can't authorise this" must
  /// not blur together or cashiers will type PINs for a minute before noticing
  /// the role block.
  static String _messageFor(OverrideResult r, UserRow? user) {
    switch (r) {
      case OverrideResult.ok:
        return ''; // unreachable — isOk path pops the dialog
      case OverrideResult.notFound:
        return 'Логин не найден';
      case OverrideResult.wrongPin:
        return 'Неверный PIN';
      case OverrideResult.insufficientRole:
        final name = user?.name ?? 'Этот пользователь';
        return '$name не может авторизовать продажу ниже остатка — позовите менеджера';
      case OverrideResult.inactive:
        return 'Учётная запись отключена — обратитесь к администратору';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Авторизация менеджера'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.subtitle != null) ...[
            Text(widget.subtitle!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _loginCtrl,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Логин менеджера',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pinCtrl,
            obscureText: true,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'PIN',
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : _cancel,
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Подтвердить'),
        ),
      ],
    );
  }
}
