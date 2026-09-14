import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/firebase_error_mapper.dart';
import '../../domain/models/daily_challenge.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/models/public_profile.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../domain/repositories/repo_result.dart';

/// Implementasi [LeaderboardRepository] menggunakan Cloud Firestore.
class FirebaseLeaderboardRepository implements LeaderboardRepository {
  FirebaseLeaderboardRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore,
        _auth = auth;

  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;
  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;

  static const String collectionName = 'daily_challenge_results';
  static const String profilesCollection = 'profiles';

  static String _formatDateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<RepoResult<List<LeaderboardEntry>>> fetchTopEntries({
    required String band,
    required DateTime date,
    int limit = 50,
    String? currentPlayerUsername,
  }) async {
    try {
      final dateKey = _formatDateKey(date);

      // Query server-side dengan orderBy + limit (menggunakan composite index).
      // Disertai fallback jika indeks komposit sedang dibangun atau terjadi issue query server.
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await firestore
            .collection(collectionName)
            .where('band', isEqualTo: band)
            .where('date', isEqualTo: dateKey)
            .orderBy('correct_count', descending: true)
            .limit(limit)
            .get()
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Fallback: ambil dokumen berdasarkan band & date tanpa orderBy server,
        // lalu urutkan sepenuhnya di memori.
        snapshot = await firestore
            .collection(collectionName)
            .where('band', isEqualTo: band)
            .where('date', isEqualTo: dateKey)
            .limit(limit)
            .get()
            .timeout(const Duration(seconds: 10));
      }

      // Parsing dan sorting di memori (correct_count desc, total_time_ms asc)
      final sortedDocs = snapshot.docs.map((doc) => doc.data()).toList()
        ..sort((a, b) {
          final cA = ((a['correct_count'] ?? 0) as num).toInt();
          final cB = ((b['correct_count'] ?? 0) as num).toInt();
          final comp = cB.compareTo(cA);
          if (comp != 0) return comp;
          final tA = ((a['total_time_ms'] ?? 0) as num).toInt();
          final tB = ((b['total_time_ms'] ?? 0) as num).toInt();
          return tA.compareTo(tB);
        });

      final entries = <LeaderboardEntry>[];
      var rank = 1;
      bool playerFound = false;

      for (var i = 0; i < sortedDocs.length; i++) {
        final data = sortedDocs[i];
        final username = (data['username'] ?? 'Pemain') as String;
        final isCurrent = currentPlayerUsername != null &&
            username.toLowerCase() == currentPlayerUsername.toLowerCase();

        if (isCurrent) {
          playerFound = true;
        }

        if (i < limit) {
          entries.add(
            LeaderboardEntry(
              rank: rank++,
              username: username,
              avatarId: data['avatar_id'] as String?,
              correctCount: ((data['correct_count'] ?? 0) as num).toInt(),
              totalTimeMs: ((data['total_time_ms'] ?? 0) as num).toInt(),
              isCurrentPlayer: isCurrent,
            ),
          );
        } else if (playerFound && isCurrent) {
          // Pemain berada di luar top-limit, sisipkan posisinya di paling bawah
          entries.add(
            LeaderboardEntry(
              rank: i + 1,
              username: username,
              avatarId: data['avatar_id'] as String?,
              correctCount: ((data['correct_count'] ?? 0) as num).toInt(),
              totalTimeMs: ((data['total_time_ms'] ?? 0) as num).toInt(),
              isCurrentPlayer: true,
            ),
          );
          break;
        }
      }

      return RepoSuccess(entries);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal memuat papan peringkat'),
        e,
      );
    }
  }

  @override
  Future<RepoResult<LeaderboardEntry?>> getPlayerEntry({
    required String band,
    required DateTime date,
    required String username,
  }) async {
    try {
      final dateKey = _formatDateKey(date);
      final cleanUsername = username.trim().toLowerCase();
      final docId = '${dateKey}_${band}_$cleanUsername';
      final col = firestore.collection(collectionName);

      // 1. Ambil dokumen pemain langsung (tanpa scan koleksi).
      final doc = await col.doc(docId).get().timeout(
        const Duration(seconds: 10),
      );
      if (!doc.exists) {
        // Fallback: dokumen lama memakai username case-asli.
        final legacy = await col
            .where('band', isEqualTo: band)
            .where('date', isEqualTo: dateKey)
            .where('username', isEqualTo: username)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));
        if (legacy.docs.isEmpty) return const RepoSuccess(null);
        final data = legacy.docs.first.data();
        return RepoSuccess(
          LeaderboardEntry(
            rank: -1, // rank tidak diketahui tanpa scan; UI pakai fetchTopEntries
            username: (data['username'] ?? username) as String,
            avatarId: data['avatar_id'] as String?,
            correctCount: ((data['correct_count'] ?? 0) as num).toInt(),
            totalTimeMs: ((data['total_time_ms'] ?? 0) as num).toInt(),
            isCurrentPlayer: true,
          ),
        );
      }

      final data = doc.data()!;
      final mineCorrect = ((data['correct_count'] ?? 0) as num).toInt();
      final mineTime = ((data['total_time_ms'] ?? 0) as num).toInt();

      // 2. Hitung rank via agregasi count (tanpa unduh dokumen lain).
      final baseQuery = col
          .where('band', isEqualTo: band)
          .where('date', isEqualTo: dateKey);
      final better = await baseQuery
          .where('correct_count', isGreaterThan: mineCorrect)
          .count()
          .get()
          .timeout(const Duration(seconds: 10));
      final tiedFaster = await baseQuery
          .where('correct_count', isEqualTo: mineCorrect)
          .where('total_time_ms', isLessThan: mineTime)
          .count()
          .get()
          .timeout(const Duration(seconds: 10));
      final rank =
          ((better.count ?? 0) + (tiedFaster.count ?? 0)) + 1;

      return RepoSuccess(
        LeaderboardEntry(
          rank: rank,
          username: (data['username'] ?? username) as String,
          avatarId: data['avatar_id'] as String?,
          correctCount: mineCorrect,
          totalTimeMs: mineTime,
          isCurrentPlayer: true,
        ),
      );
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal menghitung posisi pemain'),
        e,
      );
    }
  }

  @override
  Future<RepoResult<List<LeaderboardEntry>>> fetchAllTimeEntries({
    int limit = 50,
    String? currentPlayerUsername,
  }) async {
    try {
      // Query /profiles diurutkan by total_score desc (single-field, tidak butuh Composite Index)
      final snapshot = await firestore
          .collection(profilesCollection)
          .orderBy('total_score', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 10));

      final entries = <LeaderboardEntry>[];
      var rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final username = (data['username'] ?? '') as String;
        if (username.isEmpty) continue; // skip profil tanpa username

        final isCurrent = currentPlayerUsername != null &&
            username.toLowerCase() == currentPlayerUsername.toLowerCase();

        entries.add(
          LeaderboardEntry(
            rank: rank++,
            username: username,
            avatarId: data['avatar_id'] as String?,
            correctCount: 0,
            totalTimeMs: 0,
            isCurrentPlayer: isCurrent,
            totalScore: data['total_score'] != null
                ? ((data['total_score']) as num).toInt()
                : 0,
          ),
        );
      }

      return RepoSuccess(entries);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal memuat papan all-time'),
        e,
      );
    }
  }

  @override
  Future<RepoResult<void>> submitDailyResult({
    required DailyChallengeResult result,
    required String username,
    String? avatarId,
    int? totalScore,
    int? currentLevel,
    int? totalXp,
  }) async {
    try {
      final dateKey = _formatDateKey(result.date);
      final cleanUsername = username.trim().toLowerCase();
      final docId = '${dateKey}_${result.band}_$cleanUsername';

      final currentUid = auth.currentUser?.uid ?? result.playerId;

      // 1. Simpan hasil daily challenge (prioritas utama, terisolasi)
      await firestore.collection(collectionName).doc(docId).set({
        'player_id': currentUid,
        'username': username,
        'avatar_id': avatarId,
        'band': result.band,
        'date': dateKey,
        'correct_count': result.correctCount,
        'total_time_ms': result.totalTimeMs,
        'submitted_at': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      // 2. Best-effort sinkronisasi profil ke /profiles/{currentUid}
      //    Daily TIDAK menambah skor — ini hanya menyelaraskan agar all-time
      //    dan level tidak tertinggal. Terisolasi agar kegagalan sinkronisasi profil tidak membatalkan
      //    pencatatan daily challenge yang sudah berhasil.
      if (totalScore != null || currentLevel != null || totalXp != null) {
        try {
          await _mergeProfileTotalMax(
            uid: currentUid,
            username: username,
            avatarId: avatarId,
            totalScore: totalScore ?? 0,
            currentLevel: currentLevel,
            totalXp: totalXp,
          );
        } catch (_) {
          // Abaikan kegagalan sinkronisasi profil sekunder agar daily result tetap valid
        }
      }

      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal mengunggah skor tantangan harian'),
        e,
      );
    }
  }

  @override
  Future<RepoResult<void>> syncProfileTotal({
    required String username,
    String? avatarId,
    required int totalScore,
  }) =>
      syncProfileProgress(
        username: username,
        avatarId: avatarId,
        totalScore: totalScore,
      );

  @override
  Future<RepoResult<void>> syncProfileProgress({
    required String username,
    String? avatarId,
    required int totalScore,
    int? currentLevel,
    int? totalXp,
    Map<String, dynamic>? levelRecords,
    Map<String, dynamic>? challengeRecords,
  }) async {
    try {
      final currentUid = auth.currentUser?.uid;
      if (currentUid == null) return const RepoSuccess(null);
      await _mergeProfileTotalMax(
        uid: currentUid,
        username: username,
        avatarId: avatarId,
        totalScore: totalScore,
        currentLevel: currentLevel,
        totalXp: totalXp,
        levelRecords: levelRecords,
        challengeRecords: challengeRecords,
      );
      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal menyinkronkan profil pemain'),
        e,
      );
    }
  }

  @override
  Future<RepoResult<Map<String, dynamic>?>> fetchCloudProfile(String uid) async {
    try {
      final doc = await firestore
          .collection(profilesCollection)
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      Map<String, dynamic>? data = doc.exists ? doc.data() : null;

      // Fallback: jika profil belum ada atau belum memiliki username,
      // cari di koleksi /usernames berdasarkan uid pemilik
      final existingUsername = data?['username']?.toString().trim();
      if (data == null || existingUsername == null || existingUsername.isEmpty) {
        final uQuery = await firestore
            .collection('usernames')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));
        if (uQuery.docs.isNotEmpty) {
          final uData = uQuery.docs.first.data();
          final foundUsername = uData['username']?.toString().trim();
          if (foundUsername != null && foundUsername.isNotEmpty) {
            data = {
              ...?data,
              'username': foundUsername,
            };
          }
        }
      }

      return RepoSuccess(data);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(e, defaultMessage: 'Gagal memuat profil pemain dari cloud'),
        e,
      );
    }
  }

  /// Menulis profil dengan semantik max() via transaksi agar nilai lama
  /// dari snapshot usang tidak pernah menimpa total_score, level, xp, atau level_records.
  Future<void> _mergeProfileTotalMax({
    required String uid,
    required String username,
    String? avatarId,
    required int totalScore,
    int? currentLevel,
    int? totalXp,
    Map<String, dynamic>? levelRecords,
    Map<String, dynamic>? challengeRecords,
  }) async {
    final ref = firestore.collection(profilesCollection).doc(uid);
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final existingScore = snap.exists
          ? (((snap.data()?['total_score'] ?? 0) as num).toInt())
          : 0;
      final existingLevel = snap.exists
          ? (((snap.data()?['current_level'] ?? 1) as num).toInt())
          : 1;
      final existingXp = snap.exists
          ? (((snap.data()?['total_xp'] ?? 0) as num).toInt())
          : 0;

      final mergedScore = totalScore > existingScore ? totalScore : existingScore;
      final mergedLevel = (currentLevel != null && currentLevel > existingLevel)
          ? currentLevel
          : existingLevel;
      final mergedXp = (totalXp != null && totalXp > existingXp)
          ? totalXp
          : existingXp;

      final existingLevelRecords = snap.exists
          ? (snap.data()?['level_records'] as Map<String, dynamic>? ?? {})
          : <String, dynamic>{};

      final mergedLevelRecords = Map<String, dynamic>.from(existingLevelRecords);
      if (levelRecords != null) {
        for (final entry in levelRecords.entries) {
          final k = entry.key;
          if (entry.value is! Map) continue;
          final newVal = Map<String, dynamic>.from(entry.value as Map);
          final oldVal = mergedLevelRecords[k] is Map
              ? Map<String, dynamic>.from(mergedLevelRecords[k] as Map)
              : null;
          if (oldVal == null) {
            mergedLevelRecords[k] = newVal;
          } else {
            final oldBest = ((oldVal['best_score'] ?? 0) as num).toInt();
            final newBest = ((newVal['best_score'] ?? 0) as num).toInt();
            final oldStars = ((oldVal['stars'] ?? 0) as num).toInt();
            final newStars = ((newVal['stars'] ?? 0) as num).toInt();
            final oldAttempts = ((oldVal['attempts'] ?? 0) as num).toInt();
            final newAttempts = ((newVal['attempts'] ?? 0) as num).toInt();
            mergedLevelRecords[k] = {
              'best_score': newBest > oldBest ? newBest : oldBest,
              'stars': newStars > oldStars ? newStars : oldStars,
              'attempts': newAttempts > oldAttempts ? newAttempts : oldAttempts,
            };
          }
        }
      }

      final existingChallengeRecords = snap.exists
          ? (snap.data()?['challenge_records'] as Map<String, dynamic>? ?? {})
          : <String, dynamic>{};

      final mergedChallengeRecords =
          Map<String, dynamic>.from(existingChallengeRecords);
      if (challengeRecords != null) {
        for (final entry in challengeRecords.entries) {
          final k = entry.key;
          if (entry.value is! Map) continue;
          final newVal = Map<String, dynamic>.from(entry.value as Map);
          final oldVal = mergedChallengeRecords[k] is Map
              ? Map<String, dynamic>.from(mergedChallengeRecords[k] as Map)
              : null;
          if (oldVal == null) {
            mergedChallengeRecords[k] = newVal;
          } else {
            final oldBest = ((oldVal['best_score'] ?? 0) as num).toInt();
            final newBest = ((newVal['best_score'] ?? 0) as num).toInt();
            final oldAttempts = ((oldVal['attempts'] ?? 0) as num).toInt();
            final newAttempts = ((newVal['attempts'] ?? 0) as num).toInt();
            mergedChallengeRecords[k] = {
              'mode': newVal['mode'] ?? oldVal['mode'],
              'band': newVal['band'] ?? oldVal['band'],
              'best_score': newBest > oldBest ? newBest : oldBest,
              'attempts': newAttempts > oldAttempts ? newAttempts : oldAttempts,
            };
          }
        }
      }

      final profilePayload = <String, dynamic>{
        'username': username,
        'avatar_id': avatarId,
        'total_score': mergedScore,
        'current_level': mergedLevel,
        'total_xp': mergedXp,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (mergedLevelRecords.isNotEmpty) {
        profilePayload['level_records'] = mergedLevelRecords;
      }
      if (mergedChallengeRecords.isNotEmpty) {
        profilePayload['challenge_records'] = mergedChallengeRecords;
      }

      tx.set(ref, profilePayload, SetOptions(merge: true));
    }).timeout(const Duration(seconds: 10));
  }

  @override
  Future<RepoResult<PublicProfile?>> fetchPublicProfile(String username) async {
    try {
      final clean = username.trim();
      if (clean.isEmpty) {
        return const RepoSuccess(null);
      }

      final snapshot = await firestore
          .collection(profilesCollection)
          .where('username', isEqualTo: clean)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isEmpty) {
        return const RepoSuccess(null);
      }

      final data = snapshot.docs.first.data();
      return RepoSuccess(PublicProfile.fromJson(data));
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(
          e,
          defaultMessage: 'Gagal memuat profil publik pemain',
        ),
        e,
      );
    }
  }

  @override
  Future<RepoResult<List<LeaderboardEntry>>> fetchChallengeLeaderboard({
    required String mode,
    required String band,
    int limit = 50,
    String? currentPlayerUsername,
  }) async {
    try {
      final snapshot = await firestore
          .collection('challenge_leaderboards')
          .doc('${mode}_$band')
          .collection('entries')
          .orderBy('best_score', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(seconds: 10));

      final entries = <LeaderboardEntry>[];
      var rank = 1;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final username = (data['username'] ?? 'Pemain') as String;
        final isCurrent = currentPlayerUsername != null &&
            username.toLowerCase() == currentPlayerUsername.toLowerCase();

        entries.add(
          LeaderboardEntry(
            rank: rank++,
            username: username,
            avatarId: data['avatar_id'] as String?,
            correctCount: ((data['correct_count'] ?? 0) as num).toInt(),
            totalTimeMs: 0,
            isCurrentPlayer: isCurrent,
            totalScore: ((data['best_score'] ?? 0) as num).toInt(),
            streak: data['streak'] != null
                ? ((data['streak']) as num).toInt()
                : null,
          ),
        );
      }

      return RepoSuccess(entries);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(
          e,
          defaultMessage: 'Gagal memuat papan peringkat tantangan',
        ),
        e,
      );
    }
  }

  @override
  Future<RepoResult<LeaderboardEntry?>> getPlayerChallengeEntry({
    required String mode,
    required String band,
    required String username,
  }) async {
    try {
      final clean = username.trim();
      if (clean.isEmpty) return const RepoSuccess(null);

      final querySnapshot = await firestore
          .collection('challenge_leaderboards')
          .doc('${mode}_$band')
          .collection('entries')
          .where('username', isEqualTo: clean)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (querySnapshot.docs.isEmpty) {
        return const RepoSuccess(null);
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      final score = ((data['best_score'] ?? 0) as num).toInt();

      final higherCountSnapshot = await firestore
          .collection('challenge_leaderboards')
          .doc('${mode}_$band')
          .collection('entries')
          .where('best_score', isGreaterThan: score)
          .count()
          .get()
          .timeout(const Duration(seconds: 10));

      final rank = (higherCountSnapshot.count ?? 0) + 1;

      return RepoSuccess(
        LeaderboardEntry(
          rank: rank,
          username: clean,
          avatarId: data['avatar_id'] as String?,
          correctCount: ((data['correct_count'] ?? 0) as num).toInt(),
          totalTimeMs: 0,
          isCurrentPlayer: true,
          totalScore: score,
          streak: data['streak'] != null
              ? ((data['streak']) as num).toInt()
              : null,
        ),
      );
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(
          e,
          defaultMessage: 'Gagal menghitung peringkat tantangan pemain',
        ),
        e,
      );
    }
  }

  @override
  Future<RepoResult<void>> submitChallengeScore({
    required String mode,
    required String band,
    required int score,
    int? correctCount,
    int? streak,
    required String username,
    String? avatarId,
  }) async {
    try {
      final currentUid = auth.currentUser?.uid ?? username.trim().toLowerCase();
      final docRef = firestore
          .collection('challenge_leaderboards')
          .doc('${mode}_$band')
          .collection('entries')
          .doc(currentUid);

      await firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final existingScore = snap.exists
            ? ((snap.data()?['best_score'] ?? 0) as num).toInt()
            : 0;

        if (score > existingScore) {
          final payload = <String, dynamic>{
            'player_id': currentUid,
            'username': username,
            'avatar_id': avatarId,
            'best_score': score,
            'updated_at': FieldValue.serverTimestamp(),
          };
          if (correctCount != null) payload['correct_count'] = correctCount;
          if (streak != null) payload['streak'] = streak;

          tx.set(docRef, payload, SetOptions(merge: true));
        }
      }).timeout(const Duration(seconds: 10));

      return const RepoSuccess(null);
    } catch (e) {
      return RepoFailure(
        FirebaseErrorMapper.map(
          e,
          defaultMessage: 'Gagal mencatat skor tantangan ke papan peringkat',
        ),
        e,
      );
    }
  }
}
