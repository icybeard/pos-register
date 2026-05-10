import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_bloc.dart';

/// First-boot device activation. Owner generates a one-time code on the
/// web admin (`/stores` → "Activate register"), hands it to the operator,
/// who enters it here. Hits `POST /api/register/activate` which returns
/// the workstation binding and persists it via [WorkstationStore].
///
/// UX deliberately optimised for fat-finger / scan-and-paste:
///   - Big monospace input, auto-uppercase (codes are `[A-Z0-9]` only)
///   - Accepts pasted values with dashes/spaces/lowercase — they're stripped
///   - A "Вставить" shortcut pulls from the clipboard on tap
///   - Server errors are mapped to short, specific Russian strings
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _ctrl = TextEditingController();
  // Server allows 6-16 characters. Admin tooling currently mints 8-character
  // codes; we accept anything in that window without enforcing a hard length.
  static const _minLen = 6;
  static const _maxLen = 16;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _normalised {
    // Strip anything that isn't [A-Z0-9]. Dashes, spaces, case — all go.
    return _ctrl.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  bool get _canSubmit {
    final n = _normalised;
    return n.length >= _minLen && n.length <= _maxLen;
  }

  void _submit() {
    if (!_canSubmit) return;
    // Belt-and-braces re-entry guard. The Enter key on the TextField fires
    // before the BlocBuilder rebuild has propagated `busy=true` back to
    // disable the action button, so a fast double-Enter would otherwise
    // post two activate calls — the second one lands after the code is
    // consumed and shows a misleading "уже использован" on a successful
    // first try. The bloc has its own guard too; this one keeps the UI
    // from even trying.
    final s = context.read<AuthBloc>().state;
    if (s is RegisterNotActivated && s.busy) return;
    if (s is RegisterActivated) return;
    context.read<AuthBloc>().add(ActivateRegisterRequested(_normalised));
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text;
    if (raw == null || raw.isEmpty) return;
    if (!mounted) return;
    setState(() {
      // Normalise first, THEN cap — using raw.length here would RangeError
      // when stripping characters shrinks the string below raw.length.
      final normalised =
          raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      _ctrl.text =
          normalised.substring(0, normalised.length.clamp(0, _maxLen));
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final busy = state is RegisterNotActivated && state.busy;
          final errorMsg =
              state is RegisterNotActivated ? state.error : null;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                margin: const EdgeInsets.all(24),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 48, color: cs.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Активация кассы',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Введите код из web-админки:\nМагазины → Активировать кассу.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Big monospace input. Hardware keyboard handles
                      // most characters; we restrict to [A-Z0-9-\s] and
                      // strip the noise on normalise.
                      TextField(
                        controller: _ctrl,
                        enabled: !busy,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9\-\s]')),
                          // Let the user see the raw input (with dashes);
                          // we strip at submit time. But cap total length
                          // to max+padding so a malicious paste can't flood.
                          LengthLimitingTextInputFormatter(_maxLen + 4),
                        ],
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Код',
                          hintText: 'ABCD-1234',
                          border: const OutlineInputBorder(),
                          // Large height for comfortable tap target.
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.content_paste_go),
                            tooltip: 'Вставить из буфера',
                            onPressed: busy ? null : _pasteFromClipboard,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Регистр и дефисы не важны — мы очистим код.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
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

                      const SizedBox(height: 22),
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
                                  'Активировать',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Код действует один раз и только в течение 24 часов.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
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
