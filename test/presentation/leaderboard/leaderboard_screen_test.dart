import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/leaderboard_entry.dart';
import 'package:mathmo_app/domain/models/level_band_config.dart';
import 'package:mathmo_app/domain/models/question.dart';
import 'package:mathmo_app/presentation/game/providers/level_band_theme_provider.dart';
import 'package:mathmo_app/presentation/leaderboard/providers/leaderboard_provider.dart';
import 'package:mathmo_app/presentation/leaderboard/widgets/leaderboard_podium.dart';
import 'package:mathmo_app/presentation/leaderboard/widgets/leaderboard_screen.dart';
import 'package:mathmo_app/presentation/profile/providers/account_status_provider.dart';

class FakeAccountStatusNotifier extends AccountStatusNotifier {
  FakeAccountStatusNotifier(this._state);
  final AccountState _state;

  @override
  Future<AccountState> build() async => _state;
}

class FakeLeaderboardEntriesNotifier extends LeaderboardEntriesNotifier {
  FakeLeaderboardEntriesNotifier(this._entries);
  final List<LeaderboardEntry> _entries;

  @override
  FutureOr<List<LeaderboardEntry>> build(String arg) => _entries;
}

class FakeChallengeEntriesNotifier extends ChallengeEntriesNotifier {
  FakeChallengeEntriesNotifier(this._entries);
  final List<LeaderboardEntry> _entries;

  @override
  FutureOr<List<LeaderboardEntry>> build(({String band, String mode}) arg) =>
      _entries;
}

class FakeAllTimeEntriesNotifier extends AllTimeEntriesNotifier {
  FakeAllTimeEntriesNotifier(this._entries);
  final List<LeaderboardEntry> _entries;

  @override
  FutureOr<List<LeaderboardEntry>> build() => _entries;
}

