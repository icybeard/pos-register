import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_bloc.dart';

/// Cashier / manager login on an activated register. The workstation
/// already knows the tenant (from activation), so the cashier only enters
/// their `login` + 4-digit PIN. Hits `POST /api/auth/cashier-login`.
///
/// Not a "tap a name from a list" UX (yet) because listing cashiers
/// requires an authenticated call. Once we mint a workstation JWT from
/// activation, we'll swap this for a picker + PIN entry. For now the
/// operator types both.
class CashierLoginScreen extends StatefulWidget {
  const CashierLoginScreen({super.key});

  @override
  State<CashierLoginScreen> createState() => _CashierLoginScreenState();
}

class _CashierLoginScreenState extends State<CashierLoginScreen> {
  final _loginCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _loginFocus = FocusNode();
  final _pinFocus = FocusNode();

  @override
  void dispose() {
    _loginCtrl.dispose();
    _pinCtrl.dispose();
    _loginFocus.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _loginCtrl.text.trim().isNotEmpty && _pinCtrl.text.length >= 4;

  void _submit() {
    if (!_canSubmit) return;
    context.read<AuthBloc>().add(
          CashierLoginRequested(
            login: _loginCtrl.text.trim(),
            pin: _pinCtrl.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход кассира'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // After a successful cashier login the bloc emits
          // AuthAuthenticated — pop this screen so the root boot router
          // takes over and renders the shell. Otherwise we'd leave this
          // screen stacked on top of the shell.
          if (state is AuthAuthenticated) {
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        },
        builder: (context, state) {
          final busy = state is RegisterActivated && state.busy;
          final errorMsg =
              state is RegisterActivated ? state.error : null;
          final ws = state is RegisterActivated ? state.workstation : null;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                margin: const EdgeInsets.all(24),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        ws?.storeName.isNotEmpty == true
                            ? 'Магазин: ${ws!.storeName}'
                            : 'Вход кассира',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _loginCtrl,
                        focusNode: _loginFocus,
                        enabled: !busy,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _pinFocus.requestFocus(),
                        decoration: const InputDecoration(
                          labelText: 'Логин',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _pinCtrl,
                        focusNode: _pinFocus,
                        enabled: !busy,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 22,
                          letterSpacing: 8,
                        ),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: 'PIN',
                          hintText: '••••',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                      ),

                      if (errorMsg != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  size: 18, color: cs.onErrorContainer),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMsg,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: cs.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: (_canSubmit && !busy) ? _submit : null,
                          child: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : Text(
                                  'Войти',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
