import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';

/// Widget Podium 3 Besar bergaya "Cozy Woodwork Step Pedestal".
///
/// Menampilkan:
/// - Kiri: Peringkat #2 (Perak, balok sedang)
/// - Tengah: Peringkat #1 (Emas, mahkota, avatar terbesar, balok tertinggi)
/// - Kanan: Peringkat #3 (Perunggu, balok terendah)
class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({
    super.key,
    required this.entries,
    required this.mode,
    required this.onPlayerTap,
  });

  /// Daftar entri peringkat (minimal 1, idealnya 3).
  final List<LeaderboardEntry> entries;
  final LeaderboardMode mode;
  final ValueChanged<LeaderboardEntry> onPlayerTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final rank1 = entries.first;
    final rank2 = entries.length > 1 ? entries[1] : null;
    final rank3 = entries.length > 2 ? entries[2] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Rank 2 (Perak - Kiri)
          Expanded(
            flex: 10,
            child: rank2 != null
                ? _PodiumColumn(
                    entry: rank2,
                    mode: mode,
                    pedestalHeight: 74,
                    avatarSize: 52,
                    rankOrdinal: 2,
                    rankColor: const Color(0xFF5A5A5A),
                    rankBgColor: const Color(0xFFE0E0E0),
                    pedestalColor: AppTheme.colorPodiumSilver,
                    onTap: () => onPlayerTap(rank2),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),

          // Rank 1 (Emas - Tengah)
          Expanded(
            flex: 11,
            child: _PodiumColumn(
              entry: rank1,
              mode: mode,
              pedestalHeight: 106,
              avatarSize: 62,
              rankOrdinal: 1,
              hasCrown: true,
              rankColor: const Color(0xFF8C5F00),
              rankBgColor: const Color(0xFFFFD54F),
              pedestalColor: AppTheme.colorPodiumGold,
              onTap: () => onPlayerTap(rank1),
            ),
          ),
          const SizedBox(width: 8),

          // Rank 3 (Perunggu - Kanan)
          Expanded(
            flex: 10,
            child: rank3 != null
                ? _PodiumColumn(
                    entry: rank3,
                    mode: mode,
                    pedestalHeight: 56,
                    avatarSize: 52,
                    rankOrdinal: 3,
                    rankColor: const Color(0xFF6D3C14),
                    rankBgColor: const Color(0xFFFFCCBC),
                    pedestalColor: AppTheme.colorPodiumBronze,
                    onTap: () => onPlayerTap(rank3),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.mode,
    required this.pedestalHeight,
    required this.avatarSize,
    required this.rankOrdinal,
    required this.rankColor,
    required this.rankBgColor,
    required this.pedestalColor,
    required this.onTap,
    this.hasCrown = false,
  });

  final LeaderboardEntry entry;
  final LeaderboardMode mode;
  final double pedestalHeight;
  final double avatarSize;
  final int rankOrdinal;
  final Color rankColor;
  final Color rankBgColor;
  final Color pedestalColor;
  final VoidCallback onTap;
  final bool hasCrown;

  @override
  Widget build(BuildContext context) {
    final scoreLabel = mode == LeaderboardMode.allTime
        ? '${entry.totalScore ?? 0} pts'
        : '${entry.correctCount}/12';
    final scoreColor = mode == LeaderboardMode.allTime
        ? AppTheme.colorCoral
        : AppTheme.colorSage;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mahkota di atas avatar (khusus #1)
          if (hasCrown)
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              child: const Icon(
                AppIcons.crown,
                size: 26,
                color: Color(0xFFF6C443),
              ),
            )
          else
            const SizedBox(height: 18),

          // Avatar Bulat dengan Badge Peringkat
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.colorWoodPlank,
                  border: Border.all(
                    color: AppTheme.colorWoodMedium,
                    width: AppTokens.borderWidthWood,
                  ),
                  boxShadow: ChunkyShadow.wood(AppTheme.colorWoodDark),
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
                          style: TextStyle(
                            fontSize: avatarSize * 0.44,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.colorEspresso,
                          ),
                        ),
                      ),
              ),
              // Badge Peringkat di sudut kanan bawah
              Positioned(
                bottom: -3,
                right: -3,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rankBgColor,
                    border: Border.all(
                      color: AppTheme.colorWoodMedium,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$rankOrdinal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: rankColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Username & Chip "Kamu" (jika pemain aktif)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (entry.isCurrentPlayer) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
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
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    '@${entry.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          entry.isCurrentPlayer ? FontWeight.w900 : FontWeight.w800,
                      color: AppTheme.colorEspresso,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Skor Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              border: Border.all(
                color: scoreColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Text(
              scoreLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: scoreColor,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Balok Pilar Kayu Bertingkat Pastel (Woodwork Step Pedestal)
          Container(
            height: pedestalHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: pedestalColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border.all(
                color: AppTheme.colorWoodMedium,
                width: AppTokens.borderWidthWood,
              ),
              boxShadow: ChunkyShadow.wood(AppTheme.colorWoodDark),
            ),
            child: Center(
              child: Text(
                '$rankOrdinal',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.colorWoodMedium.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
