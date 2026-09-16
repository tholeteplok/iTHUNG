import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/level_band_config.dart';
import '../../shared/widgets/chunky_card.dart';

/// Kartu progres profil berbasis zona (band), bukan per level.
///
/// Menampilkan nama zona saat ini, rentang level zona, dan bar progres
/// "level selesai di zona / total level zona". Untuk zona tanpa batas
/// (expert) memakai fallback progres XP ke level berikut.
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({
    super.key,
    required this.currentLevel,
    required this.totalXp,
    required this.band,
  });

  final int currentLevel;
  final int totalXp;
  final LevelBand band;

  @override
  Widget build(BuildContext context) {
    final zoneFraction = band.progressFraction(currentLevel);
    final double progressFraction;
    final String progressLabel;
    final String rangeText;

    if (zoneFraction != null) {
      final completed = band.levelsCompleted(currentLevel);
      final total = band.levelsTotal ?? completed;
      progressFraction = zoneFraction;
      progressLabel = '$completed / $total level selesai di zona ini';
      rangeText = 'Level $currentLevel · ${band.rangeLabel}';
    } else {
      // Zona puncak tanpa batas: fallback progres XP 100/level.
      final xpRequiredForCurrent = (currentLevel - 1) * 100;
      final progressXp = (totalXp - xpRequiredForCurrent).clamp(0, 100);
      progressFraction = (progressXp / 100.0).clamp(0.0, 1.0);
      progressLabel = '$progressXp / 100 XP ke Level ${currentLevel + 1}';
      rangeText = 'Level $currentLevel · Zona puncak tanpa batas';
    }

    return ChunkyCard(
      variant: ChunkyCardVariant.vanillaSoft,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.levelCompleted,
                      size: 20,
                      color: AppTheme.colorSage,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        band.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.colorEspresso,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total $totalXp XP',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppTheme.colorTaupe,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rangeText,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.colorTaupe,
            ),
          ),
          const SizedBox(height: 12),

          // Progress Bar
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.colorSandyCanvas,
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              border: Border.all(
                color: AppTheme.darkBorder,
                width: AppTokens.borderWidthSubtle,
              ),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progressFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.colorSage,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  progressLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.colorTaupe,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progressFraction * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorWoodDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
