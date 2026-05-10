import 'package:flutter/material.dart';

/// Экранная цифровая клавиатура для POS-терминалов без физической клавиатуры.
class NumPad extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool allowDecimal;
  final double buttonHeight;
  final double spacing;

  const NumPad({
    super.key,
    required this.controller,
    this.onChanged,
    this.allowDecimal = false,
    this.buttonHeight = 58,
    this.spacing = 8,
  });

  void _onDigit(String digit) {
    final text = controller.text;
    if (text == '0' && digit != '.' && digit != '0') {
      controller.text = digit;
    } else if (text == '0' && digit == '0') {
      return;
    } else {
      controller.text = text + digit;
    }
    onChanged?.call(controller.text);
  }

  void _onDot() {
    if (!allowDecimal) return;
    final text = controller.text;
    if (text.contains('.')) return;
    controller.text = text.isEmpty ? '0.' : '$text.';
    onChanged?.call(controller.text);
  }

  void _onBackspace() {
    final text = controller.text;
    if (text.isEmpty) return;
    controller.text = text.substring(0, text.length - 1);
    onChanged?.call(controller.text);
  }

  void _onClear() {
    controller.text = '';
    onChanged?.call(controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(cs, ['7', '8', '9']),
        SizedBox(height: spacing),
        _buildRow(cs, ['4', '5', '6']),
        SizedBox(height: spacing),
        _buildRow(cs, ['1', '2', '3']),
        SizedBox(height: spacing),
        _buildRow(cs, [allowDecimal ? '.' : 'C', '0', '<']),
      ],
    );
  }

  Widget _buildRow(ColorScheme cs, List<String> keys) {
    return Row(
      children: keys.map((key) {
        final isAction = key == 'C' || key == '<' || key == '.';
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: SizedBox(
              height: buttonHeight,
              child: Material(
                color: isAction ? cs.surfaceContainer : cs.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    if (key == '<') { _onBackspace(); }
                    else if (key == 'C') { _onClear(); }
                    else if (key == '.') { _onDot(); }
                    else { _onDigit(key); }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: key == '<'
                          ? Icon(Icons.backspace_outlined, size: 22, color: cs.onSurfaceVariant)
                          : Text(
                              key,
                              style: TextStyle(fontFamily: 'Inter', 
                                fontSize: key == 'C' || key == '.' ? 18 : 26,
                                fontWeight: FontWeight.w500,
                                color: isAction ? cs.onSurfaceVariant : cs.onSurface,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Кнопки быстрого ввода сумм (номиналы купюр KZT)
class QuickAmountButtons extends StatelessWidget {
  final List<int> amounts;
  final ValueChanged<int> onSelect;

  const QuickAmountButtons({
    super.key,
    this.amounts = const [500, 1000, 2000, 5000, 10000, 20000],
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amounts.map((amount) {
        final label = amount >= 1000 ? '${amount ~/ 1000}K' : '$amount';
        return SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: () => onSelect(amount),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.primary,
              side: BorderSide(color: cs.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: Text('$label ₸', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        );
      }).toList(),
    );
  }
}
