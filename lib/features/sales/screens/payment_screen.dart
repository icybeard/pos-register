import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/feature_flags.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/hifi.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/num_pad.dart';
import '../../../services/api_client.dart';

enum PaymentMethod { cash, card, kaspiQR, mixed, debt }

class PaymentScreen extends StatefulWidget {
  final int totalTiyin;
  final int vatAmount;
  final String? shiftId;
  final ApiClient? api;
  final String? cashierId;

  const PaymentScreen({
    super.key,
    required this.totalTiyin,
    required this.vatAmount,
    this.shiftId,
    this.api,
    this.cashierId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.cash;
  final _cashController = TextEditingController();
  final _cardController = TextEditingController();
  final _qrController = TextEditingController();
  int _cashTiyin = 0;
  int _cardTiyin = 0;
  int _qrTiyin = 0;

  _ActiveField _activeField = _ActiveField.cash;

  // Debt state
  List<Map<String, dynamic>> _clients = [];
  Map<String, dynamic>? _selectedClient;
  bool _loadingClients = false;

  // Processing state
  bool _processing = false;
  Timer? _timeoutTimer;
  int _timeoutSeconds = 0;
  static const _paymentTimeoutDuration = 30; // seconds

  int get _changeTiyin {
    final paid = _cashTiyin + _cardTiyin + _qrTiyin;
    return paid > widget.totalTiyin ? paid - widget.totalTiyin : 0;
  }

  bool get _canPay {
    if (_method == PaymentMethod.debt) {
      return _selectedClient != null;
    }
    return (_cashTiyin + _cardTiyin + _qrTiyin) >= widget.totalTiyin;
  }

  TextEditingController get _activeController => switch (_activeField) {
    _ActiveField.cash => _cashController,
    _ActiveField.card => _cardController,
    _ActiveField.qr => _qrController,
  };

  @override
  void initState() {
    super.initState();
    _cashController.text = Money.tiyinToTenge(widget.totalTiyin).toStringAsFixed(0);
    _cashTiyin = widget.totalTiyin;
  }

  @override
  void dispose() {
    _cashController.dispose();
    _cardController.dispose();
    _qrController.dispose();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _selectMethod(PaymentMethod method) {
    setState(() {
      _method = method;
      _cashTiyin = 0; _cardTiyin = 0; _qrTiyin = 0;
      _cashController.clear(); _cardController.clear(); _qrController.clear();
      _activeField = _ActiveField.cash;
      _selectedClient = null;
      if (method == PaymentMethod.cash) {
        _cashTiyin = widget.totalTiyin;
        _cashController.text = Money.tiyinToTenge(widget.totalTiyin).toStringAsFixed(0);
      } else if (method == PaymentMethod.card) {
        _cardTiyin = widget.totalTiyin;
      } else if (method == PaymentMethod.kaspiQR) {
        _qrTiyin = widget.totalTiyin;
      } else if (method == PaymentMethod.mixed) {
        _cashTiyin = widget.totalTiyin;
        _cashController.text = Money.tiyinToTenge(widget.totalTiyin).toStringAsFixed(0);
      } else if (method == PaymentMethod.debt) {
        _loadClients();
      }
    });
  }

  Future<void> _loadClients() async {
    if (widget.api == null) return;
    setState(() => _loadingClients = true);
    try {
      final resp = await widget.api!.listClients();
      final clients = (resp['clients'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) setState(() { _clients = clients; _loadingClients = false; });
    } on Exception catch (_) {
      if (mounted) setState(() => _loadingClients = false);
    }
  }

  void _onNumPadChanged(String value) {
    final tenge = double.tryParse(value) ?? 0;
    final tiyin = Money.tengeToTiyin(tenge);
    setState(() {
      switch (_activeField) {
        case _ActiveField.cash: _cashTiyin = tiyin;
        case _ActiveField.card: _cardTiyin = tiyin;
        case _ActiveField.qr: _qrTiyin = tiyin;
      }
    });
  }

  void _onQuickAmount(int tenge) {
    final controller = _method == PaymentMethod.mixed ? _activeController : _cashController;
    controller.text = tenge.toString();
    _onNumPadChanged(tenge.toString());
  }

  void _pay() {
    // Shift validation
    if (widget.shiftId == null || widget.shiftId!.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.paymentNoShift), backgroundColor: PosColors.of(context).warningFg),
      );
      return;
    }
    // Defensive guard: even if a card / Kaspi QR tile somehow becomes
    // selectable while [FeatureFlags.cardTerminalEnabled] is off (e.g.
    // race between flag hydration and the user tapping), refuse to
    // proceed. Without this the 2-second Future.delayed stub fires and
    // we'd record a successful card sale against a declined transaction.
    final flags = context.read<FeatureFlags>();
    if (!flags.cardTerminalEnabled &&
        (_method == PaymentMethod.card || _method == PaymentMethod.kaspiQR)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.paymentTerminalUnavailable),
          backgroundColor: PosColors.of(context).warningFg,
        ),
      );
      return;
    }

    if (_method == PaymentMethod.debt) {
      _payDebt();
      return;
    }

    // For card and Kaspi QR — show processing with timeout
    if (_method == PaymentMethod.card || _method == PaymentMethod.kaspiQR) {
      _startProcessingWithTimeout();
      return;
    }

    _completePayment();
  }

  void _startProcessingWithTimeout() {
    setState(() {
      _processing = true;
      _timeoutSeconds = _paymentTimeoutDuration;
    });

    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _timeoutSeconds--);
      if (_timeoutSeconds <= 0) {
        timer.cancel();
        setState(() => _processing = false);
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.paymentTimeout), backgroundColor: PosColors.of(context).errorFg),
        );
      }
    });

    // Card / Kaspi QR terminal stub — debug builds only. The real
    // integration is a callback from a TerminalService that observes the
    // hardware terminal (or Kaspi QR webhook). In a release build the
    // operator must complete the sale manually (or the real integration
    // must be wired) — auto-approving without a confirmation is a
    // mis-charge waiting to happen on a live device.
    if (kDebugMode) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _processing) {
          _timeoutTimer?.cancel();
          _completePayment();
        }
      });
    }
  }

  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    setState(() => _processing = false);
  }

  void _completePayment() {
    // Belt-and-braces: callers (Future.delayed terminal-stub, _payCashOnly,
    // _payCardOnly etc.) check `mounted` before calling, but a race between
    // the check and this body could still hit a disposed widget — verify
    // again before we touch state or context.
    if (!mounted) return;
    setState(() => _processing = false);
    _timeoutTimer?.cancel();

    // Show confirmation screen instead of popping immediately
    Navigator.pushReplacement<Map<String, dynamic>, void>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => _PaymentConfirmation(
          totalTiyin: widget.totalTiyin,
          changeTiyin: _changeTiyin,
          method: _method,
          // TODO(receipt-id): CompleteSale's response should carry the
          // server-assigned receipt id (with shift sequence number) and
          // get plumbed through to this screen. The "—" below makes it
          // obvious that no real number is shown yet, instead of the
          // previous `millisecondsSinceEpoch % 100000` which looked like
          // a legitimate receipt number while being a wall-clock dice roll.
          receiptNumber: '—',
          onNewReceipt: () {
            Navigator.pop(context);
          },
          result: {
            'method': _method.name,
            'cash': _cashTiyin,
            'card': _cardTiyin,
            'qr': _qrTiyin,
            'change': _changeTiyin,
          },
        ),
      ),
    );
  }

  void _payDebt() {
    if (_selectedClient == null) return;

    setState(() => _processing = false);

    Navigator.pop(context, {
      'method': 'debt',
      'cash': 0,
      'card': 0,
      'qr': 0,
      'change': 0,
      'client_id': _selectedClient!['ID'] as String? ?? '',
      'client_name': _selectedClient!['Name'] as String? ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;
    final cardEnabled = context.read<FeatureFlags>().cardTerminalEnabled;

    return Scaffold(
      backgroundColor: Hifi.canvas,
      // Push-routed flow from POS — outside _MainShell. Use the navy
      // chrome with a back-button instead of a Material AppBar so the
      // visual language stays consistent with the rest of the app.
      appBar: HifiChrome(
        leading: BackButton(color: Colors.white, onPressed: () => Navigator.of(context).maybePop()),
        title: l.paymentTitle,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: _processing
                      ? _buildProcessingOverlay(l, cs, pos)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Total card
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    const BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 24, offset: Offset(0, 8)),
                                  ],
                                ),
                                child: Column(children: [
                                  Text(l.paymentToPay, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: cs.onSurfaceVariant)),
                                  const SizedBox(height: 6),
                                  Text(Money.format(widget.totalTiyin),
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
                                  const SizedBox(height: 4),
                                  Text(l.paymentVatLine(Money.format(widget.vatAmount)),
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.outline)),
                                ]),
                              ),
                              const SizedBox(height: 16),

                              // Method buttons (5 methods now). Card +
                              // Kaspi QR render disabled (null onTap) when
                              // [FeatureFlags.cardTerminalEnabled] is off
                              // — see the flag comment for why the path is
                              // gated until a real PED is wired in.
                              Row(children: [
                                Expanded(child: _MethodButton(icon: Icons.payments_outlined, label: l.paymentCash,
                                  selected: _method == PaymentMethod.cash, onTap: () => _selectMethod(PaymentMethod.cash))),
                                const SizedBox(width: 6),
                                Expanded(child: _MethodButton(icon: Icons.credit_card_outlined, label: l.paymentCard,
                                  selected: _method == PaymentMethod.card,
                                  onTap: cardEnabled ? () => _selectMethod(PaymentMethod.card) : null)),
                                const SizedBox(width: 6),
                                Expanded(child: _MethodButton(icon: Icons.qr_code_rounded, label: l.paymentKaspiQR,
                                  selected: _method == PaymentMethod.kaspiQR,
                                  onTap: cardEnabled ? () => _selectMethod(PaymentMethod.kaspiQR) : null)),
                                const SizedBox(width: 6),
                                Expanded(child: _MethodButton(icon: Icons.swap_horiz_rounded, label: l.paymentMix,
                                  selected: _method == PaymentMethod.mixed, onTap: () => _selectMethod(PaymentMethod.mixed))),
                                const SizedBox(width: 6),
                                Expanded(child: _MethodButton(icon: Icons.account_balance_wallet_outlined, label: l.paymentDebt,
                                  selected: _method == PaymentMethod.debt, onTap: () => _selectMethod(PaymentMethod.debt))),
                              ]),
                              const SizedBox(height: 16),

                              // Cash
                              if (_method == PaymentMethod.cash) ...[
                                _AmountDisplay(label: l.paymentCash, icon: Icons.payments_outlined,
                                  value: _cashController.text, isActive: true, cs: cs),
                                if (_changeTiyin > 0) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    decoration: BoxDecoration(color: pos.warningBg, borderRadius: BorderRadius.circular(14)),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text(l.paymentChange, style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: pos.warningFg)),
                                      Text(Money.format(_changeTiyin), style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800, color: pos.warningFg)),
                                    ]),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                QuickAmountButtons(onSelect: _onQuickAmount),
                                const SizedBox(height: 14),
                                NumPad(controller: _cashController, onChanged: _onNumPadChanged),
                              ],

                              // Mixed
                              if (_method == PaymentMethod.mixed) ...[
                                _AmountDisplay(label: l.paymentCash, icon: Icons.payments_outlined,
                                  value: _cashController.text, isActive: _activeField == _ActiveField.cash, cs: cs,
                                  onTap: () => setState(() => _activeField = _ActiveField.cash)),
                                const SizedBox(height: 8),
                                _AmountDisplay(label: l.paymentCard, icon: Icons.credit_card_outlined,
                                  value: _cardController.text, isActive: _activeField == _ActiveField.card, cs: cs,
                                  onTap: () => setState(() => _activeField = _ActiveField.card)),
                                const SizedBox(height: 8),
                                _AmountDisplay(label: l.paymentKaspiQR, icon: Icons.qr_code_rounded,
                                  value: _qrController.text, isActive: _activeField == _ActiveField.qr, cs: cs,
                                  onTap: () => setState(() => _activeField = _ActiveField.qr)),
                                const SizedBox(height: 8),
                                _MixedSummary(total: widget.totalTiyin, paid: _cashTiyin + _cardTiyin + _qrTiyin, cs: cs, pos: pos),
                                const SizedBox(height: 14),
                                QuickAmountButtons(onSelect: _onQuickAmount),
                                const SizedBox(height: 14),
                                NumPad(controller: _activeController, onChanged: _onNumPadChanged),
                              ],

                              // Card
                              if (_method == PaymentMethod.card)
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(18),
                                    boxShadow: [const BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 24, offset: Offset(0, 8))]),
                                  child: Column(children: [
                                    Container(width: 72, height: 72,
                                      decoration: BoxDecoration(color: pos.accentBg, borderRadius: BorderRadius.circular(18)),
                                      child: Icon(Icons.contactless_outlined, color: pos.accentFg, size: 36)),
                                    const SizedBox(height: 20),
                                    Text(l.paymentCardHint, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16)),
                                    const SizedBox(height: 6),
                                    Text('${l.paymentToPay}: ${Money.format(widget.totalTiyin)}', style: TextStyle(fontFamily: 'Inter', color: cs.outline, fontSize: 14)),
                                  ]),
                                ),

                              // Kaspi QR
                              if (_method == PaymentMethod.kaspiQR)
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(18),
                                    boxShadow: [const BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 24, offset: Offset(0, 8))]),
                                  child: Column(children: [
                                    Container(width: 108, height: 108,
                                      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                                      child: Icon(Icons.qr_code_2, size: 64, color: pos.accentFg)),
                                    const SizedBox(height: 18),
                                    Text(l.paymentQRHint, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16)),
                                    const SizedBox(height: 6),
                                    Text('${l.paymentToPay}: ${Money.format(widget.totalTiyin)}', style: TextStyle(fontFamily: 'Inter', color: cs.onSurfaceVariant, fontSize: 14)),
                                  ]),
                                ),

                              // Debt
                              if (_method == PaymentMethod.debt) _buildDebtSection(l, cs, pos),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                ),

                // Pay button
                if (!_processing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: SizedBox(height: 60, width: double.infinity, child: ElevatedButton(
                      onPressed: _canPay ? _pay : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _method == PaymentMethod.debt ? const Color(0xFFD97706) : AppTheme.success,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.success.withValues(alpha: 0.25),
                        disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
                      ),
                      child: Text(
                        _method == PaymentMethod.debt
                            ? '${l.paymentDebt} — ${Money.format(widget.totalTiyin)}'
                            : _canPay
                                ? l.paymentPayButton(Money.format(widget.totalTiyin))
                                : l.paymentPendingButton(Money.format(widget.totalTiyin - _cashTiyin - _cardTiyin - _qrTiyin)),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    )),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Debt section ──────────────────────────────────────────

  Widget _buildDebtSection(AppLocalizations l, ColorScheme cs, PosColors pos) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [const BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.account_balance_wallet_outlined, size: 22, color: pos.warningFg),
          const SizedBox(width: 10),
          Text(l.paymentDebtHint, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: cs.onSurfaceVariant)),
        ]),
        const SizedBox(height: 16),

        if (_loadingClients)
          const Center(child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ))
        else if (_clients.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(l.paymentSelectClient, style: TextStyle(fontFamily: 'Inter', color: cs.outline)),
          ))
        else
          _DebtClientList(
            clients: _clients,
            selectedId: _selectedClient?['ID'] as String?,
            onSelect: (Map<String, dynamic> client) => setState(() => _selectedClient = client),
          ),
      ]),
    );
  }

  // ─── Processing overlay ────────────────────────────────────

  Widget _buildProcessingOverlay(AppLocalizations l, ColorScheme cs, PosColors pos) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3)),
        const SizedBox(height: 24),
        Text(l.paymentProcessing, style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          '${_timeoutSeconds}s',
          style: TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w800, color: cs.outline),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: _cancelTimeout,
          icon: const Icon(Icons.cancel_outlined),
          label: Text(l.paymentCancelTimeout),
          style: TextButton.styleFrom(foregroundColor: pos.errorFg),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Payment Confirmation Screen
