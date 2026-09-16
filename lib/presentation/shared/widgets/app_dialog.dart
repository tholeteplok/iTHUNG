import 'package:flutter/material.dart';
import 'chunky_card.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.child, this.maxWidth = 360});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: ((scale - 0.9) / 0.1).clamp(0.0, 1.0),
              child: child,
            ),
          ),
          child: ChunkyCard(variant: ChunkyCardVariant.vanillaSoft, padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), child: child),
        ),
      ),
    );
  }
}