import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/domain/models/level_band_config.dart';
import 'package:mathmo_app/domain/models/player_profile.dart';
import 'package:mathmo_app/domain/models/profile_stats_aggregate.dart';
import 'package:mathmo_app/domain/models/question.dart';
import 'package:mathmo_app/presentation/game/providers/level_band_theme_provider.dart';
import 'package:mathmo_app/presentation/home/providers/player_profile_provider.dart';
import 'package:mathmo_app/presentation/profile/providers/account_status_provider.dart';
import 'package:mathmo_app/presentation/profile/providers/profile_stats_provider.dart';
import 'package:mathmo_app/presentation/profile/widgets/profile_screen.dart';

class FakePlayerProfileNotifier extends PlayerProfileNotifier {
  FakePlayerProfileNotifier(this._profile);
  final PlayerProfile _profile;

  @override
  Future<PlayerProfile> build() async => _profile;
}

class FakeAccountStatusNotifier extends AccountStatusNotifier {
  FakeAccountStatusNotifier(this._state);
  final AccountState _state;

  @override
  Future<AccountState> build() async => _state;
}

void main() {
  testWidgets('ProfileScreen renders guest mode correctly', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testProfile = PlayerProfile(
      playerId: 'local_user',
      username: null,
      currentLevel: 3,
      totalXp: 120,
      totalScore: 500,
      confidenceScore: 0,
      streak: const StreakState(
        currentStreak: 2,
        freezeTokens: 1,
        longestStreak: 4,
      ),
      createdAt: DateTime.utc(2026, 9, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerProfileProvider.overrideWith(() => FakePlayerProfileNotifier(testProfile)),
          accountStatusProvider.overrideWith(
            () => FakeAccountStatusNotifier(const AccountState(status: AccountStatus.guest)),
          ),
          levelBandsConfigProvider.overrideWith(
            (ref) async => const LevelBandsConfig([
              LevelBand(
                id: 'onboarding',
                levelStart: 1,
                levelEnd: 5,
                operations: [Operation.add],
                digitRange: '1-digit',
                timerBaseSec: 8.0,
                canvasColorHex: '#EFE7CC',
                canvasColorEndHex: '#E5DEC0',
                accentColorHex: '#5B9356',
              ),
              LevelBand(
                id: 'basic',
                levelStart: 6,
                levelEnd: 15,
                operations: [Operation.add],
                digitRange: '1-2-digit',
                timerBaseSec: 6.0,
                canvasColorHex: '#F7ECCB',
                canvasColorEndHex: '#EFE0B9',
                accentColorHex: '#D88D28',
              ),
            ]),
          ),
          profileStatsProvider.overrideWith(
            (ref) async => const ProfileStatsAggregate(
              averageAccuracy: 0.85,
              factsMastered: 14,
            ),
          ),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Profil Petualang'), findsOneWidget);
    expect(find.text('Petualang iTHUNG'), findsOneWidget);
    expect(find.text('Akun Tamu · Main Lokal'), findsOneWidget);
    expect(find.text('Fresh Sprout Meadow'), findsOneWidget);
    expect(find.text('14'), findsOneWidget); // facts mastered
    expect(find.text('4 Hari'), findsOneWidget); // longest streak
    expect(find.text('Masuk dengan Google'), findsOneWidget);
    expect(find.text('Masuk Cepat (Anonim)'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders authenticated user with username', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testProfile = PlayerProfile(
      playerId: 'firebase_user_1',
      username: 'bintang_matematika',
      currentLevel: 8,
      totalXp: 950,
      totalScore: 3200,
      confidenceScore: 1,
      streak: const StreakState(
        currentStreak: 5,
        freezeTokens: 2,
        longestStreak: 12,
      ),
      createdAt: DateTime.utc(2026, 9, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerProfileProvider.overrideWith(() => FakePlayerProfileNotifier(testProfile)),
          accountStatusProvider.overrideWith(
            () => FakeAccountStatusNotifier(
              const AccountState(
                status: AccountStatus.linked,
                userId: 'firebase_user_1',
                username: 'bintang_matematika',
              ),
            ),
          ),
          levelBandsConfigProvider.overrideWith(
            (ref) async => const LevelBandsConfig([
              LevelBand(
                id: 'onboarding',
                levelStart: 1,
                levelEnd: 5,
                operations: [Operation.add],
                digitRange: '1-digit',
                timerBaseSec: 8.0,
                canvasColorHex: '#EFE7CC',
                canvasColorEndHex: '#E5DEC0',
                accentColorHex: '#5B9356',
              ),
              LevelBand(
                id: 'basic',
                levelStart: 6,
                levelEnd: 15,
                operations: [Operation.add],
                digitRange: '1-2-digit',
                timerBaseSec: 6.0,
                canvasColorHex: '#F7ECCB',
                canvasColorEndHex: '#EFE0B9',
                accentColorHex: '#D88D28',
              ),
            ]),
          ),
          profileStatsProvider.overrideWith(
            (ref) async => const ProfileStatsAggregate(
              averageAccuracy: 0.94,
              factsMastered: 45,
            ),
          ),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('@bintang_matematika'), findsOneWidget);
    expect(find.text('Terhubung dengan Google'), findsOneWidget);
    expect(find.text('Golden Sun Canyon'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);
    expect(find.text('12 Hari'), findsOneWidget);
    expect(find.text('Keluar Akun'), findsOneWidget);
  });
}
