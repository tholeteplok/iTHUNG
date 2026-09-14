import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/core/config/zone_constants.dart';
import 'package:mathmo_app/domain/models/challenge_score_record.dart';
import 'package:mathmo_app/domain/services/scoring_service.dart';

void main() {
  const scoringService = ScoringService();

  group('ScoringService.computeBlitzScore', () {
    test('computes blitz score accurately based on correct answers and level base points', () {
      // Level 1: base = 10
      final answersLvl1 = [true, true, false, true, false, true]; // 4 benar
      expect(scoringService.computeBlitzScore(answersLvl1, 1), equals(40));

      // Level 15: base = 20
      final answersLvl15 = [true, true, true]; // 3 benar
      expect(scoringService.computeBlitzScore(answersLvl15, 15), equals(60));

      // Level 25: base = 40
      final answersLvl25 = [true, false, true]; // 2 benar
      expect(scoringService.computeBlitzScore(answersLvl25, 25), equals(80));

      // Level 35: base = 70
      final answersLvl35 = [true, false, true]; // 2 benar
      expect(scoringService.computeBlitzScore(answersLvl35, 35), equals(140));

      // 0 correct -> 0 score
      final answersZero = [false, false, false];
      expect(scoringService.computeBlitzScore(answersZero, 50), equals(0));
    });
  });

  group('ScoringService.computeMarathonScore', () {
    test('computes marathon score with progressive streak bonus clamped at 40', () {
      // Streak 0 -> 0 score
      expect(scoringService.computeMarathonScore(0, 1), equals(0));

      // Streak 1 at Level 1: base (10) + streak (2) = 12
      expect(scoringService.computeMarathonScore(1, 1), equals(12));

      // Streak 3 at Level 1:
      // pos 1: 10 + 2 = 12
      // pos 2: 10 + 4 = 14
      // pos 3: 10 + 6 = 16
      // Total = 12 + 14 + 16 = 42
      expect(scoringService.computeMarathonScore(3, 1), equals(42));

      // Streak 25 at Level 1:
      // Untuk pos 1..20: streakBonus = pos * 2
      // Untuk pos 21..25: streakBonus diclamp pada 40
      final score25 = scoringService.computeMarathonScore(25, 1);
      expect(score25, greaterThan(25 * 10)); // Pastikan jauh di atas base points murni
    });
  });

  group('ScoringService.computeChallengeReplayDelta', () {
    test('calculates weighted replay delta accurately with zone multiplier', () {
      final record = ChallengeScoreRecord(
        mode: 'blitz',
        band: 'basic',
        bestScore: 200,
        attempts: 1,
      );

      // New score: 300 -> delta murni = 100
      // Basic zone constant = 1.2
      // Formula: (100 * 0.10 * 1.2).round() = 12
      final deltaBasic = scoringService.computeChallengeReplayDelta(
        currentRecord: record,
        newChallengeScore: 300,
        zoneConstant: kZoneConstants['basic']!,
      );
      expect(deltaBasic, equals(12));

      // Expert zone constant = 2.8
      // Formula: (100 * 0.10 * 2.8).round() = 28
      final deltaExpert = scoringService.computeChallengeReplayDelta(
        currentRecord: record,
        newChallengeScore: 300,
        zoneConstant: kZoneConstants['expert']!,
      );
      expect(deltaExpert, equals(28));

      // Onboarding zone constant = 1.0
      // Formula: (100 * 0.10 * 1.0).round() = 10
      final deltaOnboarding = scoringService.computeChallengeReplayDelta(
        currentRecord: record,
        newChallengeScore: 300,
        zoneConstant: kZoneConstants['onboarding']!,
      );
      expect(deltaOnboarding, equals(10));
    });

    test('returns 0 delta when score does not break previous record', () {
      final record = ChallengeScoreRecord(
        mode: 'marathon',
        band: 'basic',
        bestScore: 500,
        attempts: 2,
      );

      final deltaLower = scoringService.computeChallengeReplayDelta(
        currentRecord: record,
        newChallengeScore: 450,
        zoneConstant: 1.2,
      );
      expect(deltaLower, equals(0));

      final deltaEqual = scoringService.computeChallengeReplayDelta(
        currentRecord: record,
        newChallengeScore: 500,
        zoneConstant: 1.2,
      );
      expect(deltaEqual, equals(0));
    });
  });
}