import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/core/theme/app_tokens.dart';
import 'package:mathmo_app/presentation/home/widgets/mascot_node_character.dart';

void main() {
  group('MascotNodeCharacter Widget Tests', () {
    testWidgets('renders initial idle sprite, speech bubble, and triggers onTap', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MascotNodeCharacter(
                level: 3,
                scale: 1.0,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Memastikan balon ucapan ter-render
      expect(find.text('Siap berpetualang?'), findsOneWidget);

      // Memastikan sprite awal (idle) ter-render
      final initialImageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                AppAssets.characterAvatar7Idle,
      );
      expect(initialImageFinder, findsOneWidget);

      // Tap karakter memicu callback
      await tester.tap(find.byType(MascotNodeCharacter));
      await tester.pump();
      expect(tapped, isTrue);

      // Setelah di-tap langsung switch ke Cheer pose
      final cheerImageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                AppAssets.characterAvatar7Cheer,
      );
      expect(cheerImageFinder, findsOneWidget);
    });

    testWidgets('cycles pose and speech text after timer duration', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MascotNodeCharacter(
                level: 5,
                scale: 1.0,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Siap berpetualang?'), findsOneWidget);

      // Majukan waktu 3.6 detik untuk memicu siklus pose ke-2 (Think)
      await tester.pump(const Duration(milliseconds: 3600));
      await tester.pump(const Duration(milliseconds: 350));

      final thinkImageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                AppAssets.characterAvatar7Think,
      );
      expect(thinkImageFinder, findsOneWidget);
      expect(find.text('Ayo taklukkan level ini!'), findsOneWidget);

      // Majukan waktu 3.6 detik lagi untuk memicu siklus pose ke-3 (Cheer)
      await tester.pump(const Duration(milliseconds: 3600));
      await tester.pump(const Duration(milliseconds: 350));

      final cheerImageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                AppAssets.characterAvatar7Cheer,
      );
      expect(cheerImageFinder, findsOneWidget);
    });

    testWidgets('respects customSpeech override', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MascotNodeCharacter(
                level: 1,
                customSpeech: 'Ayo mulai!',
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Ayo mulai!'), findsOneWidget);
    });
  });
}