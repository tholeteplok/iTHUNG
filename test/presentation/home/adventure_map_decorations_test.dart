import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathmo_app/core/theme/app_icons.dart';
import 'package:mathmo_app/core/theme/app_tokens.dart';
import 'package:mathmo_app/domain/models/session_result.dart';
import 'package:mathmo_app/domain/repositories/repo_result.dart';
import 'package:mathmo_app/domain/repositories/session_repository.dart';
import 'package:mathmo_app/presentation/game/providers/game_dependencies_provider.dart';
import 'package:mathmo_app/presentation/home/providers/level_stars_provider.dart';
import 'package:mathmo_app/presentation/home/widgets/avatar_callout_pin.dart';
import 'package:mathmo_app/presentation/home/widgets/biome_props.dart';
import 'package:mathmo_app/presentation/home/widgets/level_node.dart';
import 'package:mathmo_app/presentation/home/widgets/milestone_chest_node.dart';

class _FakeSessionRepository implements SessionRepository {
  _FakeSessionRepository(this.sessions);
  final List<SessionResult> sessions;

  @override
  Future<RepoResult<void>> saveSession(SessionResult result) async {
    return const RepoSuccess(null);
  }

  @override
  Future<RepoResult<List<SessionResult>>> getRecentSessions({
    int limit = 20,
  }) async {
    return RepoSuccess(sessions);
  }

  @override
  Future<RepoResult<void>> clearAll() async {
    sessions.clear();
    return const RepoSuccess(null);
  }
}

SessionResult _createSession({
  required int level,
  required double accuracy,
}) {
  return SessionResult(
    sessionId: 'test_s_$level',
    mode: GameMode.normal,
    startedAt: DateTime(2026, 9, 8, 10, 0),
    endedAt: DateTime(2026, 9, 8, 10, 2),
    levelReached: level,
    rounds: const [],
    totalScore: 100,
    accuracy: accuracy,
    avgResponseTimeMs: 1200,
    bestStreak: 5,
    xpEarned: 25,
    xpBreakdown: XpBreakdown.zero,
  );
}

void main() {
  group('Biome Architecture (Opsi A)', () {
    test('biomeForLevel maps correctly across all 5 Level Bands', () {
      expect(biomeForLevel(1), equals(IthungBiome.meadow));
      expect(biomeForLevel(5), equals(IthungBiome.meadow));

      expect(biomeForLevel(6), equals(IthungBiome.canyon));
      expect(biomeForLevel(15), equals(IthungBiome.canyon));

      expect(biomeForLevel(16), equals(IthungBiome.ridge));
      expect(biomeForLevel(30), equals(IthungBiome.ridge));

      expect(biomeForLevel(31), equals(IthungBiome.twilight));
      expect(biomeForLevel(50), equals(IthungBiome.twilight));

      expect(biomeForLevel(51), equals(IthungBiome.highland));
      expect(biomeForLevel(75), equals(IthungBiome.highland));

      expect(biomeForLevel(76), equals(IthungBiome.frost));
      expect(biomeForLevel(100), equals(IthungBiome.frost));

      expect(biomeForLevel(101), equals(IthungBiome.cosmic));
    });

    testWidgets('BiomePropsFactory renders meadow props for level 1', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BiomePropsFactory(level: 1, isLeftSide: true),
          ),
        ),
      );

      expect(find.byType(MeadowBushWithFlowers), findsOneWidget);
    });

    testWidgets('BiomePropsFactory renders canyon props for level 6', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BiomePropsFactory(level: 6, isLeftSide: true),
          ),
        ),
      );

      expect(find.byType(CanyonPricklyPear), findsOneWidget);
    });
  });

  group('Milestone Chest Node & Dialog', () {
    testWidgets('Tapping MilestoneChestNode opens MilestoneRewardDialog with XP preview', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MilestoneChestNode(
              level: 5,
              isUnlocked: true,
              xpReward: 250,
            ),
          ),
        ),
      );

      expect(find.byType(MilestoneChestNode), findsOneWidget);
      expect(find.byType(Image), findsWidgets);

      // Tap chest to open dialog
      await tester.tap(find.byType(MilestoneChestNode));
      await tester.pumpAndSettle();

      expect(find.byType(MilestoneRewardDialog), findsOneWidget);
      expect(find.text('Peti Harta Milestone!'), findsOneWidget);
      expect(find.text('+250 Bonus XP'), findsOneWidget);

      // Tap action button to close dialog
      await tester.tap(find.text('Luar Biasa!'));
      await tester.pumpAndSettle();

      expect(find.byType(MilestoneRewardDialog), findsNothing);
    });
  });

  group('Avatar Callout Pin', () {
    testWidgets('Renders floating balloon with avatar letter and label', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarCalloutPin(
              avatarLetter: 'M',
              label: 'Mulai di Sini!',
            ),
          ),
        ),
      );

      expect(find.text('M'), findsOneWidget);
      expect(find.text('Mulai di Sini!'), findsOneWidget);
    });
  });

  group('Level Stars Calculation & LevelNode Stars', () {
    test('levelStarsProvider calculates 1, 2, and 3 stars based on session accuracy', () async {
      final fakeSessions = [
        _createSession(level: 1, accuracy: 0.95), // >= 0.9 -> 3 stars
        _createSession(level: 2, accuracy: 0.72), // >= 0.7 -> 2 stars
        _createSession(level: 3, accuracy: 0.50), // < 0.7 -> 1 star
      ];

      final container = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(
            _FakeSessionRepository(fakeSessions),
          ),
        ],
      );
      addTearDown(container.dispose);

      final stars = await container.read(levelStarsProvider.future);
      expect(stars[1], equals(3));
      expect(stars[2], equals(2));
      expect(stars[3], equals(1));
    });

    testWidgets('LevelNode completed renders 3 stars when starCount is 3', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelNode(
              level: 1,
              status: LevelNodeStatus.completed,
              starCount: 3,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(AppIcons.starFilled), findsNWidgets(3));
      expect(find.byIcon(AppIcons.starEmpty), findsNothing);
    });

    testWidgets(
      'LevelNode active renders woodTokenPlay and Level label, triggers onTap',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LevelNode(
                level: 4,
                status: LevelNodeStatus.active,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Level 4'), findsOneWidget);

        final imageFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == AppAssets.woodTokenPlay,
        );
        expect(imageFinder, findsOneWidget);

        await tester.tap(imageFinder);
        await tester.pump();
        expect(tapped, isTrue);
      },
    );
  });
}
