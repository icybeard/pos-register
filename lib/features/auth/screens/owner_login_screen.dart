import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_bloc.dart';

/// Primary boot screen on the register: owner / admin email + password
/// login against `/api/auth/login` on the .NET central. Registration is
/// done on the web admin (POST /api/signup); the register only signs in.
///
/// On success [AuthBloc] persists the token pair via [AuthTokenStore] and
/// emits [AuthAuthenticated], which `main.dart` routes into the shell.
class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<AuthBloc>().add(
          OwnerLoginRequested(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      // BlocConsumer (not BlocBuilder): we need to BOTH rebuild on state
      // changes AND react to AuthAuthenticated by dismissing this screen.
      // Without the listener, a successful login would emit
      // AuthAuthenticated and main.dart's root BlocBuilder would re-render
      // `home:` as _MainShell underneath — but THIS screen stays on top
      // of the Navigator stack (it was pushed by LoginChooserScreen), so
      // the user sees a frozen login form despite a 200 response.
      // maybePop() is safe whether we were pushed (canPop=true → pops)
      // or rendered as home (canPop=false → no-ops, BlocBuilder above
      // handles the rerender to _MainShell on its own).
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).maybePop();
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          // Login failures land in different state slots depending on
          // whether the device is activated. _emitLoginFailure in
          // AuthBloc routes the error to RegisterActivated(error: …) on
          // activated devices and AuthInitial(error: …) otherwise.
          // Read both so the user sees the message either way.
          final errorMsg = switch (state) {
            AuthInitial(:final error) => error,
            RegisterActivated(:final error) => error,
            _ => null,
          };
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                margin: const EdgeInsets.all(24),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'POS System',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Вход для владельца / администратора',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        TextFormField(
                          controller: _emailCtrl,
                          autofillHints: const [AutofillHints.email],
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enabled: !isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return 'Введите email';
                            if (!t.contains('@')) return 'Некорректный email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _passwordCtrl,
                          // No autofill hints on a POS device — this is an
                          // operator console, not a consumer app. Password
                          // managers (iCloud Keychain, Google Password
                          // Manager) must not offer to save the owner
                          // credential to a shared terminal.
                          autofillHints: const <String>[],
                          autocorrect: false,
                          enableSuggestions: false,
                          obscureText: !_showPassword,
                          enabled: !isLoading,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Введите пароль' : null,
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
                                        fontSize: 13, color: cs.onErrorContainer),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(
                                    'Войти',
                                    style: GoogleFonts.inter(
                                        fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Регистрация выполняется в web-админке.\nКассиры входят по PIN после владельца.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
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
