import '../models/daily_challenge.dart';
import '../models/leaderboard_entry.dart';
import '../models/public_profile.dart';
import 'repo_result.dart';

/// Kontrak repositori untuk papan peringkat (Leaderboard).
abstract class LeaderboardRepository {
  /// Mengambil daftar top-N entri papan peringkat untuk band dan tanggal tertentu.
  /// Menandai [currentPlayerUsername] dengan `isCurrentPlayer = true`.
  Future<RepoResult<List<LeaderboardEntry>>> fetchTopEntries({
    required String band,
    required DateTime date,
    int limit = 50,
    String? currentPlayerUsername,
  });

  /// Mengambil entri posisi pemain tertentu jika tidak masuk di top-N.
  Future<RepoResult<LeaderboardEntry?>> getPlayerEntry({
    required String band,
    required DateTime date,
    required String username,
  });

  /// Mengambil daftar top-N entri papan peringkat all-time (total skor akumulatif).
  Future<RepoResult<List<LeaderboardEntry>>> fetchAllTimeEntries({
    int limit = 50,
    String? currentPlayerUsername,
  });

  /// Mengunggah hasil tantangan harian pemain ke cloud papan peringkat.
  ///
  /// Daily bersifat kompetisi harian murni: tidak mengubah total skor.
  /// [totalScore] hanya dipakai untuk best-effort sinkronisasi profil agar
  /// all-time tidak tertinggal jauh (nilai lama tidak pernah menimpa baru).
  Future<RepoResult<void>> submitDailyResult({
    required DailyChallengeResult result,
    required String username,
    String? avatarId,
    int? totalScore,
    int? currentLevel,
    int? totalXp,
  });

  /// Mendorong total skor lokal terbaru ke /profiles agar all-time sinkron.
  /// Implementasi wajib memakai semantik max(): nilai lama tidak menimpa baru.
  Future<RepoResult<void>> syncProfileTotal({
    required String username,
    String? avatarId,
    required int totalScore,
  });

  /// Mendorong progres pemain lokal terbaru (skor, level, xp, dan rekor per level) ke /profiles/{uid} di cloud.
  /// Implementasi wajib memakai semantik max(): nilai lama tidak menimpa baru.
  Future<RepoResult<void>> syncProfileProgress({
    required String username,
    String? avatarId,
    required int totalScore,
    int? currentLevel,
    int? totalXp,
    Map<String, dynamic>? levelRecords,
    Map<String, dynamic>? challengeRecords,
  });

  /// Mengambil data dokumen profil pemain dari /profiles/{uid} di Firestore.
  /// Mengembalikan null jika profil belum pernah tersimpan di cloud.
  Future<RepoResult<Map<String, dynamic>?>> fetchCloudProfile(String uid);

  /// Mengambil data profil publik pemain berdasarkan [username] dari /profiles di Firestore.
  /// Mengembalikan null jika profil tidak ditemukan.
  Future<RepoResult<PublicProfile?>> fetchPublicProfile(String username);

  /// Mengambil daftar top-N entri papan peringkat tantangan khusus (speed blitz / math marathon)
  /// untuk mode dan band tertentu.
  Future<RepoResult<List<LeaderboardEntry>>> fetchChallengeLeaderboard({
    required String mode,
    required String band,
    int limit = 50,
    String? currentPlayerUsername,
  });

  /// Mengambil entri posisi pemain tertentu pada mode tantangan dan band jika tidak masuk di top-N.
  Future<RepoResult<LeaderboardEntry?>> getPlayerChallengeEntry({
    required String mode,
    required String band,
    required String username,
  });

  /// Mengunggah skor rekor tantangan baru ke papan peringkat cloud mode & band.
  Future<RepoResult<void>> submitChallengeScore({
    required String mode,
    required String band,
    required int score,
    int? correctCount,
    int? streak,
    required String username,
    String? avatarId,
  });
}