// ═══════════════════════════════════════════════════════════════

class _PaymentConfirmation extends StatelessWidget {
  final int totalTiyin;
  final int changeTiyin;
  final PaymentMethod method;
  final String receiptNumber;
  final VoidCallback onNewReceipt;
  final Map<String, dynamic> result;

  const _PaymentConfirmation({
    required this.totalTiyin,
    required this.changeTiyin,
    required this.method,
    required this.receiptNumber,
    required this.onNewReceipt,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success icon
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: pos.successBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, size: 48, color: pos.successFg),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l.paymentSuccess,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800, color: pos.successFg),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.paymentReceiptNumber(receiptNumber),
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),

                    // Payment details card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          const BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 24, offset: Offset(0, 8)),
                        ],
                      ),
                      child: Column(children: [
                        _ConfirmRow(l.paymentToPay, Money.format(totalTiyin)),
                        const SizedBox(height: 8),
                        _ConfirmRow(
                          _methodLabel(method, l),
                          Money.format(totalTiyin),
                          color: cs.primary,
                        ),
                        if (changeTiyin > 0) ...[
                          const SizedBox(height: 8),
                          _ConfirmRow(l.paymentChange, Money.format(changeTiyin), color: pos.warningFg),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 32),

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Pop this screen and return result to POS
                          Navigator.pop(context, result);
                        },
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: Text(l.paymentNewReceipt, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    // TODO(print): the "Распечатать копию" button lived here
                    // but only showed a snackbar with its own label — a dead
                    // CTA on the post-sale confirmation screen. Hidden until
                    // printer integration lands (separate milestone: printer
                    // driver + receipt PDF template). Re-enable by restoring
                    // an OutlinedButton.icon with onPressed wired to the
                    // `printing` package + a receipt PDF built from `result`.
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _methodLabel(PaymentMethod m, AppLocalizations l) => switch (m) {
    PaymentMethod.cash => l.paymentCash,
    PaymentMethod.card => l.paymentCard,
    PaymentMethod.kaspiQR => l.paymentKaspiQR,
    PaymentMethod.mixed => l.paymentMix,
    PaymentMethod.debt => l.paymentDebt,
  };
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _ConfirmRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: c)),
      Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: c)),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// Shared widgets
