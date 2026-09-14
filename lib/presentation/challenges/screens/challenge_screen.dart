import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/challenge_score_record.dart';
import '../../../domain/models/daily_challenge.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../daily_challenge/providers/daily_challenge_provider.dart';
import '../../game/providers/game_dependencies_provider.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../home/providers/player_profile_provider.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import '../widgets/challenge_briefing_dialog.dart';
import '../widgets/daily_challenge_briefing_dialog.dart';

/// Layar Hub Pusat Tantangan (ChallengeScreen).
///
/// Menyajikan akses ke berbagai mode tantangan dengan latar belakang pedesaan
/// `highPass_canvas.png` dan gaya Cozy Warm Woodwork.
///
/// Fitur Utama:
/// - Kartu Tantangan Harian (Daily Challenge)
/// - Kartu Speed Blitz (60 Detik Sprint)
/// - Kartu Math Marathon (Sudden Death Survival)
class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  Timer? _countdownTimer;
  late Duration _timeUntilMidnight;

  @override
  void initState() {
    super.initState();
    _calculateTimeUntilMidnight();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _calculateTimeUntilMidnight();
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _calculateTimeUntilMidnight() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _timeUntilMidnight = nextMidnight.difference(now);
  }

  String _formatRemainingTime() {
    final hours = _timeUntilMidnight.inHours;
    final minutes = _timeUntilMidnight.inMinutes % 60;
    return '${hours}j ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final completionAsync = ref.watch(dailyChallengeCompletionProvider);
    final profile = ref.watch(playerProfileProvider).valueOrNull;
    final config = ref.watch(levelBandsConfigProvider).valueOrNull;
    final currentLevel = profile?.currentLevel ?? 1;
    final bandId = config?.bandForLevel(currentLevel).id ?? 'basic';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.colorSandyCanvas,
        body: Stack(
          children: [
            // Latar Belakang Scenic highPass_canvas
            Positioned.fill(
              child: Image.asset(
                AppAssets.highPassCanvasBackground,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // Warm Cozy Scrim
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.colorSandyCanvas.withValues(alpha: 0.15),
                      AppTheme.colorSandyCanvas.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),

            // Konten Utama
            SafeArea(
              child: Column(
                children: [
                  // Top App Header sentral
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: AppHeader(
                      title: 'Pusat Tantangan',
                      showStats: false,
                      onBackTap: () => context.go('/'),
                    ),
                  ),

                  // Daftar Kartu Tantangan
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      children: [
                        // Subheader Tantangan Harian
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Text(
                            'TANTANGAN HARIAN',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppTheme.colorTaupe,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Kartu Utama: Tantangan Harian
                        completionAsync.when(
                          loading: () => const _LoadingChallengeCard(),
                          error: (_, _) => _buildDailyCard(context, null),
                          data: (result) => _buildDailyCard(context, result),
                        ),
                        const SizedBox(height: 24),

                        // Subheader Tantangan Spesial
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Text(
                            'TANTANGAN SPESIAL',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppTheme.colorTaupe,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Kartu Mode: Speed Blitz
                        _buildSpecialChallengeCard(
                          context: context,
                          type: ChallengeType.blitz,
                          title: 'Speed Blitz',
                          subtitle:
                              'Pacu kecepatan aritmatika kilat 60 detik tanpa henti!',
                          badgeText: '60 DETIK',
                          badgeColor: AppTheme.colorCoral,
                          iconAsset: AppAssets.icChallengeLightning,
                          bandId: bandId,
                        ),
                        const SizedBox(height: 14),

                        // Kartu Mode: Math Marathon
                        _buildSpecialChallengeCard(
                          context: context,
                          type: ChallengeType.marathon,
                          title: 'Math Marathon',
                          subtitle:
                              'Mode sudden death survival sampai kamu melakukan 1 kesalahan!',
                          badgeText: 'SURVIVAL',
                          badgeColor: AppTheme.colorSage,
                          iconAsset: AppAssets.icChallengeCrown,
                          bandId: bandId,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu Utama Tantangan Harian dengan varian WoodBoard.
  Widget _buildDailyCard(
    BuildContext context,
    DailyChallengeResult? completionResult,
  ) {
    final isDone = completionResult != null;

    return GestureDetector(
      onTap: () {
        DailyChallengeBriefingDialog.show(
          context,
          completionResult: completionResult,
        );
      },
      child: ChunkyCard(
        variant: ChunkyCardVariant.woodBoard,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Badge Atas & Countdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.colorSage.withValues(alpha: 0.15)
                        : AppTheme.colorCoral.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMini),
                    border: Border.all(
                      color: isDone ? AppTheme.colorSage : AppTheme.colorCoral,
                      width: AppTokens.borderWidthSubtle,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.star_rounded,
                        size: 14,
                        color: isDone
                            ? AppTheme.colorSage
                            : AppTheme.colorCoral,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isDone ? 'SELESAI HARI INI' : 'SPESIAL HARIAN',
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDone
                            ? AppTheme.colorSage
                            : AppTheme.colorCoral,
                        ),
                      ),
                    ],
                  ),
                ),

                // Reset Countdown
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppTheme.colorTaupe,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Reset: ${_formatRemainingTime()}',
                      style: AppTheme.statNumberStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorTaupe,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Konten Ikon 3D dan Judul
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.colorWoodPlank,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.colorWoodMedium,
                      width: AppTokens.borderWidthWood,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.colorWoodDark.withValues(alpha: 0.2),
                        offset: const Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    isDone
                        ? AppAssets.icChallengeCrown
                        : AppAssets.icChallengeTrophy,
                    width: 42,
                    height: 42,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tantangan Harian',
                        style: GoogleFonts.quicksand(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.colorEspresso,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isDone
                            ? 'Skor: ${completionResult.correctCount}/12 Benar (${(completionResult.totalTimeMs / 1000).toStringAsFixed(1)}d)'
                            : '12 Soal Aritmatika Kilat. Taklukkan papan peringkat global!',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.colorTaupe,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Button Terintegrasi
            ChunkyButton(
              onPressed: () {
                DailyChallengeBriefingDialog.show(
                  context,
                  completionResult: completionResult,
                );
              },
              backgroundColor: isDone
                  ? AppTheme.colorWoodPlank
                  : AppTheme.colorSage,
              borderColor: isDone
                  ? AppTheme.colorWoodMedium
                  : AppTheme.colorWoodDark,
              shadowColor: AppTheme.colorWoodDark,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isDone) ...[
                    Image.asset(
                      AppAssets.icChallengePlay,
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isDone ? 'Lihat Pencapaian' : 'Buka Tantangan',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDone ? AppTheme.colorEspresso : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu Tantangan Spesial (Speed Blitz & Math Marathon).
  Widget _buildSpecialChallengeCard({
    required BuildContext context,
    required ChallengeType type,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required String iconAsset,
    required String bandId,
  }) {
    final isBlitz = type == ChallengeType.blitz;
    final modeKey = isBlitz ? 'blitz' : 'marathon';
    final challengeRepo = ref.watch(challengeScoreRepositoryProvider);

    return ChunkyCard(
      variant: ChunkyCardVariant.woodBoard,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Badge Atas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMini),
                  border: Border.all(
                    color: badgeColor,
                    width: AppTokens.borderWidthSubtle,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.quicksand(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: badgeColor,
                  ),
                ),
              ),

              // Rekor Score Display
              FutureBuilder<RepoResult<ChallengeScoreRecord?>>(
                future: challengeRepo.getRecord(modeKey, bandId),
                builder: (context, snapshot) {
                  ChallengeScoreRecord? record;
                  if (snapshot.hasData &&
                      snapshot.data is RepoSuccess<ChallengeScoreRecord?>) {
                    record =
                        (snapshot.data as RepoSuccess<ChallengeScoreRecord?>)
                            .value;
                  }
                  final best = record?.bestScore ?? 0;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 14,
                        color: AppTheme.colorTaupe,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        best > 0 ? 'Rekor: $best Pts' : 'Belum Ada Rekor',
                        style: AppTheme.statNumberStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.colorTaupe,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Konten Ikon 3D dan Judul
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.colorWoodPlank,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.colorWoodMedium,
                    width: AppTokens.borderWidthWood,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.colorWoodDark.withValues(alpha: 0.2),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  iconAsset,
                  width: 38,
                  height: 38,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.colorEspresso,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.colorTaupe,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Button
          ChunkyButton(
            onPressed: () {
              ChallengeBriefingDialog.show(context, type: type);
            },
            backgroundColor:
                isBlitz ? AppTheme.colorCoral : AppTheme.colorSage,
            borderColor: AppTheme.colorWoodDark,
            shadowColor: AppTheme.colorWoodDark,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  isBlitz ? 'Mainkan Speed Blitz' : 'Mulai Math Marathon',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu Loading Placeholder
class _LoadingChallengeCard extends StatelessWidget {
  const _LoadingChallengeCard();

  @override
  Widget build(BuildContext context) {
    return const ChunkyCard(
      variant: ChunkyCardVariant.woodBoard,
      padding: EdgeInsets.all(28),
      child: Center(
        child: CircularProgressIndicator(color: AppTheme.colorWoodMedium),
      ),
    );
  }
}