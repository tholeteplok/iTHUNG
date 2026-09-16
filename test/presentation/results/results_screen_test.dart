import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/core/theme/app_icons.dart';
import 'package:mathmo_app/domain/models/session_result.dart';
import 'package:mathmo_app/presentation/results/widgets/animated_star_rating.dart';
import 'package:mathmo_app/presentation/results/widgets/results_screen.dart';
import 'package:mathmo_app/presentation/shared/widgets/chunky_button.dart';

void main() {
  SessionResult createDummyResult({required double accuracy, int level = 1}) {
    return SessionResult(
      sessionId: 's_test_123',
      mode: GameMode.normal,
      startedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      endedAt: DateTime.now(),
      levelReached: level,
      rounds: const [],
      totalScore: 350,
      accuracy: accuracy,
      avgResponseTimeMs: 1500,
      bestStreak: 5,
      xpEarned: 45,
      xpBreakdown: const XpBreakdown(
        distinctFactsPracticed: 5,
        factsMovedUpABox: 2,
        sessionCompletedBonus: 10,
      ),
    );
  }

  group('AnimatedStarRating Widget Tests', () {
    testWidgets('renders 3 star slots', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnimatedStarRating(starCount: 2, playSfx: false),
            ),
          ),
        ),
      );

      // Verify 3 empty star placeholders
      expect(find.byIcon(AppIcons.starEmpty), findsNWidgets(3));

      // Pump animation
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // Verify 2 filled stars appeared
      expect(find.byIcon(AppIcons.starFilled), findsNWidgets(2));
    });
  });

  group('ResultsScreen 3 Action Buttons Tests', () {
    testWidgets('renders 3 labeled buttons: Home, Ulangi, Lanjut', (tester) async {
      final result = createDummyResult(accuracy: 0.8, level: 3);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResultsScreen(result: result),
          ),
        ),
      );

      // Verify tiered game-tone title (80% = 2 stars) and star rating
      expect(find.text('Level Tuntas!'), findsOneWidget);
      expect(find.byType(AnimatedStarRating), findsOneWidget);

      // Verify 3 ChunkyButtons with labels
      expect(find.byType(ChunkyButton), findsNWidgets(3));
      expect(find.byIcon(AppIcons.home), findsOneWidget);
      expect(find.byIcon(AppIcons.replay), findsOneWidget);
      expect(find.byIcon(AppIcons.nextLevel), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Ulangi'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);

      // Accuracy 80% gives 2 stars -> Next level button should be enabled
      final nextButton = tester.widget<ChunkyButton>(
        find.ancestor(
          of: find.byIcon(AppIcons.nextLevel),
          matching: find.byType(ChunkyButton),
        ),
      );
      expect(nextButton.enabled, isTrue);
      expect(nextButton.onPressed, isNotNull);
    });

    testWidgets('disables Next Level button when accuracy < 50% (0 stars)', (tester) async {
      final result = createDummyResult(accuracy: 0.3, level: 2);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResultsScreen(result: result),
          ),
        ),
      );

      // Next level button must be disabled
      final nextButton = tester.widget<ChunkyButton>(
        find.ancestor(
          of: find.byIcon(AppIcons.nextLevel),
          matching: find.byType(ChunkyButton),
        ),
      );
      expect(nextButton.enabled, isFalse);
      expect(nextButton.onPressed, isNull);
    });
  });

  group('ResultsScreen Replay & Score Delta Display Tests', () {
    testWidgets('shows full score added on first play', (tester) async {
      final result = createDummyResult(accuracy: 0.9, level: 1);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResultsScreen(result: result),
          ),
        ),
      );

      expect(find.text('TOTAL SKOR'), findsOneWidget);
      expect(find.text('350'), findsOneWidget);
      expect(find.text('+350 ditambahkan ke peringkat'), findsOneWidget);
      expect(find.text('★ REKOR BARU! ★'), findsNothing);
    });

    testWidgets(
        'shows REKOR BARU badge and delta score on replay with higher score',
        (tester) async {
      final base = createDummyResult(accuracy: 0.95, level: 1);
      final result = base.copyWith(
        totalScore: 170,
        scoreDelta: 25,
        previousBestScore: 145,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResultsScreen(result: result),
          ),
        ),
      );

      expect(find.text('★ REKOR BARU! ★'), findsOneWidget);
      expect(find.text('170'), findsOneWidget);
      expect(find.text('+25 ditambahkan ke peringkat'), findsOneWidget);
    });

    testWidgets(
        'hides negative delta and shows previous best on replay with lower score',
        (tester) async {
      final base = createDummyResult(accuracy: 0.6, level: 1);
      final result = base.copyWith(
        totalScore: 120,
        scoreDelta: 0,
        previousBestScore: 170,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResultsScreen(result: result),
          ),
        ),
      );

      expect(find.text('★ REKOR BARU! ★'), findsNothing);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('Rekor terbaik: 170'), findsOneWidget);
      // Ensure no negative score delta (e.g. -50) is displayed
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && RegExp(r'-\s*\d+').hasMatch(w.data ?? ''),
        ),
        findsNothing,
      );
    });
  });
}

