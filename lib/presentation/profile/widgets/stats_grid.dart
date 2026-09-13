import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/profile_stats_aggregate.dart';
import '../../shared/widgets/chunky_card.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    required this.totalScore,
    required this.longestStreak,
    required this.stats,
  });

  final int totalScore;
  final int longestStreak;
  final ProfileStatsAggregate stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: AppIcons.star,
                iconColor: const Color(0xFFD48B00),
                label: 'Skor Total',
                value: '$totalScore',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: AppIcons.timer,
                iconColor: const Color(0xFF2C6D9E),
                label: 'Akurasi',
                value: stats.formattedAccuracy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: AppIcons.levelCompleted,
                iconColor: AppTheme.colorSage,
                label: 'Fakta Dikuasai',
                value: '${stats.factsMastered}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: AppIcons.streakFlame,
                iconColor: const Color(0xFFD9531E),
                label: 'Streak Terbaik',
                value: '$longestStreak Hari',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ChunkyCard(
      variant: ChunkyCardVariant.woodBoard,
      borderRadius: AppTokens.radiusCard,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTheme.statNumberStyle(
              fontSize: 22,
              color: AppTheme.colorEspresso,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.colorTaupe,
            ),
          ),
        ],
      ),
    );
  }
}
