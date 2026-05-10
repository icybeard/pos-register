import 'package:flutter/material.dart';
import '../../../core/theme/hifi.dart';
import '../../../core/utils/money.dart';
import '../../../services/api_client.dart';

/// Hi-fi shift-open screen — section 02 in the design handoff.
///
/// Layout:
///   [navy chrome]
///   ┌ left ─────────────────────── ┬ right (340 navy) ┐
///   │ header: "Открытие смены №43" │ Итого в кассе    │
///   │ denomination table           │  48px mono total │
///   │   20000 · stepper · total    │                  │
///   │   10000 · stepper · total    │ delta card       │
///   │   ...                        │                  │
///   │ totals: ожидаемо / δ / total │ [Открыть смену]  │
///   │                              │ [Отложить]       │
///   └──────────────────────────────┴──────────────────┘
class ShiftScreen extends StatefulWidget {
  final ApiClient api;
  final String cashierId;
  final String cashierName;
  final VoidCallback? onShiftChanged;
  const ShiftScreen({
    super.key,
    required this.api,
    required this.cashierId,
    required this.cashierName,
    this.onShiftChanged,
  });

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  static const denoms = [20000, 10000, 5000, 2000, 1000, 500, 200, 100];

  Map<String, dynamic>? _shift;
  bool _loading = true;
  bool _submitting = false;
  final Map<int, int> _counts = {for (final d in denoms) d: 0};
  int _expected = 0;
  String _shiftNumber = '—';

  int get _total => _counts.entries.fold(0, (s, e) => s + e.key * e.value);

  @override
  void initState() {
    super.initState();
    _loadShift();
  }

  Future<void> _loadShift() async {
    setState(() => _loading = true);
    try {
      final resp = await widget.api.getCurrentShift(widget.cashierId);
      setState(() {
        _shift = resp;
        _shiftNumber = resp['ShiftNumber']?.toString() ?? '—';
        _expected = (resp['ExpectedCash'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        setState(() {
          _shift = null;
          _loading = false;
        });
      }
    } on Exception catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.api.openShift(cashierId: widget.cashierId, cashStart: _total);
      if (mounted) {
        await _loadShift();
        widget.onShiftChanged?.call();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hifi.canvas,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          // Chrome is rendered by the shell (_MainShell._buildShellChrome);
          // ShiftScreen body fills the remainder.
          : (_shift == null ? _buildOpen(context) : _buildOpenedInfo(context)),
    );
  }

  Widget _buildOpen(BuildContext context) {
    return Row(children: [
      // LEFT pane
      Expanded(
        child: Container(
          color: Hifi.paneBg,
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            HifiSectionHeader(
              icon: '💼',
              title: 'Открытие смены',
              subtitle: 'Пересчитайте наличные в денежном ящике',
              trailing: 'Кассир: ${widget.cashierName}',
            ),
            const SizedBox(height: 10),
            Expanded(child: _denomTable()),
            _deltaRow(),
          ]),
        ),
      ),
      // RIGHT pane (navy)
      _rightPane(context),
    ]);
  }

  Widget _buildOpenedInfo(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle_outline, size: 72, color: Hifi.success),
          const SizedBox(height: 16),
          Text('Смена №$_shiftNumber уже открыта', style: Hifi.ui(size: 20, weight: FontWeight.w700, color: Hifi.chrome)),
          const SizedBox(height: 8),
          Text('Работайте на кассе, или закройте смену с Z-отчётом.',
              style: Hifi.ui(size: 13, color: const Color(0xFF666666))),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/pos'),
            icon: const Icon(Icons.point_of_sale),
            label: const Text('Открыть кассу'),
            style: FilledButton.styleFrom(backgroundColor: Hifi.chrome),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/shift-close'),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Закрыть смену + Z-отчёт'),
          ),
        ]),
      ),
    );
  }

  Widget _denomTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Hifi.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(children: [
          // header
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Hifi.tableHead,
              border: Border(bottom: BorderSide(color: Hifi.border)),
            ),
            child: Row(children: [
              SizedBox(width: 120, child: Text('НОМИНАЛ', style: Hifi.ui(size: 11, weight: FontWeight.w600, color: const Color(0xFF555555)))),
              Expanded(child: Center(child: Text('КОЛИЧЕСТВО', style: Hifi.ui(size: 11, weight: FontWeight.w600, color: const Color(0xFF555555))))),
              SizedBox(width: 120, child: Text('СУММА', textAlign: TextAlign.right, style: Hifi.ui(size: 11, weight: FontWeight.w600, color: const Color(0xFF555555)))),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final d in denoms)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Hifi.divider))),
                    child: Row(children: [
                      SizedBox(width: 120, child: Text(Money.formatTenge(d * 100), style: Hifi.mono(size: 14, weight: FontWeight.w600))),
                      Expanded(
                        child: Center(
                          child: HifiStepper(
                            value: _counts[d]!,
                            showInput: true,
                            onDec: () => setState(() => _counts[d] = (_counts[d]! - 1).clamp(0, 999)),
                            onInc: () => setState(() => _counts[d] = _counts[d]! + 1),
                            onChanged: (v) => setState(() => _counts[d] = v.clamp(0, 9999)),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          Money.formatTenge(d * 100 * _counts[d]!),
                          textAlign: TextAlign.right,
                          style: Hifi.mono(size: 14, weight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _deltaRow() {
    final delta = _total - _expected;
    final deltaColor = delta == 0 ? Hifi.success : delta > 0 ? Hifi.warn : Hifi.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('Ожидаемо: ', style: Hifi.ui(size: 13, color: const Color(0xFF666666))),
          Text(Money.formatTenge(_expected), style: Hifi.mono(size: 13, color: const Color(0xFF666666))),
        ]),
        const SizedBox(height: 2),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('Расхождение: ', style: Hifi.ui(size: 13, weight: FontWeight.w600, color: deltaColor)),
          Text('${delta > 0 ? '+' : ''}${Money.formatTenge(delta)}', style: Hifi.mono(size: 13, weight: FontWeight.w600, color: deltaColor)),
        ]),
      ]),
    );
  }

  Widget _rightPane(BuildContext context) {
    final delta = _total - _expected;
    final deltaColor = delta == 0 ? Hifi.chromeOnline : Hifi.chromeOffline;
    return Container(
      width: 340,
      color: Hifi.chrome,
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ИТОГО В КАССЕ',
            style: Hifi.ui(size: 11, color: Colors.white.withValues(alpha: 0.7), weight: FontWeight.w600)
                .copyWith(letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(Money.formatTenge(_total),
            style: Hifi.mono(size: 48, weight: FontWeight.w800, color: Colors.white).copyWith(height: 1)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ожидаемо по закрытию',
                style: Hifi.ui(size: 11, color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 4),
            Text(Money.formatTenge(_expected), style: Hifi.mono(size: 15, color: Colors.white)),
            const SizedBox(height: 10),
            Text('Расхождение',
                style: Hifi.ui(size: 11, color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 4),
            Text('${delta > 0 ? '+' : ''}${Money.formatTenge(delta)}',
                style: Hifi.mono(size: 15, weight: FontWeight.w700, color: deltaColor)),
          ]),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Hifi.chrome,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Открыть смену', style: Hifi.ui(size: 16, weight: FontWeight.w700, color: Hifi.chrome)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.maybePop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.white.withValues(alpha: 0.7)),
            child: const Text('Отложить'),
          ),
        ),
      ]),
    );
  }
}
