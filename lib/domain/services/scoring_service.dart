import 'dart:math';

import '../models/challenge_score_record.dart';
import '../models/level_score_record.dart';
import '../models/round_result.dart';
import '../models/session_result.dart';

/// Service untuk perhitungan skor ronde dan XP akun.
///
/// Mengacu pada `math-speed-game-core-gameplay-spec.md` §7:
/// - Round score: mengukur efisiensi dan fluency instan (base + speed + mastery + streak)
/// - Session XP: mengukur progres akun jangka panjang, terpisah dari kecepatan
class ScoringService {
  const ScoringService();

  /// Menghitung skor dan rincian poin untuk satu ronde yang baru selesai.
  ///
  /// [level]: level pemain saat ronde dimainkan.
  /// [timeLeftMs]: sisa waktu saat tombol ditekan (0 jika timeout/salah).
  /// [timeTotalMs]: total alokasi waktu untuk ronde tersebut.
  /// [streakCorrect]: jumlah jawaban benar beruntun sebelum/termasuk ronde ini.
  /// [factBox]: kotak Leitner fakta saat ini (1-5). Jika <= 2, mendapat bonus mastery.
  /// [isCorrect]: apakah jawaban benar. Jika salah, total score = 0.
  ({int roundScore, ScoreBreakdown breakdown}) computeRoundScore({
    required int level,
    required int timeLeftMs,
    required int timeTotalMs,
    required int streakCorrect,
    required bool isCorrect,
    int? factBox,
  }) {
    if (!isCorrect) {
      return (
        roundScore: 0,
        breakdown: const ScoreBreakdown(
          basePoints: 0,
          speedBonus: 0,
          masteryBonus: 0,
          streakBonus: 0,
        ),
      );
    }

    // Skala Base Points berbasis Level Band (Opsi A - Proporsional Tingkat Kesulitan):
    // - Onboarding (Level 1–5): Base 10 (1.0x)
    // - Basic (Level 6–15): Base 20 (2.0x)
    // - Intermediate (Level 16–30): Base 40 (4.0x)
    // - Advanced (Level 31–50): Base 70 (7.0x)
    // - Expert (Level 51+): Base 100 (10.0x)
    final int basePoints = basePointsForLevel(level);

    // speed_bonus = round(base_points * 0.3 * (time_left / time_total))
    final timeRatio = timeTotalMs > 0
        ? (timeLeftMs / timeTotalMs).clamp(0.0, 1.0)
        : 0.0;
    final speedBonus = (basePoints * 0.3 * timeRatio).round();

    // mastery_bonus = fact.box <= 2 ? 8 : 0 (insentif melatih fakta yang masih lemah)
    final masteryBonus = (factBox != null && factBox <= 2) ? 8 : 0;

    // streak_bonus = round(base_points * min(streak_correct * 0.05, 0.5))
    // Maksimal 50% dari basePoints (proporsional per band, tidak flat lagi!)
    final streakRatio = (min(streakCorrect, 10) / 10.0) * 0.5;
    final streakBonus = (basePoints * streakRatio).round();

    final total = basePoints + speedBonus + masteryBonus + streakBonus;

    final breakdown = ScoreBreakdown(
      basePoints: basePoints,
      speedBonus: speedBonus,
      masteryBonus: masteryBonus,
      streakBonus: streakBonus,
    );

    return (roundScore: total, breakdown: breakdown);
  }

  /// Menghitung XP akun yang didapat dari satu sesi permainan.
  ///
  /// Mengacu pada §7.2: XP TIDAK menghitung kecepatan agar pemain tidak terdorong
  /// grinding fakta mudah secara terburu-buru.
  ///
  /// Formula: (distinct_facts * 2) + (facts_moved_up * 5) + (session_completed ? 10 : 0)
  ({int totalXp, XpBreakdown breakdown}) computeSessionXp({
    required int distinctFactsPracticed,
    required int factsMovedUpABox,
    required bool sessionCompleted,
  }) {
    final breakdown = XpBreakdown(
      distinctFactsPracticed: distinctFactsPracticed,
      factsMovedUpABox: factsMovedUpABox,
      sessionCompletedBonus: sessionCompleted ? 10 : 0,
    );

    final total =
        (distinctFactsPracticed * 2) +
        (factsMovedUpABox * 5) +
        (sessionCompleted ? 10 : 0);

    return (totalXp: total, breakdown: breakdown);
  }

