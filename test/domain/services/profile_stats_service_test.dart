import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/mastery_record.dart';
import 'package:mathmo_app/domain/models/session_result.dart';
import 'package:mathmo_app/domain/services/profile_stats_service.dart';

void main() {
  const service = ProfileStatsService();

  group('ProfileStatsService', () {
    test('returns 0.0 accuracy and 0 mastered facts when empty', () {
      final aggregate = service.computeAggregate(
        recentSessions: [],
        masteryBank: {},
      );

      expect(aggregate.averageAccuracy, equals(0.0));
      expect(aggregate.factsMastered, equals(0));
    });

    test('calculates average accuracy from multiple sessions', () {
      final s1 = SessionResult(
        sessionId: 's1',
        mode: GameMode.normal,
        startedAt: DateTime.utc(2026, 9, 1),
        endedAt: DateTime.utc(2026, 9, 1, 0, 5),
        levelReached: 3,
        rounds: [],
        totalScore: 100,
        accuracy: 0.8,
        avgResponseTimeMs: 1200,
        bestStreak: 5,
        xpEarned: 20,
        xpBreakdown: XpBreakdown.zero,
      );

      final s2 = SessionResult(
        sessionId: 's2',
        mode: GameMode.normal,
        startedAt: DateTime.utc(2026, 9, 2),
        endedAt: DateTime.utc(2026, 9, 2, 0, 5),
        levelReached: 4,
        rounds: [],
        totalScore: 150,
        accuracy: 1.0,
        avgResponseTimeMs: 900,
        bestStreak: 10,
        xpEarned: 30,
        xpBreakdown: XpBreakdown.zero,
      );

      final aggregate = service.computeAggregate(
        recentSessions: [s1, s2],
        masteryBank: {},
      );

      expect(aggregate.averageAccuracy, closeTo(0.9, 0.001));
      expect(aggregate.factsMastered, equals(0));
    });

    test('counts only facts with Leitner box == 5 as mastered', () {
      final rec1 = MasteryRecord(
        factKey: '7x8',
        attempts: 10,
        correct: 10,
        recentResults: List.filled(8, true),
        avgResponseTimeMs: 800,
        masteryScore: 1.0,
        box: 5,
        lastSeenAt: DateTime.utc(2026, 9, 1),
        errorTypeCounts: {},
      );

      final rec2 = MasteryRecord(
        factKey: '6x9',
        attempts: 5,
        correct: 4,
        recentResults: [true, true, true, false, true],
        avgResponseTimeMs: 1400,
        masteryScore: 0.7,
        box: 4,
        lastSeenAt: DateTime.utc(2026, 9, 1),
        errorTypeCounts: {},
      );

      final rec3 = MasteryRecord(
        factKey: '12-5',
        attempts: 12,
        correct: 12,
        recentResults: List.filled(8, true),
        avgResponseTimeMs: 700,
        masteryScore: 1.0,
        box: 5,
        lastSeenAt: DateTime.utc(2026, 9, 2),
        errorTypeCounts: {},
      );

      final aggregate = service.computeAggregate(
        recentSessions: [],
        masteryBank: {
          '7x8': rec1,
          '6x9': rec2,
          '12-5': rec3,
        },
      );

      expect(aggregate.factsMastered, equals(2));
      expect(aggregate.averageAccuracy, equals(0.0));
    });
  });
}