// ═══════════════════════════════════════════════════════════════

enum _ActiveField { cash, card, qr }

class _AmountDisplay extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool isActive;
  final ColorScheme cs;
  final VoidCallback? onTap;

  const _AmountDisplay({
    required this.label, required this.icon, required this.value,
    required this.isActive, required this.cs, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? cs.primary : cs.outlineVariant, width: isActive ? 2 : 1),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: isActive ? cs.primary : cs.onSurfaceVariant),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: cs.onSurfaceVariant)),
          const Spacer(),
          Text(value.isEmpty ? '0' : '$value ₸',
            style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700,
              color: isActive ? cs.onSurface : cs.onSurfaceVariant)),
          if (isActive) ...[
            const SizedBox(width: 6),
            Container(width: 2, height: 26, decoration: BoxDecoration(
              color: cs.primary, borderRadius: BorderRadius.circular(1))),
          ],
        ]),
      ),
    );
  }
}

class _MixedSummary extends StatelessWidget {
  final int total;
  final int paid;
  final ColorScheme cs;
  final PosColors pos;

  const _MixedSummary({required this.total, required this.paid, required this.cs, required this.pos});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final remaining = total - paid;
    final isEnough = remaining <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isEnough ? pos.successBg : pos.warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(isEnough ? l.paymentChange : l.paymentRemaining, style: TextStyle(fontFamily: 'Inter',
          fontSize: 14, fontWeight: FontWeight.w600, color: isEnough ? pos.successFg : pos.warningFg)),
        Text(Money.format(isEnough ? paid - total : remaining), style: TextStyle(fontFamily: 'Inter', 
          fontSize: 20, fontWeight: FontWeight.w800, color: isEnough ? pos.successFg : pos.warningFg)),
      ]),
    );
  }
}

