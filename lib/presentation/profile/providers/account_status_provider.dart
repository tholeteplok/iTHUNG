import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/level_score_record.dart';
import '../../../domain/models/player_profile.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../daily_challenge/providers/daily_sync_provider.dart';
import '../../game/providers/game_dependencies_provider.dart';
import '../../home/providers/level_stars_provider.dart';
import '../../home/providers/player_profile_provider.dart';
import 'profile_stats_provider.dart';

/// Status akun pemain.
enum AccountStatus {
  /// Bermain offline secara lokal tanpa akun Firebase.
  guest,

  /// Masuk dengan akun anonim Firebase.
  anonymous,

  /// Terhubung dengan akun permanen (mis. Google).
  linked,
}

/// Data state untuk akun pemain aktif.
class AccountState {
  const AccountState({
    required this.status,
    this.userId,
    this.username,
    this.hasVerifiedSession = false,
  });

  final AccountStatus status;
  final String? userId;
  final String? username;

  /// True hanya jika ada sesi Firebase Auth aktif (bukan sekadar cache lokal).
  ///
  /// Bedakan dari [username] yang bisa berasal dari Hive lokal walau sesi cloud
  /// sudah hilang (reinstall, token dicabut, dsb.).
  final bool hasVerifiedSession;

  bool get isGuest => status == AccountStatus.guest;
  bool get hasUsername => username != null && username!.trim().length >= 4;

  /// True hanya jika aman untuk mengirim data ke Firestore.
  ///
  /// Dipakai di semua titik submission cloud (daily challenge, sync total_score)
  /// agar tidak mengandalkan cek `username != null` yang bisa misleading saat
  /// sesi Firebase sudah hilang tapi cache Hive masih ada.
  bool get canSubmitToCloud => hasVerifiedSession && hasUsername;

  AccountState copyWith({
    AccountStatus? status,
    String? userId,
    String? username,
    bool? hasVerifiedSession,
  }) {
    return AccountState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      hasVerifiedSession: hasVerifiedSession ?? this.hasVerifiedSession,
    );
  }
}

final accountStatusProvider =
    AsyncNotifierProvider<AccountStatusNotifier, AccountState>(
      AccountStatusNotifier.new,
    );

class AccountStatusNotifier extends AsyncNotifier<AccountState> {
  @override
  FutureOr<AccountState> build() async {
    final authRepo = ref.watch(authRepositoryProvider);

    // Dapatkan username dari profil lokal tanpa memasang reactive watch
    // untuk mencegah circular invalidation loop.
    final localProfile = ref.read(playerProfileProvider).valueOrNull;

    if (!authRepo.isLoggedIn) {
      // Tidak ada sesi Firebase — username lokal boleh ditampilkan di UI
      // tapi TIDAK boleh dipakai untuk submission cloud.
      return AccountState(
        status: AccountStatus.guest,
        username: localProfile?.username,
        hasVerifiedSession: false,
      );
    }

    final uid = authRepo.currentUserId;
    String? effectiveUsername = authRepo.currentUsername ?? localProfile?.username;

    // Jika user sudah login dan profil lokal belum punya username atau butuh sinkronisasi dari cloud
    if (uid != null && (effectiveUsername == null || effectiveUsername.isEmpty)) {
      effectiveUsername = await _restoreFromCloud(
        uid: uid,
        localProfile: localProfile,
        initialUsername: effectiveUsername,
      );
    }

    if (authRepo.isLoggedIn &&
        effectiveUsername != null &&
        effectiveUsername.isNotEmpty) {
      Future.microtask(() {
        ref.read(dailySyncServiceProvider).syncPendingSubmissions();
      });
    }

    return AccountState(
      status: authRepo.isAnonymous ? AccountStatus.anonymous : AccountStatus.linked,
      userId: uid,
      username: effectiveUsername,
      hasVerifiedSession: true,
    );
  }

