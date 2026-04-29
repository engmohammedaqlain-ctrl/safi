import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/safi_brand_mark.dart';
import '../providers/debts_ui_provider.dart';

/// بطاقة إيصال بنفس تصميم شاشة «تمت العملية بنجاح» — للعرض أو لتصدير صورة.
class DebtTransactionReceiptCard extends StatelessWidget {
  const DebtTransactionReceiptCard({
    super.key,
    required this.customerName,
    required this.amount,
    required this.type,
    required this.date,
    this.counterpartyLabel = 'العميل',
    this.paymentMethod,
    this.note,
  });

  final String customerName;
  final double amount;
  final TransactionType type;
  final DateTime date;

  /// «العميل» أو «المورد»
  final String counterpartyLabel;

  final String? paymentMethod;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final isGave = type == TransactionType.gave;
    final accentColor = isGave ? const Color(0xFFE53935) : const Color(0xFF43A047);
    final bgColor = isGave ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final label = isGave ? 'دين جديد' : 'سداد';
    final sign = isGave ? '+' : '-';

    final timeStr = formatReceiptTime(date);
    final dateStr = formatReceiptDate(date);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: accentColor.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$sign${amount.toStringAsFixed(2)} ₪',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                    letterSpacing: -0.5,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _DashedCircle(color: const Color(0xFFF5F5F8)),
                Expanded(
                  child: Row(
                    children: List.generate(
                      30,
                      (i) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height: 1.5,
                          color: i.isEven ? Colors.grey.shade300 : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
                _DashedCircle(color: const Color(0xFFF5F5F8)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                _ReceiptRow(label: counterpartyLabel, value: customerName),
                const SizedBox(height: 12),
                _ReceiptRow(label: 'نوع العملية', value: label),
                const SizedBox(height: 12),
                _ReceiptRow(label: 'التاريخ', value: dateStr),
                const SizedBox(height: 12),
                _ReceiptRow(label: 'الوقت', value: timeStr),
                if (paymentMethod != null && paymentMethod!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ReceiptRow(label: 'وسيلة الدفع', value: paymentMethod!),
                ],
                if (note != null && note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ReceiptRow(label: 'ملاحظة', value: note!, multiline: true),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SafiBrandMark(size: 24),
                const SizedBox(width: 6),
                const Text(
                  'الصافي',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textMuted,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: multiline ? 1.35 : 1.2,
            ),
            maxLines: multiline ? 8 : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DashedCircle extends StatelessWidget {
  const _DashedCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

String formatReceiptTime(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String formatReceiptDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}
