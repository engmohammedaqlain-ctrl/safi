import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';

/// أزرار أوضح للضغط — مدمجة (ليست مبالغة بالحجم)
const double _kKeyH = 50.0;
const double _kRowGap = 6.0;
const double _kKeyPadH = 3.5;

/// لوحة مفاتيح — أرقام (هاتف) + عمود % / × − + سطر عشري: . 0(عريض) + = (بدون صف + بعرض كامل)
class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({super.key, required this.onKeyTap});
  final void Function(String) onKeyTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row4(const ['C', 'M+', 'M-', '⌫']),
          SizedBox(height: _kRowGap),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _row4(const ['1', '2', '3', '%']),
                SizedBox(height: _kRowGap),
                _row4(const ['4', '5', '6', '/']),
                SizedBox(height: _kRowGap),
                _row4(const ['7', '8', '9', '-']),
                SizedBox(height: _kRowGap),
                _rowDecimalAndPlus(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row4(List<String> keys) {
    return Row(
      children: keys
          .map(
            (k) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _kKeyPadH),
                child: _PressableKey(
                  keyHeight: _kKeyH,
                  label: k,
                  onTap: () => onKeyTap(k),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// [ . ] [ 0 عريض ] [ + ] [ = ] — دمج + مع بقية الصف (لا يستولي على عرض الشاشة)
  Widget _rowDecimalAndPlus() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kKeyPadH),
            child: _PressableKey(
              keyHeight: _kKeyH,
              label: '.',
              onTap: () => onKeyTap('.'),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kKeyPadH),
            child: _PressableKey(
              keyHeight: _kKeyH,
              label: '0',
              onTap: () => onKeyTap('0'),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kKeyPadH),
            child: _PressableKey(
              keyHeight: _kKeyH,
              label: '+',
              onTap: () => onKeyTap('+'),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kKeyPadH),
            child: _PressableKey(
              keyHeight: _kKeyH,
              label: '=',
              onTap: () => onKeyTap('='),
            ),
          ),
        ),
      ],
    );
  }
}

class _PressableKey extends StatefulWidget {
  const _PressableKey({
    required this.label,
    required this.onTap,
    this.keyHeight = _kKeyH,
  });

  final String label;
  final VoidCallback onTap;
  final double keyHeight;

  @override
  State<_PressableKey> createState() => _PressableKeyState();
}

class _PressableKeyState extends State<_PressableKey>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.label;
    final isOp = ['+', '-', 'x', '/', '%', '='].contains(key);
    final isMem = ['M+', 'M-'].contains(key);
    final isAct = key == 'C' || key == '⌫';
    final isPrimary = isOp || isMem || isAct;

    final Color bg = isPrimary
        ? AppColors.primary.withValues(alpha: _pressed ? 0.18 : 0.08)
        : (_pressed ? const Color(0xFFF3F0F8) : Colors.white);
    final Color tx = isPrimary ? AppColors.primary : Colors.black87;
    final Color borderColor = isPrimary
        ? AppColors.primary.withValues(alpha: _pressed ? 0.45 : 0.20)
        : (_pressed
            ? AppColors.primary.withValues(alpha: 0.30)
            : Colors.grey.shade300);

    Widget child;
    if (key == '⌫') {
      child = Icon(
        LucideIcons.delete,
        color: tx,
        size: widget.keyHeight > 50 ? 20 : 19,
      );
    } else {
      final fs = isMem
          ? 14.0
          : (key == '.' ? 22.0 : (widget.keyHeight * 0.48).clamp(17.0, 22.0));
      child = Text(
        key,
        style: TextStyle(
          fontSize: fs,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
          color: tx,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _setPressed(true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _setPressed(false);
        widget.onTap();
      },
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 85),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 85),
          height: widget.keyHeight,
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
