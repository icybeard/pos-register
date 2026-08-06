import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../auth/controllers/auth_controller.dart';

/// Standalone (автономный) first-run setup — spec 03 R1. Shown after the
/// owner taps «Пропустить — работать автономно» on the connect screen.
/// Deliberately minimal (name + PIN + store name): everything else lives in
/// Settings. The legacy [SetupWizard] is API-driven and stays untouched for
/// the linked path.
class StandaloneSetupScreen extends ConsumerStatefulWidget {
  const StandaloneSetupScreen({super.key});

  @override
  ConsumerState<StandaloneSetupScreen> createState() =>
      _StandaloneSetupScreenState();
}

class _StandaloneSetupScreenState extends ConsumerState<StandaloneSetupScreen> {
  final _nameC = TextEditingController();
  final _pinC = TextEditingController();
  final _confirmC = TextEditingController();
  final _storeC = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _nameC.dispose();
    _pinC.dispose();
    _confirmC.dispose();
    _storeC.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameC.text.trim().isNotEmpty &&
      _pinC.text.length == 4 &&
      _confirmC.text.length == 4;

  void _submit() {
    if (!_canSubmit) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final l = AppLocalizations.of(context)!;
    if (_pinC.text != _confirmC.text) {
      setState(() => _localError = l.standalonePinMismatch);
      return;
    }
    setState(() => _localError = null);
    ref
        .read(authControllerProvider.notifier)
        .finishStandaloneSetup(
          ownerName: _nameC.text,
          pin: _pinC.text,
          storeName: _storeC.text.trim().isEmpty
              ? l.standaloneStoreDefault
              : _storeC.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(authControllerProvider);
    final busy = state is StandaloneSetupRequired && state.busy;
    final error =
        _localError ?? (state is StandaloneSetupRequired ? state.error : null);

    // MediaQuery.fromView restores the REAL keyboard viewInsets that the
    // app-level builder zeroes out (that global override keeps POS layouts
    // from being squeezed by the keyboard, but here it left the submit
    // button hidden underneath it). With real insets the Scaffold resizes
    // above the keyboard and the scroll view keeps every field reachable.
    return MediaQuery.fromView(
      view: View.of(context),
      child: Scaffold(
        // Tap anywhere outside a field to dismiss the keyboard — the iOS
        // numeric pad has no Done key, so without this the PIN keyboard
        // could not be dismissed at all.
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.standaloneTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.standaloneSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameC,
                        enabled: !busy,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: l.standaloneOwnerName,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _storeC,
                        enabled: !busy,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l.standaloneStoreName,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _pinC,
                              enabled: !busy,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: l.standalonePin,
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _confirmC,
                              enabled: !busy,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              // The iOS number pad has no Done key — drop the
                              // keyboard once the 4th confirm digit is in so
                              // the submit button is immediately visible.
                              onChanged: (v) {
                                setState(() {});
                                if (v.length == 4) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                }
                              },
                              onSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: l.standalonePinConfirm,
                                counterText: '',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: cs.error,
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
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  l.standaloneStart,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => ref
                                  .read(authControllerProvider.notifier)
                                  .cancelStandaloneSetup(),
                        child: Text(
                          l.standaloneBackToConnect,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
