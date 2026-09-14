import '../models/challenge_score_record.dart';
import 'repo_result.dart';

/// Kontrak repositori untuk penyimpanan rekor skor mode tantangan (Speed Blitz, Math Marathon).
abstract interface class ChallengeScoreRepository {
  /// Mengambil rekor skor untuk [mode] dan [band] tertentu.
  Future<RepoResult<ChallengeScoreRecord?>> getRecord(String mode, String band);

  /// Menyimpan atau memperbarui rekor skor untuk mode dan band tertentu.
  Future<RepoResult<void>> saveRecord(ChallengeScoreRecord record);

  /// Mengambil seluruh rekor skor tantangan pemain yang tersimpan secara lokal.
  Future<RepoResult<Map<String, ChallengeScoreRecord>>> getAllRecords();

  /// Menghapus seluruh rekor skor tantangan (mis. saat reset data atau testing).
  Future<RepoResult<void>> clearAll();
}
