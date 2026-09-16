import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/level_score_record.dart';
import 'package:mathmo_app/domain/services/scoring_service.dart';

void main() {
  const scoringService = ScoringService();

  group('ScoringService.computeRoundScore', () {
    test('returns 0 score when answer is wrong', () {
      final result = scoringService.computeRoundScore(
        level: 1,
        timeLeftMs: 3000,
        timeTotalMs: 4000,
        streakCorrect: 5,
        isCorrect: false,
      );

      expect(result.roundScore, equals(0));
      expect(result.breakdown.total, equals(0));
    });

    test(
      'calculates correct base points, speed bonus, streak bonus for correct answer',
      () {
        // Level 1: base = 10
        // timeLeft = 2000 / 4000 = 0.5 ratio
        // speed_bonus = round(10 * 0.3 * 0.5) = round(1.5) = 2
        // streak = 3 -> streakRatio = (3 / 10.0) * 0.5 = 0.15 -> streakBonus = round(10 * 0.15) = 2
        // masteryBonus = 0 (no factBox)
        // total = 10 + 2 + 0 + 2 = 14
        final result = scoringService.computeRoundScore(
          level: 1,
          timeLeftMs: 2000,
          timeTotalMs: 4000,
          streakCorrect: 3,
          isCorrect: true,
        );

        expect(result.breakdown.basePoints, equals(10));
        expect(result.breakdown.speedBonus, equals(2));
        expect(result.breakdown.streakBonus, equals(2));
        expect(result.breakdown.masteryBonus, equals(0));
        expect(result.roundScore, equals(14));
      },
    );

    test('awards mastery bonus of 8 points when factBox <= 2', () {
      final result = scoringService.computeRoundScore(
        level: 5,
        timeLeftMs: 1000,
        timeTotalMs: 4000,
        streakCorrect: 0,
        isCorrect: true,
        factBox: 2,
      );

      expect(result.breakdown.masteryBonus, equals(8));
      expect(result.roundScore, greaterThan(8));
    });

    test('scales base points and caps streak bonus at 50% across bands', () {
      // Level 1 (Onboarding): base = 10 -> max streak = 5
      final onbResult = scoringService.computeRoundScore(
        level: 1,
        timeLeftMs: 0,
        timeTotalMs: 4000,
        streakCorrect: 15,
        isCorrect: true,
      );
      expect(onbResult.breakdown.basePoints, equals(10));
      expect(onbResult.breakdown.streakBonus, equals(5));

      // Level 10 (Basic): base = 20 -> max streak = 10
      final basicResult = scoringService.computeRoundScore(
        level: 10,
        timeLeftMs: 0,
        timeTotalMs: 4000,
        streakCorrect: 15,
        isCorrect: true,
      );
      expect(basicResult.breakdown.basePoints, equals(20));
      expect(basicResult.breakdown.streakBonus, equals(10));

      // Level 20 (Intermediate): base = 40 -> max streak = 20
      final interResult = scoringService.computeRoundScore(
        level: 20,
        timeLeftMs: 0,
        timeTotalMs: 4000,
        streakCorrect: 15,
        isCorrect: true,
      );
      expect(interResult.breakdown.basePoints, equals(40));
      expect(interResult.breakdown.streakBonus, equals(20));

      // Level 40 (Advanced): base = 70 -> max streak = 35
      final advResult = scoringService.computeRoundScore(
        level: 40,
        timeLeftMs: 0,
        timeTotalMs: 4000,
        streakCorrect: 15,
        isCorrect: true,
      );
      expect(advResult.breakdown.basePoints, equals(70));
      expect(advResult.breakdown.streakBonus, equals(35));

      // Level 55 (Expert): base = 100 -> max streak = 50
      final expResult = scoringService.computeRoundScore(
        level: 55,
        timeLeftMs: 0,
        timeTotalMs: 4000,
        streakCorrect: 15,
        isCorrect: true,
      );
      expect(expResult.breakdown.basePoints, equals(100));
      expect(expResult.breakdown.streakBonus, equals(50));

      // Level 80 (Master): base = 140 -> max streak = 70
      final mstResult = scoringService.computeRoundScore(
        level: 80,
        timeLeftMs: 0,
        timeTotalMs: 4000,
        streakCorrect: 15,
        isCorrect: true,
      );
      expect(mstResult.breakdown.basePoints, equals(140));
      expect(mstResult.breakdown.streakBonus, equals(70));
    });
  });

  group('ScoringService.computeSessionXp', () {
    test('computes XP independent of speed', () {
      // (4 distinct * 2) + (2 moved up * 5) + (completed ? 10 : 0)
      // = 8 + 10 + 10 = 28
      final result = scoringService.computeSessionXp(
        distinctFactsPracticed: 4,
        factsMovedUpABox: 2,
        sessionCompleted: true,
      );

      expect(result.totalXp, equals(28));
      expect(result.breakdown.distinctFactsPracticed, equals(4));
      expect(result.breakdown.factsMovedUpABox, equals(2));
      expect(result.breakdown.sessionCompletedBonus, equals(10));
    });

    test('omits sessionCompleted bonus if session was abandoned', () {
      final result = scoringService.computeSessionXp(
        distinctFactsPracticed: 3,
        factsMovedUpABox: 1,
        sessionCompleted: false,
      );

      // (3 * 2) + (1 * 5) + 0 = 11
      expect(result.totalXp, equals(11));
      expect(result.breakdown.sessionCompletedBonus, equals(0));
    });
  });

  group('ScoringService.computeLevelReplayDelta', () {
    test('computes positive delta when new score beats record and updates stars', () {
      final initial = LevelScoreRecord.initial(1);
      final (:scoreDelta, :updatedRecord) =
          scoringService.computeLevelReplayDelta(
        currentRecord: initial,
        newSessionScore: 200,
        accuracy: 0.95,
      );

      expect(scoreDelta, equals(200));
      expect(updatedRecord.bestScore, equals(200));
      expect(updatedRecord.attempts, equals(1));
      expect(updatedRecord.stars, equals(3));
    });

    test('computes zero delta when new score is less than record', () {
      const existing = LevelScoreRecord(
        level: 1,
        bestScore: 200,
        attempts: 1,
        stars: 3,
      );

      final (:scoreDelta, :updatedRecord) =
          scoringService.computeLevelReplayDelta(
        currentRecord: existing,
        newSessionScore: 150,
        accuracy: 0.75, // 2 stars, but existing is 3 stars -> stays 3
      );

      expect(scoreDelta, equals(0));
      expect(updatedRecord.bestScore, equals(200));
      expect(updatedRecord.attempts, equals(2));
      expect(updatedRecord.stars, equals(3));
    });

    test('computes incremental delta when new score exceeds previous best', () {
      const existing = LevelScoreRecord(
        level: 2,
        bestScore: 120,
        attempts: 2,
        stars: 1,
      );

      final (:scoreDelta, :updatedRecord) =
          scoringService.computeLevelReplayDelta(
        currentRecord: existing,
        newSessionScore: 180,
        accuracy: 0.8, // 2 stars -> upgrades from 1 to 2
      );

      expect(scoreDelta, equals(60));
      expect(updatedRecord.bestScore, equals(180));
      expect(updatedRecord.attempts, equals(3));
      expect(updatedRecord.stars, equals(2));
    });
  });

  group('ScoringService.calculateStars', () {
    test('maps accuracy thresholds correctly to 3, 2, 1, 0 stars', () {
      expect(ScoringService.calculateStars(1.0), equals(3));
      expect(ScoringService.calculateStars(0.90), equals(3));
      expect(ScoringService.calculateStars(0.89), equals(2));
      expect(ScoringService.calculateStars(0.70), equals(2));
      expect(ScoringService.calculateStars(0.69), equals(1));
      expect(ScoringService.calculateStars(0.50), equals(1));
      expect(ScoringService.calculateStars(0.49), equals(0));
      expect(ScoringService.calculateStars(0.20), equals(0));
      expect(ScoringService.calculateStars(0.0), equals(0));
    });
  });
}
