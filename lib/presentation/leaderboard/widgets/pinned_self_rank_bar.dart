import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';

/// Bilah footer yang menempel (*sticky*) di bawah layar leaderboard
/// untuk menampilkan posisi ranking pemain login jika berada di luar daftar Top 50.
class PinnedSelfRankBar extends StatelessWidget {
  const PinnedSelfRankBar({
    super.key,
    required this.entry,
    required this.mode,
    required this.onTap,
  });

  final LeaderboardEntry entry;
  final LeaderboardMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scoreLabel = mode == LeaderboardMode.allTime
        ? '${entry.totalScore ?? 0} pts'
        : '${entry.correctCount}/12';
    final scoreColor = mode == LeaderboardMode.allTime
        ? AppTheme.colorCoral
        : AppTheme.colorSage;

    final subInfo = mode == LeaderboardMode.allTime
        ? 'Peringkat All-Time Kamu'
        : 'Waktu: ${entry.formattedTime}';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.colorWoodPlank,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(
                color: AppTheme.colorWoodMedium,
                width: AppTokens.borderWidthWood,
              ),
              boxShadow: ChunkyShadow.wood(AppTheme.colorWoodDark),
            ),
            child: Row(
              children: [
                // Rank Badge Lingkaran
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.colorSandyCanvas,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.colorWoodMedium,
                      width: AppTokens.borderWidthSubtle,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.rank}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppTheme.colorWoodDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Avatar Bulat
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.colorSandyCanvas,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.colorWoodMedium,
                      width: AppTokens.borderWidthSubtle,
                    ),
                  ),
                  child: AppAssets.avatarPath(entry.avatarId) != null
                      ? ClipOval(
                          child: Image.asset(
                            AppAssets.avatarPath(entry.avatarId)!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            entry.username.isNotEmpty
                                ? entry.username[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: AppTheme.colorEspresso,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),

                // Username & Label Kamu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '@${entry.username}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.colorEspresso,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.colorWoodDark,
                              borderRadius:
                                  BorderRadius.circular(AppTokens.radiusPill),
                            ),
                            child: const Text(
                              'Kamu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subInfo,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.colorTaupe,
                        ),
                      ),
                    ],
                  ),
                ),

                // Skor Utama
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    border: Border.all(
                      color: scoreColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    scoreLabel,
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