  /// Menghitung delta skor untuk penyelesaian/pengulangan sebuah level (node).
  ///
  /// Berbeda dari [computeRoundScore] (per-soal) — ini beroperasi di level
  /// SessionResult.totalScore vs rekor terbaik level tersebut.
  ({int scoreDelta, LevelScoreRecord updatedRecord}) computeLevelReplayDelta({
    required LevelScoreRecord currentRecord,
    required int newSessionScore,
    double? accuracy,
  }) {
    final earnedStars = accuracy != null ? calculateStars(accuracy) : null;
    final result = currentRecord.applyAttempt(
      newSessionScore,
      earnedStars: earnedStars,
    );
    return (scoreDelta: result.delta, updatedRecord: result.record);
  }

  /// Menghitung jumlah bintang berdasarkan akurasi (0.0 .. 1.0) — Opsi A:
  /// - Akurasi >= 90% (0.90): 3 Bintang (★★★)
  /// - Akurasi >= 70% (0.70): 2 Bintang (★★☆)
  /// - Akurasi >= 50% (0.50): 1 Bintang (★☆☆) — syarat minimal lolos level
  /// - Akurasi < 50%: 0 Bintang (☆☆☆) — gagal
  static int calculateStars(double accuracy) {
    if (accuracy >= 0.9) {
      return 3;
    } else if (accuracy >= 0.7) {
      return 2;
    } else if (accuracy >= 0.5) {
      return 1;
    } else {
      return 0;
    }
  }

  /// Menghitung base points diskret proporsional terhadap level band:
  /// - Onboarding (Level 1–5): Base 10 (1.0x)
  /// - Basic (Level 6–15): Base 20 (2.0x)
  /// - Intermediate (Level 16–30): Base 40 (4.0x)
  /// - Advanced (Level 31–50): Base 70 (7.0x)
  /// - Expert (Level 51+): Base 100 (10.0x)
  static int basePointsForLevel(int level) {
    if (level <= 5) {
      return 10;
    } else if (level <= 15) {
      return 20;
    } else if (level <= 30) {
      return 40;
    } else if (level <= 50) {
      return 70;
    } else {
      return 100;
    }
  }

  /// Pengali tingkat kesulitan relatif terhadap base level 1 (10 poin).
  static double levelMultiplier(int level) => basePointsForLevel(level) / 10.0;

  /// Menghitung skor mode Speed Blitz (jawaban benar terbanyak dalam 60 detik).
  ///
  /// Tanpa bonus kecepatan individual karena throughput jawaban dalam 60 detik
  /// sudah menjadi reward kecepatan secara alami.
  int computeBlitzScore(List<bool> answerResults, int currentLevel) {
    final basePoints = basePointsForLevel(currentLevel);
    final correctCount = answerResults.where((r) => r).length;
    return correctCount * basePoints;
  }

  /// Menghitung skor mode Math Marathon (rantai jawaban benar sampai salah/timeout).
  ///
  /// Memberikan streak bonus bertahap (maksimum 40 poin bonus per soal)
  /// untuk mengapresiasi ketahanan dan fokus mental.
  int computeMarathonScore(int correctStreakLength, int currentLevel) {
    final basePoints = basePointsForLevel(currentLevel);
    var total = 0;
    for (var position = 1; position <= correctStreakLength; position++) {
      final streakBonus = (position * 2).clamp(0, 40);
      total += basePoints + streakBonus;
    }
    return total;
  }

  /// Menghitung kontribusi delta skor ke total_score all-time saat rekor pribadi pecah.
  ///
  /// Mencegah grinding abuse di zona rendah dengan memadukan delta murni
  /// dengan pengali zona (zoneConstant).
  int computeChallengeReplayDelta({
    required ChallengeScoreRecord currentRecord,
    required int newChallengeScore,
    required double zoneConstant,
  }) {
    final result = currentRecord.applyAttempt(newChallengeScore);
    return (result.delta * 0.10 * zoneConstant).round();
  }
}