  /// Memulihkan dan menyinkronkan profil pemain dari cloud (/profiles/{uid} & /usernames).
  Future<String?> _restoreFromCloud({
    required String uid,
    required PlayerProfile? localProfile,
    required String? initialUsername,
  }) async {
    String? effectiveUsername = initialUsername;
    try {
      final leaderboardRepo = ref.read(leaderboardRepositoryProvider);
      final cloudRes = await leaderboardRepo.fetchCloudProfile(uid);

      if (cloudRes is RepoSuccess<Map<String, dynamic>?> && cloudRes.value != null) {
        final cloudData = cloudRes.value!;
        final cloudUsername = (cloudData['username'] as String?)?.trim();
        final cloudAvatarId = cloudData['avatar_id'] as String?;
        final cloudLevel = ((cloudData['current_level'] ?? 1) as num).toInt();
        final cloudXp = ((cloudData['total_xp'] ?? 0) as num).toInt();
        final cloudScore = ((cloudData['total_score'] ?? 0) as num).toInt();

        if (cloudUsername != null && cloudUsername.isNotEmpty) {
          effectiveUsername = cloudUsername;
        }

        // Pastikan basis profil tersedia meskipun baru diinstal atau data terhapus
        final repo = ref.read(playerRepositoryProvider);
        PlayerProfile baseProfile = localProfile ?? PlayerProfile.initial(playerId: uid);
        if (localProfile == null) {
          final res = await repo.getProfile();
          if (res is RepoSuccess<PlayerProfile>) {
            baseProfile = res.value;
          }
        }

        final mergedLevel = cloudLevel > baseProfile.currentLevel
            ? cloudLevel
            : baseProfile.currentLevel;
        final mergedXp = cloudXp > baseProfile.totalXp
            ? cloudXp
            : baseProfile.totalXp;
        final mergedScore = cloudScore > baseProfile.totalScore
            ? cloudScore
            : baseProfile.totalScore;

        final restoredProfile = baseProfile.copyWith(
          username: effectiveUsername ?? baseProfile.username,
          avatarId: cloudAvatarId ?? baseProfile.avatarId,
          currentLevel: mergedLevel,
          totalXp: mergedXp,
          totalScore: mergedScore,
        );

        await ref.read(playerProfileProvider.notifier).updateProfile(restoredProfile);

        // 2. Pulihkan rekor skor & bintang per level dari Cloud ke Hive lokal
        final cloudRecords = cloudData['level_records'] as Map<String, dynamic>?;
        if (cloudRecords != null && cloudRecords.isNotEmpty) {
          final scoreRepo = ref.read(levelScoreRepositoryProvider);
          final restoredStarsMap = <int, int>{};

          for (final entry in cloudRecords.entries) {
            final lvl = int.tryParse(entry.key);
            if (lvl != null && entry.value is Map) {
              final recMap = Map<String, dynamic>.from(entry.value as Map);
              recMap['level'] = lvl;
              final record = LevelScoreRecord.fromJson(recMap);
              await scoreRepo.saveRecord(record);
              if (record.stars > 0) {
                restoredStarsMap[lvl] = record.stars;
              }
            }
          }

          if (restoredStarsMap.isNotEmpty) {
            ref.read(levelStarsProvider.notifier).restoreStars(restoredStarsMap);
          }
        }
        ref.invalidate(profileStatsProvider);

        // 3. Rekonsiliasi Dua Arah (Self-Healing Push):
        // Jika data kemajuan lokal (level, skor, atau XP) ternyata lebih tinggi daripada di cloud,
        // dorong pembaruan ke Firestore secara asynchronous di background agar profil cloud
        // langsung terpulihkan (misal kasus pemain yang bermain offline).
        final localLevelIsHigher = baseProfile.currentLevel > cloudLevel;
        final localScoreIsHigher = baseProfile.totalScore > cloudScore;
        final localXpIsHigher = baseProfile.totalXp > cloudXp;

        final usernameToPush = restoredProfile.username ?? effectiveUsername;
        if ((localLevelIsHigher || localScoreIsHigher || localXpIsHigher) &&
            usernameToPush != null &&
            usernameToPush.trim().length >= 4) {
          unawaited(() async {
            try {
              final scoreRepo = ref.read(levelScoreRepositoryProvider);
              final allRecordsRes = await scoreRepo.getAllRecords();
              final Map<String, dynamic> localRecordsPayload = {};
              if (allRecordsRes is RepoSuccess<Map<int, LevelScoreRecord>>) {
                for (final entry in allRecordsRes.value.entries) {
                  localRecordsPayload[entry.key.toString()] = entry.value.toJson();
                }
              }

              await leaderboardRepo.syncProfileProgress(
                username: usernameToPush,
                avatarId: restoredProfile.avatarId,
                totalScore: restoredProfile.totalScore,
                currentLevel: restoredProfile.currentLevel,
                totalXp: restoredProfile.totalXp,
                levelRecords: localRecordsPayload.isNotEmpty ? localRecordsPayload : null,
              );
            } catch (err) {
              debugPrint('[_restoreFromCloud] Gagal self-healing push ke cloud: $err');
            }
          }());
        }
      } else if (cloudRes is RepoSuccess<Map<String, dynamic>?> && cloudRes.value == null) {
        // Dokumen cloud belum ada. Inisialisasi profil ke Firestore jika data lokal tersedia.
        final repo = ref.read(playerRepositoryProvider);
        PlayerProfile baseProfile = localProfile ?? PlayerProfile.initial(playerId: uid);
        if (localProfile == null) {
          final res = await repo.getProfile();
          if (res is RepoSuccess<PlayerProfile>) {
            baseProfile = res.value;
          }
        }
        if (effectiveUsername != null && effectiveUsername.trim().length >= 4) {
          final profileToSync = baseProfile;
          final usernameToSync = effectiveUsername;
          unawaited(() async {
            try {
              final scoreRepo = ref.read(levelScoreRepositoryProvider);
              final allRecordsRes = await scoreRepo.getAllRecords();
              final Map<String, dynamic> localRecordsPayload = {};
              if (allRecordsRes is RepoSuccess<Map<int, LevelScoreRecord>>) {
                for (final entry in allRecordsRes.value.entries) {
                  localRecordsPayload[entry.key.toString()] = entry.value.toJson();
                }
              }

              await leaderboardRepo.syncProfileProgress(
                username: usernameToSync,
                avatarId: profileToSync.avatarId,
                totalScore: profileToSync.totalScore,
                currentLevel: profileToSync.currentLevel,
                totalXp: profileToSync.totalXp,
                levelRecords: localRecordsPayload.isNotEmpty ? localRecordsPayload : null,
              );
            } catch (err) {
              debugPrint('[_restoreFromCloud] Gagal inisialisasi push profil ke cloud: $err');
            }
          }());
        }
      }
    } catch (e, stack) {
      debugPrint('[_restoreFromCloud] Gagal memulihkan profil dari cloud: $e\n$stack');
    }
    return effectiveUsername;
  }

