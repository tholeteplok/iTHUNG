import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/leaderboard_entry.dart';

void main() {
  group('LeaderboardEntry', () {
    test('formats time correctly', () {
      const entry = LeaderboardEntry(
        rank: 1,
        username: 'champion_99',
        correctCount: 10,
        totalTimeMs: 24500,
        isCurrentPlayer: true,
      );

      expect(entry.formattedTime, equals('24.5s'));
      expect(entry.rank, equals(1));
      expect(entry.username, equals('champion_99'));
      expect(entry.isCurrentPlayer, isTrue);
    });

    test('toJson and fromJson serialize properly', () {
      const entry = LeaderboardEntry(
        rank: 2,
        username: 'speedster',
        correctCount: 9,
        totalTimeMs: 18200,
        isCurrentPlayer: false,
      );

      final json = entry.toJson();
      expect(json['rank'], equals(2));
      expect(json['username'], equals('speedster'));
      expect(json['correct_count'], equals(9));
      expect(json['total_time_ms'], equals(18200));
      expect(json['is_current_player'], isFalse);

      final from = LeaderboardEntry.fromJson(json);
      expect(from, equals(entry));
    });

    test('supports totalScore in all-time mode', () {
      const entry = LeaderboardEntry(
        rank: 1,
        username: 'master',
        correctCount: 0,
        totalTimeMs: 0,
        isCurrentPlayer: true,
        totalScore: 4500,
      );

      final json = entry.toJson();
      expect(json['total_score'], equals(4500));

      final from = LeaderboardEntry.fromJson(json);
      expect(from.totalScore, equals(4500));
      expect(from, equals(entry));
    });

    test('supports streak for marathon mode', () {
      const entry = LeaderboardEntry(
        rank: 1,
        username: 'runner',
        correctCount: 0,
        totalTimeMs: 0,
        isCurrentPlayer: true,
        totalScore: 3200,
        streak: 42,
      );

      final json = entry.toJson();
      expect(json['streak'], equals(42));

      final from = LeaderboardEntry.fromJson(json);
      expect(from.streak, equals(42));
      expect(from, equals(entry));

      final updated = entry.copyWith(streak: 50);
      expect(updated.streak, equals(50));
      expect(updated.rank, equals(1));
    });
  });
}

