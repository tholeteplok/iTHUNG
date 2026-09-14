import 'package:flutter_test/flutter_test.dart';
import 'package:mathmo_app/core/services/bgm_service.dart';
import 'package:mathmo_app/core/services/sfx_service.dart';
import 'package:mathmo_app/presentation/settings/providers/settings_provider.dart';

class FakeBgmService implements BgmService {
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

class FakeSfxService implements SfxService {
  bool muted = false;
  double vol = 1.0;
  final List<SfxType> played = [];

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
    if (!muted) {
      played.add(type);
    }
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SfxType & SfxService Tests', () {
    test('SfxType contains all expected sound event types', () {
      expect(SfxType.values, contains(SfxType.correct));
      expect(SfxType.values, contains(SfxType.wrong));
      expect(SfxType.values, contains(SfxType.levelUp));
      expect(SfxType.values, contains(SfxType.chestOpen));
      expect(SfxType.values, contains(SfxType.tap));
      expect(SfxType.values, contains(SfxType.timerTick));
      expect(SfxType.values, contains(SfxType.timerWarning));
      expect(SfxType.values.length, equals(7));
    });

    test('AudioSettingsNotifier toggles BGM and SFX state properly', () async {
      final fakeBgm = FakeBgmService();
      final fakeSfx = FakeSfxService();

      final notifier = AudioSettingsNotifier(
        bgmService: fakeBgm,
        sfxService: fakeSfx,
      );

      // Initial state
      expect(notifier.state.bgmMuted, isFalse);
      expect(notifier.state.sfxMuted, isFalse);
      expect(notifier.state.bgmVolume, equals(1.0));
      expect(notifier.state.sfxVolume, equals(1.0));
      expect(notifier.state.hapticEnabled, isTrue);

      // Toggle BGM
      await notifier.toggleBgm();
      expect(notifier.state.bgmMuted, isTrue);
      expect(fakeBgm.muted, isTrue);

      await notifier.toggleBgm();
      expect(notifier.state.bgmMuted, isFalse);
      expect(fakeBgm.muted, isFalse);

      // Toggle SFX
      await notifier.toggleSfx();
      expect(notifier.state.sfxMuted, isTrue);
      expect(fakeSfx.muted, isTrue);

      await notifier.toggleSfx();
      expect(notifier.state.sfxMuted, isFalse);
      expect(fakeSfx.muted, isFalse);

      // Set volume with clamping
      await notifier.setBgmVolume(0.5);
      expect(notifier.state.bgmVolume, equals(0.5));

      await notifier.setSfxVolume(0.75);
      expect(notifier.state.sfxVolume, equals(0.75));
      expect(fakeSfx.vol, equals(0.75));

      // Clamping out of bounds
      await notifier.setSfxVolume(1.5);
      expect(notifier.state.sfxVolume, equals(1.0));
      expect(fakeSfx.vol, equals(1.0));

      await notifier.setSfxVolume(-0.5);
      expect(notifier.state.sfxVolume, equals(0.0));
      expect(fakeSfx.vol, equals(0.0));

      // Toggle Haptic
      notifier.toggleHaptic();
      expect(notifier.state.hapticEnabled, isFalse);
      notifier.toggleHaptic();
      expect(notifier.state.hapticEnabled, isTrue);
    });

    test('FakeSfxService records played sound events when unmuted', () async {
      final fakeSfx = FakeSfxService();

      await fakeSfx.play(SfxType.correct);
      await fakeSfx.play(SfxType.wrong);
      await fakeSfx.play(SfxType.levelUp);
      await fakeSfx.play(SfxType.chestOpen);
      await fakeSfx.play(SfxType.tap);

      expect(fakeSfx.played, equals([
        SfxType.correct,
        SfxType.wrong,
        SfxType.levelUp,
        SfxType.chestOpen,
        SfxType.tap,
      ]));

      // When muted, no sounds should be added
      await fakeSfx.setMuted(true);
      await fakeSfx.play(SfxType.correct);
      expect(fakeSfx.played.length, equals(5));
    });
  });
}
