import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/firebase_error_mapper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/leaderboard_entry.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../profile/providers/account_status_provider.dart';
import '../../profile/widgets/set_username_dialog.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import '../../shared/widgets/segmented_pill.dart';
import '../../daily_challenge/providers/daily_sync_provider.dart';
import '../providers/leaderboard_provider.dart';
import 'leaderboard_podium.dart';
import 'pinned_self_rank_bar.dart';

/// Layar Papan Peringkat Global / Kohor Harian / Speed Blitz / Math Marathon.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  bool _hasTriggeredInitialSync = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerInitialSync();
    });
  }

  void _triggerInitialSync() {
    if (_hasTriggeredInitialSync || !mounted) return;
    _hasTriggeredInitialSync = true;

    final accountState = ref.read(accountStatusProvider).valueOrNull;
    if (accountState == null || accountState.isGuest || !accountState.hasUsername) {
      return;
    }

    // Picu auto-sync dan rekonsiliasi satu kali di latar belakang saat layar pertama kali dimount
    ref.read(dailySyncServiceProvider).syncPendingSubmissions();
    ref.read(accountStatusProvider.notifier).reconcileProfileWithCloud();
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountStatusProvider).valueOrNull ??
        const AccountState(status: AccountStatus.guest);

    // 1. Jika masih mode Guest (belum buat akun / username), tampilkan Locked State
    if (accountState.isGuest || !accountState.hasUsername) {
      return LeaderboardLockedView(accountState: accountState);
    }

    // 2. Jika sudah terhubung, tampilkan Leaderboard dengan mode toggle
    final mode = ref.watch(leaderboardModeProvider);
    final selectedBand = ref.watch(leaderboardSelectedBandProvider);

    final entriesAsync = switch (mode) {
      LeaderboardMode.daily =>
        ref.watch(leaderboardEntriesProvider(selectedBand)),
      LeaderboardMode.blitz =>
        ref.watch(challengeEntriesProvider((mode: 'blitz', band: selectedBand))),
      LeaderboardMode.marathon => ref.watch(
          challengeEntriesProvider((mode: 'marathon', band: selectedBand))),
      LeaderboardMode.allTime => ref.watch(allTimeEntriesProvider),
    };

    final playerEntryAsync = switch (mode) {
      LeaderboardMode.daily =>
        ref.watch(playerLeaderboardEntryProvider(selectedBand)),
      LeaderboardMode.blitz => ref.watch(
          playerChallengeEntryProvider((mode: 'blitz', band: selectedBand))),
      LeaderboardMode.marathon => ref.watch(
          playerChallengeEntryProvider((mode: 'marathon', band: selectedBand))),
      LeaderboardMode.allTime => const AsyncValue.data(null),
    };

    void navigateToPlayerProfile(LeaderboardEntry entry) {
      if (entry.isCurrentPlayer) {
        context.go('/profile');
      } else {
        context.push('/profile/${entry.username}');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.colorSandyCanvas,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar tersentral
              AppHeader(
                title: 'Papan Peringkat',
                showStats: false,
                onBackTap: () => context.go('/'),
              ),

              // Mode Toggle Pill (Harian / Speed / Maraton / Semua)
              const _ModeToggle(),
              const SizedBox(height: 6),

              // Band Tabs Selector â€” tampil di mode yang mendukung level band
              if (mode.hasBandSelector) ...[
                const _BandTabsSelector(),
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 4),

              // Konten State Leaderboard
              Expanded(
                child: entriesAsync.when(
                  loading: () => const LeaderboardLoadingView(),
                  error: (err, _) => LeaderboardErrorView(
                    error: err,
                    onRetry: () {
                      switch (mode) {
                        case LeaderboardMode.daily:
                          ref.invalidate(
                              leaderboardEntriesProvider(selectedBand));
                        case LeaderboardMode.blitz:
                          ref.invalidate(challengeEntriesProvider(
                              (mode: 'blitz', band: selectedBand)));
                        case LeaderboardMode.marathon:
                          ref.invalidate(challengeEntriesProvider(
                              (mode: 'marathon', band: selectedBand)));
                        case LeaderboardMode.allTime:
                          ref.invalidate(allTimeEntriesProvider);
                      }
                    },
                  ),
                  data: (entries) {
                    final hasCurrentPlayerInList =
                        entries.any((e) => e.isCurrentPlayer);
                    final outsidePlayer = !hasCurrentPlayerInList
                        ? playerEntryAsync.valueOrNull
                        : null;

                    return Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            color: AppTheme.colorWoodMedium,
                            backgroundColor: AppTheme.colorVanillaCard,
                            onRefresh: () async {
                              switch (mode) {
                                case LeaderboardMode.daily:
                                  await ref
                                      .read(dailySyncServiceProvider)
                                      .syncPendingSubmissions();
                                  ref.invalidate(
                                      leaderboardEntriesProvider(selectedBand));
                                  await ref.read(
                                      leaderboardEntriesProvider(selectedBand)
                                          .future);
                                case LeaderboardMode.blitz:
                                  ref.invalidate(challengeEntriesProvider(
                                      (mode: 'blitz', band: selectedBand)));
                                  await ref.read(challengeEntriesProvider(
                                          (mode: 'blitz', band: selectedBand))
                                      .future);
                                case LeaderboardMode.marathon:
                                  ref.invalidate(challengeEntriesProvider(
                                      (mode: 'marathon', band: selectedBand)));
                                  await ref.read(challengeEntriesProvider((
                                    mode: 'marathon',
                                    band: selectedBand
                                  )).future);
                                case LeaderboardMode.allTime:
                                  await ref
                                      .read(accountStatusProvider.notifier)
                                      .reconcileProfileWithCloud();
                                  ref.invalidate(allTimeEntriesProvider);
                                  await ref.read(allTimeEntriesProvider.future);
                              }
                            },
                            child: LeaderboardListView(
                              entries: entries,
                              mode: mode,
                              onPlayerTap: navigateToPlayerProfile,
                            ),
                          ),
                        ),
                        if (outsidePlayer != null)
                          PinnedSelfRankBar(
                            entry: outsidePlayer,
                            mode: mode,
                            onTap: () => navigateToPlayerProfile(outsidePlayer),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle pill untuk memilih mode leaderboard (Harian / Speed / Maraton / Semua).
class _ModeToggle extends ConsumerWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(leaderboardModeProvider);
    const modes = LeaderboardMode.values;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedPill(
        labels: modes.map((m) => m.label).toList(),
        selectedIndex: modes.indexOf(mode),
        onSelected: (i) {
          final nextMode = modes[i];
          ref.read(leaderboardModeProvider.notifier).state = nextMode;
          final band = ref.read(leaderboardSelectedBandProvider);
          switch (nextMode) {
            case LeaderboardMode.daily:
              ref.read(dailySyncServiceProvider).syncPendingSubmissions();
              ref.invalidate(leaderboardEntriesProvider(band));
            case LeaderboardMode.blitz:
              ref.invalidate(
                  challengeEntriesProvider((mode: 'blitz', band: band)));
            case LeaderboardMode.marathon:
              ref.invalidate(
                  challengeEntriesProvider((mode: 'marathon', band: band)));
            case LeaderboardMode.allTime:
              ref.invalidate(allTimeEntriesProvider);
          }
        },
      ),
    );
  }
}

/// Selector tab band horizontal â€” ChunkyButton sentral per item.
class _BandTabsSelector extends ConsumerWidget {
  const _BandTabsSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bandsAsync = ref.watch(levelBandsConfigProvider);
    final selectedBand = ref.watch(leaderboardSelectedBandProvider);

    return bandsAsync.when(
      loading: () => const SizedBox(height: 40),
      error: (err, stack) => const SizedBox.shrink(),
      data: (config) {
        final bands = config.bands;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: bands.map((band) {
              final isSelected = band.id == selectedBand;
              final bandLabel = band.displayName;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChunkyButton(
                  onPressed: () {
                    ref.read(leaderboardSelectedBandProvider.notifier).state =
                        band.id;
                  },
                  backgroundColor: isSelected
                      ? AppTheme.colorWoodMedium
                      : AppTheme.colorVanillaCard,
                  borderColor: isSelected
                      ? AppTheme.colorWoodDark
                      : AppTheme.darkBorder,
                  shadowColor: isSelected
                      ? AppTheme.colorWoodDark
                      : AppTheme.darkBorder,
                  borderWidth: AppTokens.borderWidthDefault,
                  borderRadius: AppTokens.radiusPill,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Text(
                    bandLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppTheme.colorWoodDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// State saat papan peringkat terkunci karena user belum login atau belum memiliki username.
class LeaderboardLockedView extends ConsumerWidget {
  const LeaderboardLockedView({super.key, required this.accountState});

  final AccountState accountState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = accountState.isGuest;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.colorSandyCanvas,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: ChunkyButton(
                    onPressed: () => context.go('/'),
                    backgroundColor: AppTheme.colorVanillaCard,
                    borderColor: AppTheme.darkBorder,
                    shadowColor: AppTheme.darkBorder,
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      AppIcons.back,
                      size: 20,
                      color: AppTheme.colorWoodDark,
                    ),
                  ),
                ),
                const Spacer(),
                ChunkyCard(
                  variant: ChunkyCardVariant.vanillaSoft,
                  padding: const EdgeInsets.fromLTRB(26, 40, 26, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.trophy,
                        size: 54,
                        color: Color(0xFFD48B00),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Papan Peringkat Terkunci',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.colorEspresso,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isGuest
                            ? 'Hubungkan akunmu dan buat username unik untuk melihat ranking dan bersaing dengan pemain lain.'
                            : 'Kamu perlu menetapkan username unik (minimal 4 karakter) sebelum dapat melihat dan bersaing di papan peringkat.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.colorTaupe,
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (isGuest) ...[
                        ChunkyButton(
                          onPressed: () async {
                            final res = await ref
                                .read(accountStatusProvider.notifier)
                                .signInWithGoogle();
                            if (res is RepoSuccess<AccountState> &&
                                context.mounted) {
                              await handlePostSignInFlow(context, ref,
                                  accountState: res.value);
                            }
                          },
                          backgroundColor: AppTheme.colorSage,
                          borderColor: const Color(0xFF43733A),
                          shadowColor: const Color(0xFF43733A),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(AppIcons.profile,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Masuk dengan Google',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ChunkyButton(
                          onPressed: () async {
                            final res = await ref
                                .read(accountStatusProvider.notifier)
                                .signInAnonymously();
                            if (res is RepoSuccess<AccountState> &&
                                context.mounted) {
                              await handlePostSignInFlow(context, ref,
                                  accountState: res.value);
                            }
                          },
                          backgroundColor: AppTheme.colorWoodMedium,
                          borderColor: AppTheme.colorWoodDark,
                          shadowColor: AppTheme.colorWoodDark,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(AppIcons.cloudSync,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Masuk Cepat & Buat Username',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ChunkyButton(
                          onPressed: () => showSetUsernameDialog(context),
                          backgroundColor: AppTheme.colorSage,
                          borderColor: const Color(0xFF43733A),
                          shadowColor: const Color(0xFF43733A),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 24,
                          ),
                          child: const Text(
                            'Buat Username Sekarang',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading view
class LeaderboardLoadingView extends StatelessWidget {
  const LeaderboardLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.colorWoodMedium),
    );
  }
}

/// Error view dengan tombol coba lagi dan pesan dinamis informatif
class LeaderboardErrorView extends StatelessWidget {
  const LeaderboardErrorView({
    super.key,
    this.error,
    required this.onRetry,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error != null
        ? FirebaseErrorMapper.map(
            error!,
            defaultMessage:
                'Gagal memuat papan peringkat. Silakan periksa koneksi atau coba lagi nanti.',
          )
        : 'Periksa koneksi internetmu dan coba kembali.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.colorTaupe,
            ),
            const SizedBox(height: 12),
            Text(
              'Gagal Memuat Papan Peringkat',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.colorEspresso,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.colorTaupe,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ChunkyButton(
              onPressed: onRetry,
              backgroundColor: AppTheme.colorWoodMedium,
              borderColor: AppTheme.colorWoodDark,
              shadowColor: AppTheme.colorWoodDark,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tampilan daftar skor leaderboard â€” mendukung mode daily, blitz, marathon, dan all-time dengan Podium 3 Besar
class LeaderboardListView extends StatelessWidget {
  const LeaderboardListView({
    super.key,
    required this.entries,
    required this.mode,
    required this.onPlayerTap,
  });

  final List<LeaderboardEntry> entries;
  final LeaderboardMode mode;
  final ValueChanged<LeaderboardEntry> onPlayerTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      final (emptyTitle, emptySubtitle) = switch (mode) {
        LeaderboardMode.daily => (
            'Belum Ada Skor Hari Ini',
            'Jadilah petualang pertama yang menaklukkan tantangan hari ini!',
          ),
        LeaderboardMode.blitz => (
            'Belum Ada Rekor Speed Blitz',
            'Pecahkan rekor kecepatan 60 detik di zona ini!',
          ),
        LeaderboardMode.marathon => (
            'Belum Ada Rekor Math Marathon',
            'Buktikan ketahanan fokusmu dan raih streak tertinggi!',
          ),
        LeaderboardMode.allTime => (
            'Belum Ada Pemain',
            'Selesaikan tantangan untuk mencatat rekor skor all-time!',
          ),
      };

      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      AppIcons.trophy,
                      size: 48,
                      color: Color(0xFFDECFA8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      emptyTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.colorEspresso,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emptySubtitle,
                      style: const TextStyle(
                          color: AppTheme.colorTaupe, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final podiumEntries = entries.take(3).toList();
    final remainingEntries = entries.skip(3).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 1. Podium 3 Besar (Emas, Perak, Perunggu)
        SliverToBoxAdapter(
          child: LeaderboardPodium(
            entries: podiumEntries,
            mode: mode,
            onPlayerTap: onPlayerTap,
          ),
        ),

        // 2. Daftar Peringkat 4+ (Cardless Clean Rows)
        if (remainingEntries.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: remainingEntries.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.colorWoodDivider,
                indent: 52,
                endIndent: 4,
              ),
              itemBuilder: (context, index) {
                final entry = remainingEntries[index];
                return _LeaderboardRowItem(
                  entry: entry,
                  mode: mode,
                  onTap: () => onPlayerTap(entry),
                );
              },
            ),
          )
        else
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
      ],
    );
  }
}

class _LeaderboardRowItem extends StatelessWidget {
  const _LeaderboardRowItem({
    required this.entry,
    required this.mode,
    required this.onTap,
  });

  final LeaderboardEntry entry;
  final LeaderboardMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (rankColor, rankBg) = switch (entry.rank) {
      1 => (const Color(0xFF7D5700), const Color(0xFFFFE082)), // Emas
      2 => (const Color(0xFF424242), const Color(0xFFE0E0E0)), // Perak
      3 => (const Color(0xFF5D3A1A), const Color(0xFFFFCCBC)), // Perunggu
      _ => (AppTheme.colorWoodDark, AppTheme.colorSandyCanvas),
    };

    // Skor yang ditampilkan berbeda per mode
    final scoreLabel = switch (mode) {
      LeaderboardMode.daily => '${entry.correctCount}/12',
      LeaderboardMode.blitz => '${entry.totalScore} pts',
      LeaderboardMode.marathon => '${entry.totalScore} pts',
      LeaderboardMode.allTime => '${entry.totalScore} pts',
    };

    final scoreColor = switch (mode) {
      LeaderboardMode.daily => AppTheme.colorSage,
      LeaderboardMode.blitz => AppTheme.colorCoral,
      LeaderboardMode.marathon => const Color(0xFFE65100),
      LeaderboardMode.allTime => AppTheme.colorCoral,
    };

    // Sub-info berbeda per mode
    final subInfo = switch (mode) {
      LeaderboardMode.daily => 'Waktu: ${entry.formattedTime}',
      LeaderboardMode.blitz => '\u{26A1} ${entry.correctCount} Soal (60s)',
      LeaderboardMode.marathon => '\u{1F525} Streak ${entry.streak ?? 0} Soal',
      LeaderboardMode.allTime => 'Total Skor',
    };

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: entry.isCurrentPlayer
              ? AppTheme.colorWoodPlank
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          border: entry.isCurrentPlayer
              ? Border.all(
                  color: AppTheme.colorWoodMedium,
                  width: AppTokens.borderWidthSubtle,
                )
              : null,
        ),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: rankBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.colorWoodMedium,
                  width: AppTokens.borderWidthSubtle,
                ),
              ),
              child: Center(
                child: Text(
                  '${entry.rank}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: rankColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Avatar (Preset image or initial letter)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.colorWoodPlank,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.colorWoodMedium,
                  width: AppTokens.borderWidthSubtle,
                ),
              ),
              child: AppAssets.avatarPath(entry.avatarId) != null
                  ? ClipOval(
                      child: Image.asset(
                        AppAssets.avatarPath(entry.avatarId)!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        entry.username.isNotEmpty
                            ? entry.username[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: AppTheme.colorEspresso,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),

            // Username & Player Indicator
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '@${entry.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: entry.isCurrentPlayer
                                ? FontWeight.w900
                                : FontWeight.w800,
                            color: AppTheme.colorEspresso,
                          ),
                        ),
                      ),
                      if (entry.isCurrentPlayer) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.colorWoodDark,
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusPill),
                          ),
                          child: const Text(
                            'Kamu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subInfo,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colorTaupe,
                    ),
                  ),
                ],
              ),
            ),

            // Skor Utama (dinamis per mode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(
                  color: scoreColor.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                scoreLabel,
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}