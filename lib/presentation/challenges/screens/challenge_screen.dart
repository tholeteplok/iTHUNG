import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/daily_challenge.dart';
import '../../daily_challenge/providers/daily_challenge_provider.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import '../widgets/daily_challenge_briefing_dialog.dart';

/// Layar Hub Pusat Tantangan (ChallengeScreen).
///
/// Menyajikan akses ke berbagai mode tantangan dengan latar belakang pedesaan
/// `highPass_canvas.png` dan gaya Cozy Warm Woodwork.
///
/// Fitur Utama:
/// - Kartu Tantangan Harian (Daily Challenge) dengan briefing readiness modal
/// - Countdown reset tengah malam
/// - Teaser mode tantangan mendatang (Speed Blitz & Math Marathon)
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

            // Warm Cozy Scrim tipis agar kanvas pedesaan terlihat jelas dan estetik
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
                      // Subheader Deskripsi Singkat
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Text(
                          'PILIH TANTANGAN',
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
                      const SizedBox(height: 20),

                      // Subheader Mode Mendatang
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Text(
                          'TANTANGAN MENDATANG',
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppTheme.colorTaupe,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Kartu Teaser: Speed Blitz
                      const _LockedChallengeCard(
                        title: 'Speed Blitz',
                        subtitle:
                            'Tantangan kecepatan kilat 60 detik tanpa henti.',
                        badgeText: 'Segera Hadir',
                        iconAsset: AppAssets.icChallengeLightning,
                      ),
                      const SizedBox(height: 12),

                      // Kartu Teaser: Math Marathon
                      const _LockedChallengeCard(
                        title: 'Math Marathon',
                        subtitle:
                            'Rantai soal tak hingga sampai kamu melakukan 1 kesalahan.',
                        badgeText: 'Segera Hadir',
                        iconAsset: AppAssets.icChallengeCrown,
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

/// Kartu Teaser untuk tantangan yang masih terkunci.
class _LockedChallengeCard extends StatelessWidget {
  const _LockedChallengeCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.iconAsset,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colorWoodPlank.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: AppTheme.colorWoodMedium.withValues(alpha: 0.6),
          width: AppTokens.borderWidthDefault,
        ),
      ),
      child: Row(
        children: [
          // Ikon mode dengan filter transparan lembut
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.colorWoodPlank.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.colorWoodMedium.withValues(alpha: 0.6),
                width: AppTokens.borderWidthDefault,
              ),
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: 0.65,
              child: Image.asset(
                iconAsset,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Detail Teks & Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorEspresso,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.colorWoodMedium.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusMini,
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.quicksand(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.colorTaupe,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.quicksand(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colorTaupe,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),

          // Gembok status terkunci
          const Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: AppTheme.colorTaupe,
          ),
        ],
      ),
    );
  }
}