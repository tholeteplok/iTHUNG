import 'dart:developer' as dev;
import 'package:audioplayers/audioplayers.dart';

/// Jenis efek suara (SFX) yang tersedia di aplikasi iTHUNG.
enum SfxType {
  /// Jawaban benar saat gameplay (bright rising chime).
  correct,

  /// Jawaban salah saat gameplay (gentle low thud/woodblock).
  wrong,

  /// Selesai level / naik level (celebratory fanfare).
  levelUp,

  /// Membuka peti harta milestone (magical sparkle sweep).
  chestOpen,

  /// Sentuhan tombol Neobrutalis (tactile pop click).
  tap,

  /// Detak jam reguler 10 detik terakhir tantangan (wood clock tick).
  timerTick,

  /// Detak peringatan mendesak 3 detik terakhir tantangan (high alert tick).
  timerWarning,
}

/// Service terpusat untuk memutar Sound Effects (SFX) berlatensi rendah secara instan.
///
/// Beroperasi terpisah dari [BgmService] agar pemutaran efek suara tidak memotong musik latar.
class SfxService {
  SfxService({
    AudioPlayer? player,
    AudioPlayer? timerPlayer,
  })  : _player = player ?? AudioPlayer(),
        _timerPlayer = timerPlayer ?? AudioPlayer();

  final AudioPlayer _player;
  final AudioPlayer _timerPlayer;
  bool _isMuted = false;
  double _volume = 1.0;

  bool get isMuted => _isMuted;
  double get volume => _volume;

  static const Map<SfxType, String> _sfxPaths = {
    SfxType.correct: 'sounds/sfx/correct.wav',
    SfxType.wrong: 'sounds/sfx/wrong.wav',
    SfxType.levelUp: 'sounds/sfx/level_up.wav',
    SfxType.chestOpen: 'sounds/sfx/chest_open.wav',
    SfxType.tap: 'sounds/sfx/tap.wav',
    SfxType.timerTick: 'sounds/sfx/timer_tick.wav',
    SfxType.timerWarning: 'sounds/sfx/timer_warning.wav',
  };

  /// Memutar sound effect sesuai [type] jika tidak dalam status mute.
  Future<void> play(SfxType type) async {
    if (_isMuted) return;

    final relativePath = _sfxPaths[type];
    if (relativePath == null) return;

    final isTimerSfx =
        type == SfxType.timerTick || type == SfxType.timerWarning;
    final activePlayer = isTimerSfx ? _timerPlayer : _player;

    try {
      await activePlayer.stop();
      await activePlayer.setVolume(_volume);
      await activePlayer.play(
        AssetSource(relativePath),
        mode: PlayerMode.lowLatency,
      );
    } catch (e, st) {
      dev.log(
        'SfxService play error for $type: ',
        error: e,
        stackTrace: st,
        name: 'SfxService',
      );
    }
  }

  /// Mengatur status Mute efek suara.
  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    if (_isMuted) {
      try {
        await _player.stop();
        await _timerPlayer.stop();
      } catch (e) {
        dev.log('SfxService stop error on mute: ', error: e, name: 'SfxService');
      }
    }
  }

  /// Mengatur tingkat volume efek suara (0.0 hingga 1.0).
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_volume);
      await _timerPlayer.setVolume(_volume);
    } catch (e) {
      dev.log('SfxService setVolume error: ', error: e, name: 'SfxService');
    }
  }

  /// Membersihkan resource audio player.
  void dispose() {
    _player.dispose();
    _timerPlayer.dispose();
  }
}
