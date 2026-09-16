import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Badge berbentuk pil untuk menampilkan statistik ringkas (mis. streak api, skor XP).
///
/// Tersentralisasi untuk header di GameScreen, HomeScreen, dan ResultsScreen.
class BadgePill extends StatelessWidget {
  const BadgePill({
    super.key,
    required this.icon,
    required this.value,
    required this.iconColor,
    this.backgroundColor = AppTheme.colorVanillaCard,
    this.borderColor = AppTheme.colorTranslucentBorder,
    this.hasShadow = true,
    this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool hasShadow;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(
          color: borderColor,
          width: AppTokens.borderWidthSubtle,
        ),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: AppTheme.colorWoodDark.withValues(alpha: 0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTheme.statNumberStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.colorEspresso,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.colorEspresso,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      pill = GestureDetector(onTap: onTap, child: pill);
    }

    return pill;
  }
}