void main() {
  const testBand = LevelBand(
    id: 'basic',
    levelStart: 6,
    levelEnd: 15,
    operations: [Operation.add],
    digitRange: '1-digit',
    timerBaseSec: 6.0,
    canvasColorHex: '#EAF3DE',
    canvasColorEndHex: '#DCEACB',
    accentColorHex: '#639922',
  );

  testWidgets('LeaderboardScreen renders locked view when user is guest',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            () => FakeAccountStatusNotifier(
                const AccountState(status: AccountStatus.guest)),
          ),
        ],
        child: const MaterialApp(
          home: LeaderboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Papan Peringkat Terkunci'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
  });

  testWidgets(
      'LeaderboardScreen renders daily entries and band tabs when logged in',
      (tester) async {
    const mockEntries = [
      LeaderboardEntry(
        rank: 1,
        username: 'juara_satu',
        correctCount: 12,
        totalTimeMs: 19500,
        isCurrentPlayer: false,
      ),
      LeaderboardEntry(
        rank: 2,
        username: 'my_user_test',
        correctCount: 11,
        totalTimeMs: 22100,
        isCurrentPlayer: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            () => FakeAccountStatusNotifier(
              const AccountState(
                status: AccountStatus.linked,
                userId: 'user_123',
                username: 'my_user_test',
              ),
            ),
          ),
          levelBandsConfigProvider.overrideWith(
            (ref) async => const LevelBandsConfig([testBand]),
          ),
          leaderboardSelectedBandProvider.overrideWith((ref) => 'basic'),
          leaderboardEntriesProvider.overrideWith(
            () => FakeLeaderboardEntriesNotifier(mockEntries),
          ),
        ],
        child: const MaterialApp(
          home: LeaderboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Papan Peringkat'), findsOneWidget);
    expect(find.byType(LeaderboardPodium), findsOneWidget);
    expect(find.text('@juara_satu'), findsOneWidget);
    expect(find.text('@my_user_test'), findsOneWidget);
    expect(find.text('12/12'), findsOneWidget);
    expect(find.text('11/12'), findsOneWidget);
    expect(find.text('Kamu'), findsOneWidget);
    expect(find.text('Harian'), findsOneWidget);
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('Maraton'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Golden Sun Canyon'), findsOneWidget);
  });

  testWidgets('LeaderboardScreen renders blitz entries in blitz mode',
      (tester) async {
    const mockBlitzEntries = [
      LeaderboardEntry(
        rank: 1,
        username: 'speed_king',
        correctCount: 25,
        totalTimeMs: 60000,
        totalScore: 3500,
        isCurrentPlayer: false,
      ),
      LeaderboardEntry(
        rank: 2,
        username: 'my_user_test',
        correctCount: 20,
        totalTimeMs: 60000,
        totalScore: 2800,
        isCurrentPlayer: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            () => FakeAccountStatusNotifier(
              const AccountState(
                status: AccountStatus.linked,
                userId: 'user_123',
                username: 'my_user_test',
              ),
            ),
          ),
          levelBandsConfigProvider.overrideWith(
            (ref) async => const LevelBandsConfig([testBand]),
          ),
          leaderboardModeProvider.overrideWith((ref) => LeaderboardMode.blitz),
          leaderboardSelectedBandProvider.overrideWith((ref) => 'basic'),
          challengeEntriesProvider.overrideWith(
            () => FakeChallengeEntriesNotifier(mockBlitzEntries),
          ),
        ],
        child: const MaterialApp(
          home: LeaderboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Papan Peringkat'), findsOneWidget);
    expect(find.byType(LeaderboardPodium), findsOneWidget);
    expect(find.text('@speed_king'), findsOneWidget);
    expect(find.text('@my_user_test'), findsOneWidget);
    expect(find.text('3500 pts'), findsOneWidget);
    expect(find.text('2800 pts'), findsOneWidget);
    expect(find.text('Golden Sun Canyon'), findsOneWidget);
  });

  testWidgets('LeaderboardScreen renders marathon entries in marathon mode',
      (tester) async {
    const mockMarathonEntries = [
      LeaderboardEntry(
        rank: 1,
        username: 'endurance_pro',
        correctCount: 0,
        totalTimeMs: 0,
        totalScore: 4200,
        streak: 35,
        isCurrentPlayer: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            () => FakeAccountStatusNotifier(
              const AccountState(
                status: AccountStatus.linked,
                userId: 'user_123',
                username: 'my_user_test',
              ),
            ),
          ),
          levelBandsConfigProvider.overrideWith(
            (ref) async => const LevelBandsConfig([testBand]),
          ),
          leaderboardModeProvider
              .overrideWith((ref) => LeaderboardMode.marathon),
          leaderboardSelectedBandProvider.overrideWith((ref) => 'basic'),
          challengeEntriesProvider.overrideWith(
            () => FakeChallengeEntriesNotifier(mockMarathonEntries),
          ),
        ],
        child: const MaterialApp(
          home: LeaderboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Papan Peringkat'), findsOneWidget);
    expect(find.byType(LeaderboardPodium), findsOneWidget);
    expect(find.text('@endurance_pro'), findsOneWidget);
    expect(find.text('4200 pts'), findsOneWidget);
    expect(find.text('Golden Sun Canyon'), findsOneWidget);
  });

  testWidgets(
      'LeaderboardScreen renders all-time entries and hides band tabs in allTime mode',
      (tester) async {
    const mockAllTimeEntries = [
      LeaderboardEntry(
        rank: 1,
        username: 'legend_player',
        correctCount: 0,
        totalTimeMs: 0,
        totalScore: 9850,
        isCurrentPlayer: false,
      ),
      LeaderboardEntry(
        rank: 2,
        username: 'my_user_test',
        correctCount: 0,
        totalTimeMs: 0,
        totalScore: 5400,
        isCurrentPlayer: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusProvider.overrideWith(
            () => FakeAccountStatusNotifier(
              const AccountState(
                status: AccountStatus.linked,
                userId: 'user_123',
                username: 'my_user_test',
              ),
            ),
          ),
          levelBandsConfigProvider.overrideWith(
            (ref) async => const LevelBandsConfig([testBand]),
          ),
          leaderboardModeProvider.overrideWith((ref) => LeaderboardMode.allTime),
          allTimeEntriesProvider.overrideWith(
            () => FakeAllTimeEntriesNotifier(mockAllTimeEntries),
          ),
        ],
        child: const MaterialApp(
          home: LeaderboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Papan Peringkat'), findsOneWidget);
    expect(find.byType(LeaderboardPodium), findsOneWidget);
    expect(find.text('@legend_player'), findsOneWidget);
    expect(find.text('@my_user_test'), findsOneWidget);
    expect(find.text('9850 pts'), findsOneWidget);
    expect(find.text('5400 pts'), findsOneWidget);
    expect(find.text('Kamu'), findsOneWidget);
    // Band tabs should NOT be rendered in all-time mode
    expect(find.text('Golden Sun Canyon'), findsNothing);
  });

  group('Optimistic update tests', () {
    test(
        'LeaderboardEntriesNotifier adds and rollbacks optimistic entry with virtual rank',
        () async {
      final container = ProviderContainer(
        overrides: [
          leaderboardEntriesProvider.overrideWith(
            () => FakeLeaderboardEntriesNotifier([
              const LeaderboardEntry(
                rank: 1,
                username: 'alice',
                correctCount: 12,
                totalTimeMs: 20000,
                isCurrentPlayer: false,
              ),
              const LeaderboardEntry(
                rank: 2,
                username: 'bob',
                correctCount: 10,
                totalTimeMs: 15000,
                isCurrentPlayer: false,
              ),
            ]),
          ),
        ],
      );

      // Initial read
      final initial =
          await container.read(leaderboardEntriesProvider('basic').future);
      expect(initial.length, 2);
      expect(initial[0].username, 'alice');
      expect(initial[1].username, 'bob');

      // Add optimistic entry that beats alice
      final notifier =
          container.read(leaderboardEntriesProvider('basic').notifier);
      notifier.addOptimisticEntry(
        const LeaderboardEntry(
          rank: 1,
          username: 'player_me',
          correctCount: 12,
          totalTimeMs: 15000,
          isCurrentPlayer: true,
        ),
      );

      final optimistic =
          container.read(leaderboardEntriesProvider('basic')).value!;
      expect(optimistic.length, 3);
      expect(optimistic[0].username, 'player_me');
      expect(optimistic[0].rank, 1);
      expect(optimistic[1].username, 'alice');
      expect(optimistic[1].rank, 2);
      expect(optimistic[2].username, 'bob');
      expect(optimistic[2].rank, 3);

      // Rollback
      notifier.rollbackOptimisticEntry('player_me');
      final rolledBack =
          container.read(leaderboardEntriesProvider('basic')).value!;
      expect(rolledBack.length, 2);
      expect(rolledBack[0].username, 'alice');
      expect(rolledBack[0].rank, 1);
      expect(rolledBack[1].username, 'bob');
      expect(rolledBack[1].rank, 2);
    });

    test('AllTimeEntriesNotifier adds optimistic score and re-ranks', () async {
      final container = ProviderContainer(
        overrides: [
          allTimeEntriesProvider.overrideWith(
            () => FakeAllTimeEntriesNotifier([
              const LeaderboardEntry(
                rank: 1,
                username: 'top_player',
                correctCount: 0,
                totalTimeMs: 0,
                totalScore: 5000,
                isCurrentPlayer: false,
              ),
              const LeaderboardEntry(
                rank: 2,
                username: 'second_player',
                correctCount: 0,
                totalTimeMs: 0,
                totalScore: 3000,
                isCurrentPlayer: false,
              ),
            ]),
          ),
        ],
      );

      await container.read(allTimeEntriesProvider.future);

      final notifier = container.read(allTimeEntriesProvider.notifier);
      notifier.addOptimisticScore(
        username: 'player_me',
        newTotalScore: 4000,
      );

      final list = container.read(allTimeEntriesProvider).value!;
      expect(list.length, 3);
      expect(list[0].username, 'top_player');
      expect(list[0].rank, 1);
      expect(list[1].username, 'player_me');
      expect(list[1].rank, 2);
      expect(list[1].totalScore, 4000);
      expect(list[2].username, 'second_player');
      expect(list[2].rank, 3);
    });
  });
}