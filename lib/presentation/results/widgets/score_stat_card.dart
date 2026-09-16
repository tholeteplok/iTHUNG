import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/chunky_card.dart';

/// Kartu statistik kecil di ResultsScreen (Akurasi, Rata-rata Waktu, Streak).
class ScoreStatCard extends StatelessWidget {
  const ScoreStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor = AppTheme.darkBorder,
  });

  final String title;
  final String value;
  final IconData? icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ChunkyCard(
      variant: ChunkyCardVariant.vanillaSoft,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 6),
          ],
          Text(
            value,
            style: AppTheme.statNumberStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.colorEspresso,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.colorTaupe,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
