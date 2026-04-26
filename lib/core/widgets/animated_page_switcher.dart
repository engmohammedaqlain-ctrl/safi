import 'package:flutter/material.dart';

class AnimatedPageSwitcher extends StatelessWidget {
  const AnimatedPageSwitcher({
    super.key,
    required this.pageKey,
    required this.child,
  });

  final Object pageKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // AnimatedSwitcher → Stack داخلياً؛ بدون ارتفاع مُحصى يسبب
    // «BoxConstraints forces an infinite height» لـ ListView / Column+Expanded
    return LayoutBuilder(
      builder: (context, constraints) {
        final mq = MediaQuery.sizeOf(context);
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mq.width;
        final h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mq.height;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (widget, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: slide,
                child: widget,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(pageKey),
            child: SizedBox(
              width: w,
              height: h,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
