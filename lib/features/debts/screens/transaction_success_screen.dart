import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/debts_ui_provider.dart';
import '../utils/debt_transaction_share.dart';
import '../widgets/debt_transaction_receipt_card.dart';

/// شاشة النجاح — تظهر بعد تسجيل دين جديد أو سداد وتختفي تلقائيًا بعد 4 ثواني
class TransactionSuccessScreen extends StatefulWidget {
  const TransactionSuccessScreen({
    super.key,
    required this.customerName,
    required this.amount,
    required this.type,
    required this.date,
    this.counterpartyLabel = 'الزبون',
  });

  final String customerName;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String counterpartyLabel;

  /// انتقال بنمط تأكيد بنكي: تلاشي + انزلاق من الأسفح
  static Route<bool> route({
    required String customerName,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String counterpartyLabel = 'الزبون',
  }) {
    return PageRouteBuilder<bool>(
      pageBuilder: (context, animation, secondaryAnimation) => TransactionSuccessScreen(
        customerName: customerName,
        amount: amount,
        type: type,
        date: date,
        counterpartyLabel: counterpartyLabel,
      ),
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.11),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<TransactionSuccessScreen> createState() =>
      _TransactionSuccessScreenState();
}

class _TransactionSuccessScreenState extends State<TransactionSuccessScreen>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  int _secondsLeft = 4;

  late AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..forward();
    HapticFeedback.mediumImpact();
    _startCountdown();
  }

  Animation<double> _interval(double begin, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _stagger(double begin, double end, Widget child) {
    final anim = _interval(begin, end);
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.075),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
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
    _countdownTimer?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGave = widget.type == TransactionType.gave;
    final accentColor = isGave ? const Color(0xFFE53935) : const Color(0xFF43A047);
    final bgColor = isGave ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    _stagger(
                      0.0,
                      0.36,
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
                    ),
                    const SizedBox(height: 16),

                    _stagger(
                      0.13,
                      0.46,
                      Column(
                        children: [
                          const Text(
                            'تمت العملية بنجاح',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _stagger(
                          0.30,
                          0.76,
                          DebtTransactionReceiptCard(
                            customerName: widget.customerName,
                            amount: widget.amount,
                            type: widget.type,
                            date: widget.date,
                            counterpartyLabel: widget.counterpartyLabel,
                          ),
                        ),
                      ),
                    ),

                    _stagger(
                      0.60,
                      1.0,
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await shareDebtTransactionReceipt(
                                  context: context,
                                  customerName: widget.customerName,
                                  amount: widget.amount,
                                  type: widget.type,
                                  date: widget.date,
                                  counterpartyLabel: widget.counterpartyLabel,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
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
                                    style: TextStyle(
                                      fontFamily: AppFonts.family,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                              child: Text(
                                'إنهاء',
                                style: TextStyle(
                                  fontFamily: AppFonts.family,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
