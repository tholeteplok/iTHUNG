import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/leaderboard_entry.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../game/providers/game_dependencies_provider.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../home/providers/player_profile_provider.dart';
import '../../profile/providers/account_status_provider.dart';

/// Mode tampilan leaderboard: harian (daily) atau semua waktu (all-time).
enum LeaderboardMode { daily, allTime }

/// Provider mode yang sedang aktif di layar leaderboard.
final leaderboardModeProvider = StateProvider<LeaderboardMode>((ref) {
  return LeaderboardMode.daily;
});

/// Provider untuk band level yang sedang aktif dipilih pada tab Leaderboard.
final leaderboardSelectedBandProvider = StateProvider<String>((ref) {
  final level = ref.watch(playerProfileProvider).valueOrNull?.currentLevel ?? 1;
  final config = ref.watch(levelBandsConfigProvider).valueOrNull;
  return config?.bandForLevel(level).id ?? 'onboarding';
});

/// Notifier untuk memuat dan mengelola entri leaderboard harian per band.
/// Mendukung update optimistik instan (§5.2) tanpa jeda jaringan.
class LeaderboardEntriesNotifier
    extends FamilyAsyncNotifier<List<LeaderboardEntry>, String> {
  @override
  FutureOr<List<LeaderboardEntry>> build(String arg) async {
    final repo = ref.watch(leaderboardRepositoryProvider);
    final accountState = ref.watch(accountStatusProvider).valueOrNull;
    final username = accountState?.username;
    final now = DateTime.now();

    final result = await repo.fetchTopEntries(
      band: arg,
      date: now,
      limit: 50,
      currentPlayerUsername: username,
    );

    return switch (result) {
      RepoSuccess(:final value) => value,
      RepoFailure(:final reason) => throw Exception(reason),
    };
  }

  /// Menambahkan entri pemain saat ini secara optimistik ke daftar leaderboard.
  /// Otomatis mengurutkan berdasarkan skor tertinggi & waktu tercepat,
  /// serta menghitung peringkat virtual lokal (1..N).
  void addOptimisticEntry(LeaderboardEntry entry) {
    final current = state.valueOrNull ?? [];
    final filtered = current.where(
      (e) => e.username.toLowerCase() != entry.username.toLowerCase(),
    ).toList();
    filtered.add(entry);

    filtered.sort((a, b) {
      final comp = b.correctCount.compareTo(a.correctCount);
      if (comp != 0) return comp;
      return a.totalTimeMs.compareTo(b.totalTimeMs);
    });

    final ranked = [
      for (var i = 0; i < filtered.length; i++)
        filtered[i].copyWith(rank: i + 1),
    ];

    state = AsyncData(ranked);
  }

  /// Membatalkan entri optimistik (rollback) jika pengiriman cloud gagal.
  void rollbackOptimisticEntry(String username) {
    final current = state.valueOrNull;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }

    final filtered = current.where(
      (e) => e.username.toLowerCase() != username.toLowerCase(),
    ).toList();

    final ranked = [
      for (var i = 0; i < filtered.length; i++)
        filtered[i].copyWith(rank: i + 1),
    ];

    state = AsyncData(ranked);
  }
}

/// Provider untuk memuat daftar entri leaderboard per band level (mode harian).
final leaderboardEntriesProvider = AsyncNotifierProvider.family<
    LeaderboardEntriesNotifier, List<LeaderboardEntry>, String>(
  LeaderboardEntriesNotifier.new,
);

/// Notifier untuk memuat dan mengelola entri leaderboard all-time (total skor akumulatif).
class AllTimeEntriesNotifier extends AsyncNotifier<List<LeaderboardEntry>> {
  @override
  FutureOr<List<LeaderboardEntry>> build() async {
    final repo = ref.watch(leaderboardRepositoryProvider);
    final accountState = ref.watch(accountStatusProvider).valueOrNull;
    final username = accountState?.username;

    final result = await repo.fetchAllTimeEntries(
      limit: 50,
      currentPlayerUsername: username,
    );

    return switch (result) {
      RepoSuccess(:final value) => value,
      RepoFailure(:final reason) => throw Exception(reason),
    };
  }

  /// Menambahkan / memperbarui skor total pemain secara optimistik pada list all-time.
  void addOptimisticScore({
    required String username,
    required int newTotalScore,
    String? avatarId,
  }) {
    final current = state.valueOrNull ?? [];
    final lowerUser = username.toLowerCase();

    final existingIndex = current.indexWhere((e) => e.username.toLowerCase() == lowerUser);

    final List<LeaderboardEntry> list;
    if (existingIndex != -1) {
      final existing = current[existingIndex];
      final higherScore = newTotalScore > (existing.totalScore ?? 0)
          ? newTotalScore
          : (existing.totalScore ?? 0);
      final updated = existing.copyWith(
        totalScore: higherScore,
        avatarId: avatarId ?? existing.avatarId,
        isCurrentPlayer: true,
      );
      list = [...current]..[existingIndex] = updated;
    } else {
      list = [
        ...current,
        LeaderboardEntry(
          rank: 1,
          username: username,
          avatarId: avatarId,
          correctCount: 0,
          totalTimeMs: 0,
          totalScore: newTotalScore,
          isCurrentPlayer: true,
        ),
      ];
    }

    list.sort((a, b) => (b.totalScore ?? 0).compareTo(a.totalScore ?? 0));

    final ranked = [
      for (var i = 0; i < list.length; i++)
        list[i].copyWith(rank: i + 1),
    ];

    state = AsyncData(ranked);
  }

  /// Membatalkan perubahan skor optimistik jika sinkronisasi gagal.
  void rollbackOptimisticScore(String username) {
    ref.invalidateSelf();
  }
}

/// Provider untuk memuat daftar entri leaderboard all-time (total skor akumulatif).
final allTimeEntriesProvider =
    AsyncNotifierProvider<AllTimeEntriesNotifier, List<LeaderboardEntry>>(
  AllTimeEntriesNotifier.new,
);

/// Provider untuk mengambil posisi pemain sendiri jika di luar Top-N (khusus mode harian).
final playerLeaderboardEntryProvider = FutureProvider.autoDispose.family<LeaderboardEntry?, String>((ref, band) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final accountState = ref.watch(accountStatusProvider).valueOrNull;
  final username = accountState?.username;
  if (username == null || username.isEmpty) return null;

  final now = DateTime.now();
  final result = await repo.getPlayerEntry(band: band, date: now, username: username);
  return switch (result) {
    RepoSuccess(:final value) => value,
    RepoFailure() => null,
  };
});
