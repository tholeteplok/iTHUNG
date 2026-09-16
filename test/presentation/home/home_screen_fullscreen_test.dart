import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/presentation/home/widgets/floating_bottom_dock.dart';
import 'package:mathmo_app/presentation/home/widgets/home_screen.dart';
import 'package:mathmo_app/presentation/home/widgets/level_node.dart';
import 'package:mathmo_app/presentation/home/widgets/milestone_chest_node.dart';

void main() {
  group('HomeScreen Fullscreen & Stage Configuration', () {
    test('kIthungStages covers all 5 bands with calibrated anchors', () {
      expect(kIthungStages.length, greaterThanOrEqualTo(12));

      // Meadow (Band 1)
      expect(kIthungStages[0].title, equals('Fresh Sprout Meadow'));
      expect(kIthungStages[0].startLevel, equals(1));
      expect(kIthungStages[0].endLevel, equals(5));
      expect(kIthungStages[0].assetPath, contains('meadow_canvas.jpg'));

      // Canyon (Band 2)
      expect(kIthungStages[1].title, equals('Golden Sun Canyon'));
      expect(kIthungStages[1].startLevel, equals(6));
      expect(kIthungStages[1].endLevel, equals(10));
      expect(kIthungStages[1].assetPath, contains('canyon_canvas.jpg'));

      // Ridge (Band 3)
      expect(kIthungStages[3].title, equals('Coral Sunset Ridge'));
      expect(kIthungStages[3].startLevel, equals(16));
      expect(kIthungStages[3].endLevel, equals(20));
      expect(kIthungStages[3].assetPath, contains('ridge_canvas.jpg'));

      // Twilight (Band 4)
      expect(kIthungStages[6].title, equals('Twilight Forest'));
      expect(kIthungStages[6].startLevel, equals(31));
      expect(kIthungStages[6].endLevel, equals(35));
      expect(kIthungStages[6].assetPath, contains('twilight_canvas.jpg'));

      // Highland Wind (Band 5)
      expect(kIthungStages[10].title, equals('Highland Wind'));
      expect(kIthungStages[10].startLevel, equals(51));
      expect(kIthungStages[10].endLevel, equals(55));
      expect(kIthungStages[10].assetPath, contains('Highland_canvas.jpg'));

      // Frost Wind (Band 6)
      expect(kIthungStages[15].title, equals('Frost Wind'));
      expect(kIthungStages[15].startLevel, equals(76));
      expect(kIthungStages[15].endLevel, equals(80));
      expect(kIthungStages[15].assetPath, contains('frost_canvas.jpg'));

      // Calibrated anchors and BGM asset configuration
      for (final stage in kIthungStages) {
        expect(stage.nodeAnchors.length, equals(5));
        expect(stage.nodeAnchors[0], equals(const Offset(265, 1020)));
        expect(stage.nodeAnchors[4], equals(const Offset(265, 450)));
        expect(stage.chestAnchor, equals(const Offset(380, 360)));
        expect(stage.bgmAssetPath, startsWith('assets/sounds/musics/'));
        expect(stage.bgmAssetPath, endsWith('.mp3'));
      }
    });

    test('Perspective scaling rules: foreground nodes are larger than summit nodes', () {
      expect(kStagePerspectiveScales.length, equals(5));
      // Foreground (Level 1) is 1.25x (largest)
      expect(kStagePerspectiveScales[0], equals(1.25));
      // Summit (Level 5) is 0.78x (smallest)
      expect(kStagePerspectiveScales[4], equals(0.78));
      // Strictly descending
      for (var i = 0; i < kStagePerspectiveScales.length - 1; i++) {
        expect(
          kStagePerspectiveScales[i],
          greaterThan(kStagePerspectiveScales[i + 1]),
          reason: 'Node $i must be larger than Node ${i + 1} for 3D depth',
        );
      }
      expect(kMilestoneChestPerspectiveScale, equals(0.80));
    });

    testWidgets('Renders PageView, nodes, and Mute toggle button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(FloatingBottomDock), findsOneWidget);
      expect(find.byType(LevelNode), findsWidgets);
      expect(find.byType(MilestoneChestNode), findsWidgets);

      // Verify Mute toggle button exists in header
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      // Tap mute toggle button
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump();

      // Should now display muted volume icon
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    });
  });
}
