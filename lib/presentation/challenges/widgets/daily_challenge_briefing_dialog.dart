import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/daily_challenge.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';

/// Modal dialog persiapan sebelum pemain memulai Tantangan Harian.
///
/// Menyajikan *briefing* strategis:
/// - Format soal (12 soal aritmatika kilat)
/// - Penilaian & waktu (kecepatan respon + akurasi)
/// - Satu kesempatan resmi harian untuk papan peringkat global
///
/// Memberikan kontrol penuh kepada pengguna agar tidak masuk ke gameplay
/// secara mendadak.
class DailyChallengeBriefingDialog extends ConsumerWidget {
  const DailyChallengeBriefingDialog({
    super.key,
    required this.completionResult,
  });

  /// Hasil pengerjaan harian jika pengguna sudah pernah menyelesaikan hari ini.
  final DailyChallengeResult? completionResult;

  /// Helper untuk memunculkan dialog persiapan.
  static Future<void> show(
    BuildContext context, {
    DailyChallengeResult? completionResult,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppTheme.colorEspresso.withValues(alpha: 0.6),
      builder: (_) => DailyChallengeBriefingDialog(
        completionResult: completionResult,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAlreadyCompleted = completionResult != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ChunkyCard(
        variant: ChunkyCardVariant.woodBoard,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Representasi Visual 3D
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.colorWoodPlank,
                border: Border.all(
                  color: AppTheme.colorWoodMedium,
                  width: AppTokens.borderWidthWood,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.colorWoodDark.withValues(alpha: 0.25),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Image.asset(
                isAlreadyCompleted
                    ? AppAssets.icChallengeCrown
                    : AppAssets.icChallengeTrophy,
                width: 58,
                height: 58,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),

            // Judul Dialog
            Text(
              isAlreadyCompleted
                  ? 'Tantangan Telah Selesai!'
                  : 'Tantangan Harian',
              style: GoogleFonts.quicksand(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.colorEspresso,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Subtitle Deskripsi
            Text(
              isAlreadyCompleted
                  ? 'Kamu sudah mencatatkan rekor hari ini. Tunggu giliran reset tengah malam untuk tantangan baru!'
                  : 'Uji ketajaman mentalmu dengan 12 soal aritmatika cepat. Bersiaplah sebelum menekan tombol mulai!',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.colorTaupe,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // Card Detail Aturan / Rekor Hasil
            if (isAlreadyCompleted)
              _buildResultSummary(completionResult!)
            else
              _buildRulesSummary(),

            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                // Tombol Batal / Tutup
                Expanded(
                  child: ChunkyButton(
                    onPressed: () => Navigator.of(context).pop(),
                    backgroundColor: AppTheme.colorWoodPlank,
                    borderColor: AppTheme.colorWoodMedium,
                    shadowColor: AppTheme.colorWoodDark,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Text(
                      isAlreadyCompleted ? 'Tutup' : 'Nanti Saja',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorEspresso,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol Mulai / Lihat Peringkat
                Expanded(
                  child: ChunkyButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (isAlreadyCompleted) {
                        context.go('/leaderboard');
                      } else {
                        // Masuk ke gameplay Tantangan Harian
                        context.push('/daily/play');
                      }
                    },
                    backgroundColor: isAlreadyCompleted
                        ? AppTheme.colorCoral
                        : AppTheme.colorSage,
                    borderColor: isAlreadyCompleted
                        ? AppTheme.colorWoodBorder
                        : AppTheme.colorWoodDark,
                    shadowColor: AppTheme.colorWoodDark,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Text(
                      isAlreadyCompleted ? 'Peringkat' : 'Mulai Sekarang!',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Menampilkan aturan main untuk pemain yang belum menyelesaikan tantangan.
  Widget _buildRulesSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.colorWoodPlank,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(
          color: AppTheme.colorWoodMedium,
          width: AppTokens.borderWidthDefault,
        ),
      ),
      child: Column(
        children: [
          _buildRuleRow(
            assetIcon: AppAssets.icChallengeSpeed,
            title: '12 Soal Kilat',
            subtitle: 'Waktu per soal berjalan cepat',
          ),
          const Divider(
            color: AppTheme.colorWoodMedium,
            thickness: 1,
            height: 16,
          ),
          _buildRuleRow(
            assetIcon: AppAssets.icChallengeTrophy,
            title: '1x Kesempatan Resmi',
            subtitle: 'Skor masuk Papan Peringkat Global',
          ),
          const Divider(
            color: AppTheme.colorWoodMedium,
            thickness: 1,
            height: 16,
          ),
          _buildRuleRow(
            assetIcon: AppAssets.icChallengeStar,
            title: 'Papan Peringkat Global',
            subtitle: 'Buktikan kemampuanmu di puncak kohor band',
          ),
        ],
      ),
    );
  }

  /// Menampilkan rangkuman hasil untuk pemain yang sudah menyelesaikan tantangan.
  Widget _buildResultSummary(DailyChallengeResult result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.colorWoodPlank,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(
          color: AppTheme.colorWoodMedium,
          width: AppTokens.borderWidthDefault,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            label: 'Jawaban Benar',
            value: '${result.correctCount} / 12',
            iconPath: AppAssets.icChallengeStar,
          ),
          Container(
            height: 38,
            width: 2,
            color: AppTheme.colorWoodMedium,
          ),
          _buildStatColumn(
            label: 'Total Waktu',
            value: '${(result.totalTimeMs / 1000).toStringAsFixed(1)}d',
            iconPath: AppAssets.icChallengeSpeed,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleRow({
    required String assetIcon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Image.asset(
          assetIcon,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorEspresso,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorTaupe,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required String iconPath,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: AppTheme.statNumberStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.colorEspresso,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.colorTaupe,
          ),
        ),
      ],
    );
  }
}