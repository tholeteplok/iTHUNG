import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/core/services/bgm_service.dart';
import 'package:mathmo_app/core/services/sfx_service.dart';
import 'package:mathmo_app/core/theme/app_theme.dart';
import 'package:mathmo_app/domain/models/player_profile.dart';
import 'package:mathmo_app/presentation/home/providers/player_profile_provider.dart';
import 'package:mathmo_app/presentation/settings/providers/settings_provider.dart';
import 'package:mathmo_app/core/constants/developer_contact.dart';
import 'package:mathmo_app/core/services/external_link_service.dart';
import 'package:mathmo_app/presentation/settings/widgets/settings_screen.dart';

class MockSfxService implements SfxService {
  bool muted = false;
  double vol = 1.0;
  final List<SfxType> playedTypes = [];

  @override
  bool get isMuted => muted;

  @override
  double get volume => vol;

  @override
  Future<void> setMuted(bool mute) async {
    muted = mute;
  }

  @override
  Future<void> setVolume(double volume) async {
    vol = volume.clamp(0.0, 1.0);
  }

  @override
  Future<void> play(SfxType type) async {
    playedTypes.add(type);
  }

  @override
  void dispose() {}
}

class MockBgmService implements BgmService {
  bool muted = false;
  String? track;

  @override
  String? get currentTrack => track;

  @override
  bool get isMuted => muted;

  @override
  Future<void> setMuted(bool mute) async {
    muted = mute;
  }

  @override
  Future<void> toggleMute() async {
    muted = !muted;
  }

  @override
  Future<void> playTrack(String assetPath) async {
    track = assetPath;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  void dispose() {}
}

class FakePlayerProfileNotifier extends PlayerProfileNotifier {
  @override
  FutureOr<PlayerProfile> build() {
    return PlayerProfile(
      playerId: 'test_player',
      currentLevel: 6,
      totalXp: 450,
      streak: const StreakState(currentStreak: 5, freezeTokens: 0),
      confidenceScore: 0,
      createdAt: DateTime(2026, 9, 9),
    );
  }
}

class FakeExternalLinkService extends ExternalLinkService {
  FakeExternalLinkService(this.opened);

  final List<Uri> opened;

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Widget Tests', () {
    late MockSfxService mockSfx;
    late MockBgmService mockBgm;
    late List<Uri> openedLinks;

    setUp(() {
      mockSfx = MockSfxService();
      mockBgm = MockBgmService();
      openedLinks = [];
    });

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          sfxServiceProvider.overrideWithValue(mockSfx),
          bgmServiceProvider.overrideWithValue(mockBgm),
          playerProfileProvider.overrideWith(FakePlayerProfileNotifier.new),
          externalLinkServiceProvider.overrideWithValue(
            FakeExternalLinkService(openedLinks),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SettingsScreen(),
        ),
      );
    }

    testWidgets('renders all settings cards and elements', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify Header: hanya back + judul, tanpa pil streak/XP.
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('5'), findsNothing); // Streak disembunyikan
      expect(find.text('450'), findsNothing); // XP disembunyikan

      // Verify Audio Card
      expect(find.text('Musik & Suara'), findsOneWidget);
      expect(find.text('Musik Latar (BGM)'), findsOneWidget);
      expect(find.text('Efek Suara (SFX)'), findsOneWidget);
      // SFX audition was removed per user request
      expect(find.text('Tes Efek Suara:'), findsNothing);
      expect(find.text('✓ Benar'), findsNothing);

      // Verify Gameplay Card
      expect(find.text('Preferensi Permainan'), findsOneWidget);
      expect(find.text('Getaran Haptik'), findsOneWidget);
      expect(find.text('Animasi Dinamis'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);

      // Verify About Card
      expect(find.text('iTHUNG'), findsOneWidget);
      expect(find.text('Fast Math. Sharp Mind.'), findsOneWidget);
      expect(find.textContaining('v0.1.0'), findsOneWidget);
      expect(find.text('Periksa Update'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(3));
      expect(
        find.text('Aset Audio & SFX: Creative Commons CC0'),
        findsOneWidget,
      );

      // Verify Contact Section
      expect(find.text('Hubungi Developer'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_contact_telegram')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_contact_whatsapp')), findsOneWidget);
    });

    testWidgets('contact buttons open telegram and whatsapp links', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('btn_contact_telegram')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('btn_contact_whatsapp')));
      await tester.pumpAndSettle();

      expect(openedLinks, contains(DeveloperContact.telegramUrl));
      expect(openedLinks, contains(DeveloperContact.whatsappUrl));
    });

    testWidgets('audio toggle switches are rendered and no sliders exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('switch_bgm')), findsOneWidget);
      expect(find.byKey(const Key('switch_sfx')), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
    });
  });
}


