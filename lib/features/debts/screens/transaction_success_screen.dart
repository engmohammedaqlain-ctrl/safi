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
    required this.type, // gave = أعطيت, received = أخذت
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
  late final AnimationController _cardController;
  late final AnimationController _titleController;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;

  Timer? _autoNavTimer;
  int _secondsLeft = 4;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    HapticFeedback.mediumImpact();

    // Animation: card scales up + fades in
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardScale = CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    );
    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: const Interval(0, 0.4)),
    );

    // Animation: title slides down + fades in
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(_titleController);
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );

    _titleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardController.forward();
    });

    // Auto-navigate back after 4 seconds
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _navigateBack();
      }
    });
  }

  void _navigateBack() {
    _countdownTimer?.cancel();
    _autoNavTimer?.cancel();
    if (mounted) {
      // pushReplacement was used, so success screen IS the top — one pop() returns to CustomerDetailScreen
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    _titleController.dispose();
    _autoNavTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGave = widget.type == TransactionType.gave;
    final amountColor = isGave ? Colors.red : Colors.green;
    final sign = isGave ? '+' : '-';

    final timeStr = _formatTime(widget.date);
    final amountStr =
        '${widget.amount.toStringAsFixed(2)} ₪';

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // يمنع تقلص الشاشة أثناء إغلاق الكيبورد
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),

              // ── العنوان ──
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _titleOpacity,
                  child: Column(
                    children: [
                      Text(
                        'تمت المعاملة بنجاح',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // تم إخفاء العداد بناءً على طلب المستخدم
                      // Text(
                      //   'ستُغلق الصفحة تلقائياً خلال $_secondsLeft ثواني',
                      //   style: const TextStyle(
                      //     fontSize: 13,
                      //     color: Colors.grey,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ── البطاقة ──
              ScaleTransition(
                scale: _cardScale,
                child: FadeTransition(
                  opacity: _cardOpacity,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // خلفية زخرفية (نمط أرابيسك خفيف)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CustomPaint(
                              painter: _PatternPainter(),
                            ),
                          ),
                        ),

                        // المحتوى
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // اسم العميل
                              Text(
                                widget.customerName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // التاريخ والوقت
                              Text(
                                'اليوم ساعة $timeStr',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // نوع المعاملة
                              Text(
                                isGave ? 'أعطيت' : 'أخذت',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: amountColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // المبلغ
                              Text(
                                '$sign$amountStr',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: amountColor,
                                ),
                              ),
                              const SizedBox(height: 28),
                              // شعار التطبيق
                              _AppBadge(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── أزرار ──
              FadeTransition(
                opacity: _cardOpacity,
                child: Row(
                  children: [
                    // زر إنهاء
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _navigateBack,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'إنهاء',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // زر مشاركة
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: مشاركة الإيصال
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'مشاركة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── تنسيق الوقت بدون مكتبة intl ──
String _formatTime(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// ── شعار التطبيق ──
class _AppBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'ص',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'صافي',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A148C),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── خلفية زخرفية بسيطة ──
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6A1B9A).withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 18, paint);
        canvas.drawCircle(Offset(x, y), 10, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
