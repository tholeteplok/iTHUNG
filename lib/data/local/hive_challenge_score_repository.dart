import 'package:hive_ce/hive.dart';

import '../../domain/models/challenge_score_record.dart';
import '../../domain/repositories/challenge_score_repository.dart';
import '../../domain/repositories/repo_result.dart';

/// Implementasi [ChallengeScoreRepository] menggunakan Hive CE.
class HiveChallengeScoreRepository implements ChallengeScoreRepository {
  HiveChallengeScoreRepository([Box<Map>? box]) : _box = box;

  static const String boxName = 'challenge_scores';
  Box<Map>? _box;

  Future<Box<Map>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<Map>(boxName);
    return _box!;
  }

  @override
  Future<RepoResult<ChallengeScoreRecord?>> getRecord(
    String mode,
    String band,
  ) async {
    try {
      final box = await _getBox();
      final key = '${mode}_$band';
      final raw = box.get(key);
      if (raw == null) return const RepoSuccess(null);
      return RepoSuccess(
        ChallengeScoreRecord.fromJson(Map<String, dynamic>.from(raw)),
      );
    } catch (e) {
      return RepoFailure('Gagal memuat rekor challenge $mode ($band)', e);
    }
  }

  @override
  Future<RepoResult<void>> saveRecord(ChallengeScoreRecord record) async {
    try {
      final box = await _getBox();
      final key = '${record.mode}_${record.band}';
      await box.put(key, record.toJson());
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal menyimpan rekor challenge ${record.mode}', e);
    }
  }

  @override
  Future<RepoResult<Map<String, ChallengeScoreRecord>>> getAllRecords() async {
    try {
      final box = await _getBox();
      final map = <String, ChallengeScoreRecord>{};
      for (final entry in box.toMap().entries) {
        final record = ChallengeScoreRecord.fromJson(
          Map<String, dynamic>.from(entry.value),
        );
        map[entry.key.toString()] = record;
      }
      return RepoSuccess(map);
    } catch (e) {
      return RepoFailure('Gagal memuat seluruh rekor tantangan', e);
    }
  }

  @override
  Future<RepoResult<void>> clearAll() async {
    try {
      final box = await _getBox();
      await box.clear();
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure('Gagal mengosongkan rekor tantangan', e);
    }
  }
}
