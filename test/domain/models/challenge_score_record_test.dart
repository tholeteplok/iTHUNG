import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/challenge_score_record.dart';

void main() {
  group('ChallengeScoreRecord', () {
    test('default constructor sets default values', () {
      final record = ChallengeScoreRecord(mode: 'blitz', band: 'basic');
      expect(record.mode, equals('blitz'));
      expect(record.band, equals('basic'));
      expect(record.bestScore, equals(0));
      expect(record.attempts, equals(0));
      expect(record.updatedAt, isNull);
    });

    test('applyAttempt updates bestScore and returns positive delta when score broken', () {
      final record = ChallengeScoreRecord(
        mode: 'blitz',
        band: 'basic',
        bestScore: 200,
        attempts: 3,
      );

      final result = record.applyAttempt(350);

      expect(result.delta, equals(150));
      expect(result.record.bestScore, equals(350));
      expect(result.record.attempts, equals(4));
      expect(result.record.updatedAt, isNotNull);
    });

    test('applyAttempt does NOT update bestScore and returns 0 delta when score is lower or equal', () {
      final record = ChallengeScoreRecord(
        mode: 'marathon',
        band: 'intermediate',
        bestScore: 500,
        attempts: 2,
      );

      // Skor lebih rendah
      final result1 = record.applyAttempt(420);
      expect(result1.delta, equals(0));
      expect(result1.record.bestScore, equals(500));
      expect(result1.record.attempts, equals(3));

      // Skor sama persis
      final result2 = record.applyAttempt(500);
      expect(result2.delta, equals(0));
      expect(result2.record.bestScore, equals(500));
      expect(result2.record.attempts, equals(3));
    });

    test('toJson and fromJson serialize and deserialize correctly', () {
      final now = DateTime.now();
      final record = ChallengeScoreRecord(
        mode: 'marathon',
        band: 'advanced',
        bestScore: 1200,
        attempts: 8,
        updatedAt: now,
      );

      final json = record.toJson();
      expect(json['mode'], equals('marathon'));
      expect(json['band'], equals('advanced'));
      expect(json['best_score'], equals(1200));
      expect(json['attempts'], equals(8));
      expect(json['updated_at'], equals(now.toIso8601String()));

      final reconstructed = ChallengeScoreRecord.fromJson(json);
      expect(reconstructed.mode, equals(record.mode));
      expect(reconstructed.band, equals(record.band));
      expect(reconstructed.bestScore, equals(record.bestScore));
      expect(reconstructed.attempts, equals(record.attempts));
      expect(
        reconstructed.updatedAt?.toIso8601String(),
        equals(now.toIso8601String()),
      );
    });
  });
}