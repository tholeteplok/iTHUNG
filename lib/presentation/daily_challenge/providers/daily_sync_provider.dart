import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/daily_challenge.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../game/providers/game_dependencies_provider.dart';
import '../../game/providers/level_band_theme_provider.dart';
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
      final now = DateTime.now();

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
            _ref.invalidate(leaderboardEntriesProvider(item.band));
          }
        }
      }

      // 2. Safeguard: Pastikan hasil lokal hari ini tersimpan di Firestore
      final config = _ref.read(levelBandsConfigProvider).valueOrNull;
      final currentLevel = profile?.currentLevel ?? 1;
      final bandId = config?.bandForLevel(currentLevel).id ?? 'basic';
      final todayResult = await dailyRepo.getResult(now, bandId);
      if (todayResult is RepoSuccess<DailyChallengeResult?> &&
          todayResult.value != null) {
        final submitRes = await leaderboardRepo.submitDailyResult(
          result: todayResult.value!,
          username: username,
          avatarId: profile?.avatarId,
          totalScore: profile?.totalScore,
          currentLevel: profile?.currentLevel,
          totalXp: profile?.totalXp,
        );
        if (submitRes is RepoSuccess) {
          final dateKey =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          await dailyRepo.markSubmissionSynced('${dateKey}_$bandId');
          _ref.invalidate(leaderboardEntriesProvider(bandId));
        }
      }

      _ref.invalidate(allTimeEntriesProvider);
    } catch (_) {
      // Best-effort: kegagalan IO tidak menghalangi UI
    } finally {
      _isSyncing = false;
    }
  }
}
