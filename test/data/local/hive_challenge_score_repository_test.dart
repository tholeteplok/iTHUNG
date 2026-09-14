import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mathmo_app/data/local/hive_challenge_score_repository.dart';
import 'package:mathmo_app/domain/models/challenge_score_record.dart';
import 'package:mathmo_app/domain/repositories/repo_result.dart';

void main() {
  late Directory tempDir;
  late Box<Map> challengeBox;
  late HiveChallengeScoreRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_challenge_test_');
    Hive.init(tempDir.path);
    challengeBox =
        await Hive.openBox<Map>(HiveChallengeScoreRepository.boxName);
    repository = HiveChallengeScoreRepository(challengeBox);
  });

  tearDown(() async {
    await challengeBox.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveChallengeScoreRepository', () {
    test('getRecord returns null when no record exists', () async {
      final res = await repository.getRecord('blitz', 'basic');
      expect(res, isA<RepoSuccess<ChallengeScoreRecord?>>());
      expect((res as RepoSuccess<ChallengeScoreRecord?>).value, isNull);
    });

    test('saveRecord and getRecord persist and retrieve data properly', () async {
      final record = ChallengeScoreRecord(
        mode: 'blitz',
        band: 'basic',
        bestScore: 350,
        attempts: 5,
        updatedAt: DateTime(2026, 9, 14, 10, 0, 0),
      );

      final saveRes = await repository.saveRecord(record);
      expect(saveRes, isA<RepoSuccess<void>>());

      final getRes = await repository.getRecord('blitz', 'basic');
      expect(getRes, isA<RepoSuccess<ChallengeScoreRecord?>>());
      final retrieved = (getRes as RepoSuccess<ChallengeScoreRecord?>).value;

      expect(retrieved, isNotNull);
      expect(retrieved!.mode, equals('blitz'));
      expect(retrieved.band, equals('basic'));
      expect(retrieved.bestScore, equals(350));
      expect(retrieved.attempts, equals(5));
    });

    test('getAllRecords returns map of all saved challenge records', () async {
      final recordBlitz = ChallengeScoreRecord(
        mode: 'blitz',
        band: 'basic',
        bestScore: 200,
        attempts: 2,
      );
      final recordMarathon = ChallengeScoreRecord(
        mode: 'marathon',
        band: 'intermediate',
        bestScore: 850,
        attempts: 4,
      );

      await repository.saveRecord(recordBlitz);
      await repository.saveRecord(recordMarathon);

      final allRes = await repository.getAllRecords();
      expect(allRes, isA<RepoSuccess<Map<String, ChallengeScoreRecord>>>());
      final allMap =
          (allRes as RepoSuccess<Map<String, ChallengeScoreRecord>>).value;

      expect(allMap.length, equals(2));
      expect(allMap.containsKey('blitz_basic'), isTrue);
      expect(allMap.containsKey('marathon_intermediate'), isTrue);
      expect(allMap['blitz_basic']!.bestScore, equals(200));
      expect(allMap['marathon_intermediate']!.bestScore, equals(850));
    });

    test('clearAll removes all entries from box', () async {
      await repository.saveRecord(
        ChallengeScoreRecord(mode: 'blitz', band: 'basic', bestScore: 100),
      );
      expect(challengeBox.isNotEmpty, isTrue);

      final clearRes = await repository.clearAll();
      expect(clearRes, isA<RepoSuccess<void>>());
      expect(challengeBox.isEmpty, isTrue);
    });
  });
}