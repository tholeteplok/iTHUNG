import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../home/providers/player_profile_provider.dart';
import '../../shared/widgets/app_header.dart';
import '../providers/account_status_provider.dart';
import '../providers/profile_stats_provider.dart';
import 'create_account_cta.dart';
import 'level_progress_card.dart';
import 'profile_header.dart';
import 'stats_grid.dart';

/// Layar profil pemain (ProfileScreen - /profile).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileProvider);
    final accountState = ref.watch(accountStatusProvider).valueOrNull ??
        const AccountState(status: AccountStatus.guest);
    final statsAsync = ref.watch(profileStatsProvider);

    final profile = profileAsync.valueOrNull;
    final currentLevel = profile?.currentLevel ?? 1;
    final totalXp = profile?.totalXp ?? 0;
    final totalScore = profile?.totalScore ?? 0;
    final longestStreak = profile?.streak.longestStreak ?? 0;
    final bandsConfig = ref.watch(levelBandsConfigProvider).valueOrNull;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.colorSandyCanvas,
        body: SafeArea(
        child: Column(
          children: [
            // Top Bar tersentralisasi
            AppHeader(
              title: 'Profil Petualang',
              showStats: false,
              onBackTap: () => context.go('/'),
            ),

            // Konten Profil
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // 1. Header Profil & Avatar
                  ProfileHeader(
                    accountState: accountState,
                    currentLevel: currentLevel,
                  ),
                  const SizedBox(height: 20),

                  // 2. Kartu Zona & Progres Level
                  if (bandsConfig != null)
                    LevelProgressCard(
                      currentLevel: currentLevel,
                      totalXp: totalXp,
                      band: bandsConfig.bandForLevel(currentLevel),
                    ),
                  const SizedBox(height: 16),

                  // 3. Grid Statistik 2x2
                  statsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppTheme.colorWoodMedium),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text('Gagal memuat statistik: $err'),
                    ),
                    data: (stats) => StatsGrid(
                      totalScore: totalScore,
                      longestStreak: longestStreak,
                      stats: stats,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. CTA Akun
                  CreateAccountCta(accountState: accountState),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
