import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/public_profile.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/avatar_frame.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import '../providers/public_profile_provider.dart';

/// Layar profil pemain lain (View-Only).
///
/// Diakses via deep link atau navigasi tap dari leaderboard:
/// `/profile/:username`
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(username));

    return Scaffold(
      backgroundColor: AppTheme.colorSandyCanvas,
      appBar: AppHeader(
        showStats: false,
        onBackTap: () => context.pop(),
        title: '@$username',
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppTheme.colorWoodMedium,
            ),
          ),
          error: (err, _) => _buildErrorView(context, ref, err.toString()),
          data: (result) => switch (result) {
            RepoSuccess(:final value) => value != null
                ? _buildProfileContent(context, value)
                : _buildNotFoundView(context),
            RepoFailure(:final reason) =>
              _buildErrorView(context, ref, reason),
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, PublicProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // Avatar Frame Besar
          AvatarFrame(
            size: 96,
            borderRadius: AppTokens.radiusAvatar,
            avatarAsset: AppAssets.avatarPath(profile.avatarId),
            initialLetter: profile.username.isNotEmpty
                ? profile.username[0].toUpperCase()
                : 'P',
          ),
          const SizedBox(height: 14),

          // Username
          Text(
            '@${profile.username}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.colorEspresso,
            ),
          ),
          const SizedBox(height: 8),

          // Badge Band Petualang (Read-Only)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.colorWoodPlank,
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              border: Border.all(
                color: AppTheme.colorWoodMedium,
                width: AppTokens.borderWidthWood,
              ),
              boxShadow: ChunkyShadow.wood(AppTheme.colorWoodDark),
            ),
            child: Text(
              profile.bandTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.colorWoodDark,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4 Kartu Statistik Publik
          _buildStatGrid(profile),
        ],
      ),
    );
  }

  Widget _buildStatGrid(PublicProfile profile) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PublicStatCard(
                icon: AppIcons.star,
                iconColor: const Color(0xFFD48B00),
                label: 'Skor Total',
                value: '${profile.totalScore}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PublicStatCard(
                icon: AppIcons.levelCompleted,
                iconColor: AppTheme.colorSage,
                label: 'Level Selesai',
                value: 'Level ${profile.currentLevel}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PublicStatCard(
                icon: AppIcons.xp,
                iconColor: const Color(0xFF2C6D9E),
                label: 'Total XP',
                value: '${profile.totalXp}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PublicStatCard(
                icon: AppIcons.streakFlame,
                iconColor: const Color(0xFFD9531E),
                label: 'Streak Terbaik',
                value: '${profile.longestStreak} Hari',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotFoundView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ChunkyCard(
          variant: ChunkyCardVariant.woodBoard,
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                AppIcons.profile,
                size: 48,
                color: AppTheme.colorTaupe,
              ),
              const SizedBox(height: 14),
              const Text(
                'Pemain Tidak Ditemukan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorEspresso,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Profil "@$username" belum terdaftar atau telah berganti username.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.colorTaupe,
                ),
              ),
              const SizedBox(height: 20),
              ChunkyButton(
                onPressed: () => context.pop(),
                backgroundColor: AppTheme.colorWoodPlank,
                child: const Text(
                  'Kembali',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.colorWoodDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ChunkyCard(
          variant: ChunkyCardVariant.woodBoard,
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                AppIcons.warning,
                size: 48,
                color: AppTheme.colorCoral,
              ),
              const SizedBox(height: 14),
              const Text(
                'Gagal Memuat Profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorEspresso,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.colorTaupe,
                ),
              ),
              const SizedBox(height: 20),
              ChunkyButton(
                onPressed: () => ref.invalidate(publicProfileProvider(username)),
                backgroundColor: AppTheme.colorWoodPlank,
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.colorWoodDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicStatCard extends StatelessWidget {
  const _PublicStatCard({
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTheme.statNumberStyle(
              fontSize: 20,
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
