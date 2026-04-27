import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';

/// لوحة مفاتيح الآلة الحاسبة — تصميم مطابق لتطبيق Konnash
class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({super.key, required this.onKeyTap});
  final void Function(String) onKeyTap;

  @override
  Widget build(BuildContext context) {
    // تُرث اتجاه الصفحة (RTL) فتُعكس صفوف المفاتيح من اليمين لليسار
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row4(['C', 'M+', 'M-', '⌫']),
          const SizedBox(height: 10),
          _row2Special(['7', '8', '9'], '/', '%'),
          const SizedBox(height: 10),
          _row4(['4', '5', '6', 'x']),
          const SizedBox(height: 10),
          _row4(['1', '2', '3', '-']),
          const SizedBox(height: 10),
          _row4(['0', '.', '=', '+']),
        ],
      ),
    );
  }

  Widget _row4(List<String> keys) {
    return Row(
      children: keys
          .map((k) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _btn(k),
                ),
              ))
          .toList(),
    );
  }

  Widget _row2Special(List<String> firstThree, String op1, String op2) {
    return Row(
      children: [
        ...firstThree.map((k) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _btn(k),
              ),
            )),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(child: _btn(op1)),
                const SizedBox(width: 8),
                Expanded(child: _btn(op2)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _btn(String key) {
    final isOp = ['+', '-', 'x', '/', '%', '='].contains(key);
    final isMem = ['M+', 'M-'].contains(key);
    final isAct = key == 'C' || key == '⌫';

    Color bg;
    Color tx;
    Color borderColor;

    if (isOp || isMem || isAct) {
      bg = AppColors.primary.withValues(alpha: 0.08);
      tx = AppColors.primary;
      borderColor = AppColors.primary.withValues(alpha: 0.2);
    } else {
      bg = Colors.white;
      tx = Colors.black87;
      borderColor = Colors.grey.shade300;
    }

    Widget child;
    if (key == '⌫') {
      child = Icon(LucideIcons.delete, color: tx, size: 20);
    } else {
      child = Text(
        key,
        style: TextStyle(
          fontSize: isMem ? 16 : 22,
          fontWeight: isOp || isMem || isAct ? FontWeight.bold : FontWeight.w500,
          color: tx,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onKeyTap(key),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
