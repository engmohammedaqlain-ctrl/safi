import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// طبقة تحميل خفيفة فوق [child] بدون حوارات — تمنع النقر أثناء العملية.
class LightLoadingOverlay extends StatelessWidget {
  const LightLoadingOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.semanticLabel,
  });

  final bool visible;
  final Widget child;

  /// وصف لقارئ الشاشة أثناء الإظهار
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: IgnorePointer(
              ignoring: !visible,
              child: Semantics(
                label: visible ? (semanticLabel ?? 'جاري التحميل') : null,
                child: Material(
                  color: Colors.black.withValues(alpha: visible ? 0.08 : 0),
                  child: Center(
                    child: visible
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.88, end: 1),
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            builder: (context, scale, _) {
                              return Transform.scale(
                                scale: scale,
                                child: const _SoftSpinner(),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SoftSpinner extends StatelessWidget {
  const _SoftSpinner();

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          AppColors.primary.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}