  /// Masuk secara anonim ke Firebase.
  Future<RepoResult<AccountState>> signInAnonymously() async {
    state = const AsyncLoading();
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signInAnonymously();

    if (result is RepoSuccess<String>) {
      final uid = result.value;
      final localProfile = ref.read(playerProfileProvider).valueOrNull;
      final effectiveUsername = await _restoreFromCloud(
        uid: uid,
        localProfile: localProfile,
        initialUsername: authRepo.currentUsername ?? localProfile?.username,
      );

      final accountState = AccountState(
        status: AccountStatus.anonymous,
        userId: uid,
        username: effectiveUsername,
        hasVerifiedSession: true,
      );

      state = AsyncData(accountState);
      ref.read(dailySyncServiceProvider).syncPendingSubmissions();
      return RepoSuccess(accountState);
    } else {
      final failure = result as RepoFailure<String>;
      final guestState = AccountState(
        status: AccountStatus.guest,
        username: ref.read(playerProfileProvider).valueOrNull?.username,
        hasVerifiedSession: false,
      );
      state = AsyncData(guestState);
      return RepoFailure(failure.reason, failure.exception);
    }
  }

  /// Masuk dengan Google.
  Future<RepoResult<AccountState>> signInWithGoogle() async {
    state = const AsyncLoading();
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signInWithGoogle();

    if (result is RepoSuccess<String>) {
      final uid = result.value;
      final localProfile = ref.read(playerProfileProvider).valueOrNull;
      final effectiveUsername = await _restoreFromCloud(
        uid: uid,
        localProfile: localProfile,
        initialUsername: authRepo.currentUsername ?? localProfile?.username,
      );

      final accountState = AccountState(
        status: AccountStatus.linked,
        userId: uid,
        username: effectiveUsername,
        hasVerifiedSession: true,
      );

      state = AsyncData(accountState);
      ref.read(dailySyncServiceProvider).syncPendingSubmissions();
      return RepoSuccess(accountState);
    } else {
      final failure = result as RepoFailure<String>;
      final guestState = AccountState(
        status: AccountStatus.guest,
        username: ref.read(playerProfileProvider).valueOrNull?.username,
        hasVerifiedSession: false,
      );
      state = AsyncData(guestState);
      return RepoFailure(failure.reason, failure.exception);
    }
  }