class _MethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  /// Null = disabled (greyed, non-tappable). Used for the card and Kaspi
  /// QR tiles when [FeatureFlags.cardTerminalEnabled] is off.
  final VoidCallback? onTap;
  const _MethodButton({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Material(
        color: selected ? cs.primaryContainer : cs.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2 : 1),
            ),
            child: Column(children: [
              Icon(icon, size: 24, color: selected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? cs.primary : cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Renders the selectable client list inside the debt payment section.
/// Extracted from `_PaymentScreenState._buildDebtSection` so a `setState`
/// up in the parent (timeout countdown tick, method change, etc.) doesn't
/// rebuild the full client list — Flutter can reuse this element subtree
/// when only the parent state changes.
class _DebtClientList extends StatelessWidget {
  const _DebtClientList({
    required this.clients,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> clients;
  final String? selectedId;
  final ValueChanged<Map<String, dynamic>> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    return Column(
      children: List.generate(clients.length, (i) {
        final client = clients[i];
        final name = client['Name'] as String? ?? '';
        final phone = client['Phone'] as String? ?? '';
        final isSelected = selectedId != null && selectedId == (client['ID'] as String?);
        return Padding(
          padding: EdgeInsets.only(bottom: i < clients.length - 1 ? 8 : 0),
          child: GestureDetector(
            onTap: () => onSelect(client),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? pos.warningBg : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? pos.warningFg : cs.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.person_outline,
                  size: 20,
                  color: isSelected ? pos.warningFg : cs.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name,
                        style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                    if (phone.isNotEmpty)
                      Text(phone,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.outline)),
                  ]),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }
}
