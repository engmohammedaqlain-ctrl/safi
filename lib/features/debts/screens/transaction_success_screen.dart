import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/debts_ui_provider.dart';

/// شاشة النجاح — تظهر بعد تسجيل أعطيت / أخذت وتختفي تلقائيًا بعد 4 ثواني
class TransactionSuccessScreen extends StatefulWidget {
  const TransactionSuccessScreen({
    super.key,
    required this.customerName,
    required this.amount,
    required this.type,
    required this.date,
  });

  final String customerName;
  final double amount;
  final TransactionType type;
  final DateTime date;

  @override
  State<TransactionSuccessScreen> createState() =>
      _TransactionSuccessScreenState();
}

class _TransactionSuccessScreenState extends State<TransactionSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _slideAnim;

  Timer? _countdownTimer;
  int _secondsLeft = 4;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    _entryController.forward();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _navigateBack();
      }
    });
  }

  void _navigateBack() {
    _countdownTimer?.cancel();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGave = widget.type == TransactionType.gave;
    final accentColor = isGave ? const Color(0xFFE53935) : const Color(0xFF43A047);
    final bgColor = isGave ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final label = isGave ? 'أعطيت' : 'أخذت';
    final sign = isGave ? '+' : '-';
    final timeStr = _formatTime(widget.date);
    final dateStr = _formatDate(widget.date);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        children: [
                          // ── أيقونة النجاح ──
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: accentColor,
                              size: 52,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── العنوان ──
                          const Text(
                            'تمت العملية بنجاح',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'سيتم الإغلاق تلقائياً خلال $_secondsLeft ثانية',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── البطاقة ──
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // ── قسم المبلغ (ملوّن) ──
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
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: accentColor.withOpacity(0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$sign${widget.amount.toStringAsFixed(2)} ₪',
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // ── فاصل ──
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

                                // ── تفاصيل الإيصال ──
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  child: Column(
                                    children: [
                                      _ReceiptRow(label: 'العميل', value: widget.customerName),
                                      const SizedBox(height: 12),
                                      _ReceiptRow(label: 'نوع العملية', value: label),
                                      const SizedBox(height: 12),
                                      _ReceiptRow(label: 'التاريخ', value: dateStr),
                                      const SizedBox(height: 12),
                                      _ReceiptRow(label: 'الوقت', value: timeStr),
                                    ],
                                  ),
                                ),

                                // ── شعار التطبيق ──
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          gradient: AppColors.primaryGradient,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'ص',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'صافي',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // ── أزرار ──
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // TODO: مشاركة الإيصال
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.share_outlined, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'مشاركة',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _navigateBack,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'إنهاء',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── صف تفصيلة في الإيصال ──
class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

// ── الدائرة الجانبية لفاصل الإيصال ──
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

// ── تنسيق الوقت ──
String _formatTime(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// ── تنسيق التاريخ ──
String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}
