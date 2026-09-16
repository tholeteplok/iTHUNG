import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/challenge_score_record.dart';
import '../../../domain/models/daily_challenge.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../game/providers/game_dependencies_provider.dart';
import '../../home/providers/player_profile_provider.dart';
import '../../leaderboard/providers/leaderboard_provider.dart';
import '../../profile/providers/account_status_provider.dart';

final dailySyncServiceProvider = Provider<DailySyncService>((ref) {
  return DailySyncService(ref);
});

/// Service sentral untuk menyinkronkan antrean hasil tantangan harian lokal ke Firestore.
class DailySyncService {
  DailySyncService(this._ref);

  final Ref _ref;
  bool _isSyncing = false;

  /// Mengunggah seluruh hasil tantangan harian yang tertunda atau belum tersinkron ke cloud.
  Future<void> syncPendingSubmissions() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      if (!authRepo.isLoggedIn) return;

      final profile = _ref.read(playerProfileProvider).valueOrNull;
      AccountState? accountState;
      try {
        accountState = await _ref.read(accountStatusProvider.future);
      } catch (_) {
        accountState = _ref.read(accountStatusProvider).valueOrNull;
      }

      final username = accountState?.username ?? profile?.username;
      if (username == null || username.trim().length < 4) return;

      final dailyRepo = _ref.read(dailyChallengeRepositoryProvider);
      final leaderboardRepo = _ref.read(leaderboardRepositoryProvider);

      bool hasSyncedNewDaily = false;
      final syncedDailyBands = <String>{};

      // 1. Sinkronkan seluruh antrean pending dari Hive
      final pendingRes = await dailyRepo.getPendingSubmissions();
      if (pendingRes is RepoSuccess<List<DailyChallengeResult>>) {
        for (final item in pendingRes.value) {
          final submitRes = await leaderboardRepo.submitDailyResult(
            result: item,
            username: username,
            avatarId: profile?.avatarId,
            totalScore: profile?.totalScore,
            currentLevel: profile?.currentLevel,
            totalXp: profile?.totalXp,
          );
          if (submitRes is RepoSuccess) {
            final key = item.id ?? '${item.formattedDate}_${item.band}';
            await dailyRepo.markSubmissionSynced(key);
            hasSyncedNewDaily = true;
            syncedDailyBands.add(item.band);
          }
        }
      }

      // Invalidate hanya band harian yang benar-benar tersinkronisasi data baru
      for (final band in syncedDailyBands) {
        _ref.invalidate(leaderboardEntriesProvider(band));
      }

      // 2. Sinkronkan rekor tantangan khusus (Speed Blitz & Math Marathon) dari Hive ke Firestore
      final challengeRepo = _ref.read(challengeScoreRepositoryProvider);
      final challengeRecordsRes = await challengeRepo.getAllRecords();
      bool challengeSubmitted = false;
      if (challengeRecordsRes is RepoSuccess<Map<String, ChallengeScoreRecord>>) {
        for (final entry in challengeRecordsRes.value.entries) {
          final record = entry.value;
          if (record.bestScore > 0) {
            final res = await leaderboardRepo.submitChallengeScore(
              mode: record.mode,
              band: record.band,
              score: record.bestScore,
              username: username,
              avatarId: profile?.avatarId,
            );
            if (res is RepoSuccess) {
              challengeSubmitted = true;
            }
          }
        }
        if (challengeSubmitted) {
          final currentBand = _ref.read(leaderboardSelectedBandProvider);
          _ref.invalidate(challengeEntriesProvider((mode: 'blitz', band: currentBand)));
          _ref.invalidate(challengeEntriesProvider((mode: 'marathon', band: currentBand)));
        }
      }

      // Invalidate All-Time HANYA jika ada skor tantangan/harian baru yang terkirim
      if (hasSyncedNewDaily || challengeSubmitted) {
        _ref.invalidate(allTimeEntriesProvider);
      }
    } catch (_) {
      // Best-effort: kegagalan IO tidak menghalangi UI
    } finally {
      _isSyncing = false;
    }
  }
}
