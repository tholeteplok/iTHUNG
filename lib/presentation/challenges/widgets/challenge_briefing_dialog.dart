import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/challenge_score_record.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../game/providers/game_dependencies_provider.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../home/providers/player_profile_provider.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';

enum ChallengeType { blitz, marathon }

/// Modal dialog persiapan sebelum pemain memulai mode Speed Blitz atau Math Marathon.
class ChallengeBriefingDialog extends ConsumerWidget {
  const ChallengeBriefingDialog({
    super.key,
    required this.type,
  });

  final ChallengeType type;

  static Future<void> show(
    BuildContext context, {
    required ChallengeType type,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppTheme.colorEspresso.withValues(alpha: 0.6),
      builder: (_) => ChallengeBriefingDialog(type: type),
    );
  }

  String _getBandDisplayName(String id) {
    switch (id) {
      case 'onboarding':
        return 'Latihan Awal';
      case 'basic':
        return 'Hutan Rimba';
      case 'intermediate':
        return 'Lembah Batu';
      case 'advanced':
        return 'Puncak Salju';
      case 'expert':
        return 'Kawah Api';
      default:
        return 'Petualangan';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(playerProfileProvider).valueOrNull;
    final config = ref.watch(levelBandsConfigProvider).valueOrNull;
    final currentLevel = profile?.currentLevel ?? 1;
    final band = config?.bandForLevel(currentLevel);
    final bandId = band?.id ?? 'basic';

    final isBlitz = type == ChallengeType.blitz;
    final modeKey = isBlitz ? 'blitz' : 'marathon';

    final challengeRepo = ref.watch(challengeScoreRepositoryProvider);

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
              width: 80,
              height: 80,
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
                isBlitz
                    ? AppAssets.icChallengeLightning
                    : AppAssets.icChallengeCrown,
                width: 52,
                height: 52,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 14),

            // Judul Mode
            Text(
              isBlitz ? 'Speed Blitz' : 'Math Marathon',
              style: GoogleFonts.quicksand(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.colorEspresso,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Badge Zona / Level
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.colorWoodPlank,
                borderRadius: BorderRadius.circular(AppTokens.radiusMini),
                border: Border.all(
                  color: AppTheme.colorWoodMedium,
                  width: AppTokens.borderWidthSubtle,
                ),
              ),
              child: Text(
                'Zona: ${_getBandDisplayName(bandId)} (Lv. $currentLevel)',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorTaupe,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kotak Rekor Terbaik Pribadi
            FutureBuilder<RepoResult<ChallengeScoreRecord?>>(
              future: challengeRepo.getRecord(modeKey, bandId),
              builder: (context, snapshot) {
                ChallengeScoreRecord? record;
                if (snapshot.hasData && snapshot.data is RepoSuccess<ChallengeScoreRecord?>) {
                  record = (snapshot.data as RepoSuccess<ChallengeScoreRecord?>).value;
                }
                final bestScore = record?.bestScore ?? 0;
                final attempts = record?.attempts ?? 0;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.colorVanillaCard.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(AppTokens.radiusContainer),
                    border: Border.all(
                      color: AppTheme.colorWoodMedium.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Rekor Terbaik',
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.colorTaupe,
                            ),
                          ),
                          Text(
                            bestScore > 0 ? '$bestScore Poin' : 'Belum Ada',
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.colorEspresso,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: AppTheme.colorWoodMedium.withValues(alpha: 0.4),
                      ),
                      Column(
                        children: [
                          Text(
                            'Percobaan',
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.colorTaupe,
                            ),
                          ),
                          Text(
                            '$attempts kali',
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.colorEspresso,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Poin-poin Penjelasan Aturan
            if (isBlitz) ...[
              _buildRuleTile(
                icon: Icons.timer_rounded,
                title: 'Waktu Tunggal 60 Detik',
                description:
                    'Jawab soal sebanyak-banyaknya sebelum waktu habis.',
              ),
              const SizedBox(height: 8),
              _buildRuleTile(
                icon: Icons.bolt_rounded,
                title: 'Bebas Berpikir dalam 60s',
                description:
                    'Tidak ada batas waktu per soal. Jawab secepat dan sebanyak mungkin!',
              ),
              const SizedBox(height: 8),
              _buildRuleTile(
                icon: Icons.emoji_events_rounded,
                title: 'Tantang Rekor Terbaik',
                description:
                    'Poin peringkatmu bertambah setiap kali kamu berhasil melampaui skor terbaik sebelumnya.',
              ),
            ] else ...[
              _buildRuleTile(
                icon: Icons.warning_amber_rounded,
                title: 'Mode Sudden Death',
                description:
                    '1 jawaban salah atau kehabisan waktu langsung Game Over seketika!',
              ),
              const SizedBox(height: 8),
              _buildRuleTile(
                icon: Icons.local_fire_department_rounded,
                title: 'Rantai Streak Tak Hingga',
                description:
                    'Tingkat kesulitan soal bertambah seiring streak panjangmu.',
              ),
              const SizedBox(height: 8),
              _buildRuleTile(
                icon: Icons.military_tech_rounded,
                title: 'Bonus Konsistensi',
                description:
                    'Streak bonus bertahap hingga +40 poin tambahan per soal.',
              ),
            ],
            const SizedBox(height: 22),

            // Tombol Aksi
            Row(
              children: [
                Expanded(
                  child: ChunkyButton(
                    onPressed: () => Navigator.of(context).pop(),
                    backgroundColor: AppTheme.colorWoodPlank,
                    borderColor: AppTheme.colorWoodMedium,
                    shadowColor: AppTheme.colorWoodDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Kembali',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorEspresso,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ChunkyButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(
                        isBlitz ? '/challenges/blitz' : '/challenges/marathon',
                      );
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
                          'Mulai Tantangan',
                          style: GoogleFonts.quicksand(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  static Widget _buildRuleTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.colorWoodMedium.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppTheme.colorEspresso),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorEspresso,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorTaupe,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}