  /// Keluar dari akun pemain dan membersihkan data gameplay lokal ke status Tamu baru.
  ///
  /// Progres akun cloud (Google) tetap aman di Firestore dan akan dipulihkan utuh saat login ulang.
  Future<RepoResult<void>> signOut() async {
    // 1. Sinkronisasi akhir untuk pending submissions jika ada sesi aktif
    try {
      await ref.read(dailySyncServiceProvider).syncPendingSubmissions();
    } catch (_) {}

    // 2. Putus sesi autentikasi Firebase
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.signOut();

    // 3. Reset repositori data gameplay lokal ke default
    final playerRepo = ref.read(playerRepositoryProvider);
    final resetResult = await playerRepo.resetProfile();
    final newProfile = switch (resetResult) {
      RepoSuccess(:final value) => value,
      RepoFailure() => PlayerProfile.initial(
          playerId: 'p_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
        ),
    };

    await ref.read(levelScoreRepositoryProvider).clearAll();
    await ref.read(masteryRepositoryProvider).clearAll();
    await ref.read(sessionRepositoryProvider).clearAll();
    await ref.read(dailyChallengeRepositoryProvider).clearUserData();

    // 4. Perbarui state reaktif di memori
    ref.read(playerProfileProvider.notifier).resetProfile(newProfile);
    ref.read(levelStarsProvider.notifier).resetStars();
    ref.invalidate(profileStatsProvider);

    state = const AsyncData(
      AccountState(
        status: AccountStatus.guest,
        username: null,
        hasVerifiedSession: false,
      ),
    );

    return result;
  }

  /// Menetapkan username (minimal 4 karakter).
  Future<RepoResult<void>> setUsername(String username) async {
    final clean = username.trim();
    if (clean.length < 4) {
      return const RepoFailure('Username minimal 4 karakter');
    }

    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.setUsername(clean);

    if (result is RepoSuccess<void>) {
      final current = state.valueOrNull ?? const AccountState(status: AccountStatus.guest);
      state = AsyncData(current.copyWith(username: clean));

      // Simpan juga ke player profile lokal
      final profile = ref.read(playerProfileProvider).valueOrNull;
      if (profile != null) {
        final updated = profile.copyWith(username: clean);
        await ref.read(playerProfileProvider.notifier).updateProfile(updated);
      }
    }

    return result;
  }
}
