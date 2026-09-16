import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/services/sfx_service.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../settings/providers/settings_provider.dart';

/// Fase dalam alur selebrasi bintang dan skor ala referensi Alisa.mp4.
enum CelebrationPhase {
  /// State awal: Background gelap muted dan 3 bintang abu-abu redup (dormant).
  dormant,

  /// Bintang menyala (ignite) sesuai jumlah perolehan (1=tengah, 2=kiri & kanan, 3=semua).
  ignite,

  /// Fusi bintang menyatu ke tengah (jika >= 2) disertai shockwave ring.
  fusion,

  /// Putaran 3D bintang raksasa.
  starSpin,

  /// Ledakan/pecahnya bintang menjadi partikel emas.
  starBurst,

  /// Pengurangan skor sesi dan penambahan total skor (siphon).
  scoreSiphon,

  /// Layar meredup-hitam lalu memutih perlahan sebelum statistik muncul.
  whiteout,

  /// Selesai dan siap bertransisi ke statistik.
  completed,
}

/// Fragmen partikel hasil pecahan bintang emas.
class _StarShard {
  _StarShard({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.color,
    required this.shape,
  });

  final double angle;
  final double speed;
  final double size;
  final double rotationSpeed;
  final Color color;

  /// 0 = segitiga, 1 = lingkaran, 2 = persegi.
  final int shape;
}

/// Widget selebrasi level up dengan dopamine reward loop ala referensi Alisa.mp4:
/// 3 Bintang Abu Dormant -> Menyala Emas Sesuai Jumlah -> Fusi & Shockwave -> Flip 3D -> Pecah -> Tally Skor.
class CelebrationStarBurst extends ConsumerStatefulWidget {
  const CelebrationStarBurst({
    super.key,
    required this.earnedStars,
    required this.sessionScore,
    required this.initialTotalScore,
    required this.onComplete,
    this.onSkip,
    this.zoneAccent = AppTheme.colorHoney,
  });

  /// Jumlah bintang yang diperoleh (1, 2, atau 3).
  final int earnedStars;

  /// Skor yang diperoleh dalam sesi ini.
  final int sessionScore;

  /// Skor total pemain sebelum sesi ini selesai.
  final int initialTotalScore;

  /// Aksen warna zona baru untuk confetti + shockwave.
  final Color zoneAccent;

  /// Dipanggil saat seluruh rangkaian animasi telah rampung secara alami.
  final VoidCallback onComplete;

  /// Dipanggil saat pemain men-tap untuk skip selebrasi.
  final VoidCallback? onSkip;

  @override
  ConsumerState<CelebrationStarBurst> createState() =>
      CelebrationStarBurstState();
}

class CelebrationStarBurstState extends ConsumerState<CelebrationStarBurst>
    with TickerProviderStateMixin {
  CelebrationPhase _phase = CelebrationPhase.dormant;

  // Set index bintang yang aktif menyala (0: kiri, 1: tengah, 2: kanan)
  final Set<int> _ignitedSlots = {};

  // Controllers untuk setiap bintang saat menyala (scale pop & glow)
  late final List<AnimationController> _igniteControllers;
  late final List<Animation<double>> _igniteScales;

  // Controller untuk Fusi / Converge bintang ke tengah
  late final AnimationController _fusionController;
  late final Animation<double> _fusionProgress;

  // Controller untuk Shockwave Ring (Cincin kejut mengembang ala Alisa.mp4)
  late final AnimationController _shockwaveController;
  late final Animation<double> _shockwaveRadius;
  late final Animation<double> _shockwaveOpacity;

  // Controller untuk Spin 3D Bintang Raksasa
  late final AnimationController _spinController;
  late final Animation<double> _spinAngle;
  late final Animation<double> _spinScale;

  // Controller untuk Shatter / Burst Partikel
  late final AnimationController _burstController;
  late final Animation<double> _burstProgress;

  // Controller untuk Score Siphon & Tally Counter
  late final AnimationController _siphonController;
  late final Animation<double> _siphonProgress;

  // Controller untuk Whiteout (gelap → putih perlahan)
  late final AnimationController _whiteoutController;
  late final Animation<double> _whiteoutProgress;

  final List<_StarShard> _shards = [];
  Timer? _activeTimer;
  bool _isSkipped = false;
  int _lastHapticTick = 0;
  bool _shockwaveHold = false;
  bool _dimVisible = false;

  @override
  void initState() {
    super.initState();
    _initShards();
    _initControllers();
    // Fade-in dim agar tidak hard-cut.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _dimVisible = true);
    });
    _startOrchestration();
  }

  void _initShards() {
    // Seed per run agar pola tidak identik setiap kali.
    final random = math.Random();
    final colors = [
      AppTheme.colorHoney,
      const Color(0xFFFFD54F),
      const Color(0xFFFFB300),
      Colors.white,
      widget.zoneAccent,
      widget.zoneAccent.withValues(alpha: 0.85),
    ];

    for (int i = 0; i < 36; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 80 + random.nextDouble() * 200;
      final size = 5 + random.nextDouble() * 11;
      final rotationSpeed = (random.nextDouble() - 0.5) * 8;
      final color = colors[random.nextInt(colors.length)];
      _shards.add(_StarShard(
        angle: angle,
        speed: speed,
        size: size,
        rotationSpeed: rotationSpeed,
        color: color,
        shape: random.nextInt(3),
      ));
    }
  }

  void _initControllers() {
    // 3 Controllers untuk Ignite tiap slot (0: Kiri, 1: Tengah, 2: Kanan)
    _igniteControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      );
    });

    _igniteScales = _igniteControllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.35)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 60,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.35, end: 1.08)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 40,
        ),
      ]).animate(controller);
    }).toList();

    // Controller Fusi Bintang
    _fusionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fusionProgress = CurvedAnimation(
      parent: _fusionController,
      curve: Curves.easeInOutCubic,
    );

    // Controller Shockwave Ring
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shockwaveRadius = Tween<double>(begin: 30.0, end: 320.0).animate(
      CurvedAnimation(
        parent: _shockwaveController,
        curve: Curves.easeOutCubic,
      ),
    );
    _shockwaveOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 0.95),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 80,
      ),
    ]).animate(_shockwaveController);

    // Controller Spin 3D
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _spinAngle = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeInOutBack),
    );
    _spinScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.38)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_spinController);

    // Controller Burst
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _burstProgress = CurvedAnimation(
      parent: _burstController,
      curve: Curves.easeOutQuad,
    );

    // Controller Siphon Tally
    _siphonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _siphonProgress = CurvedAnimation(
      parent: _siphonController,
      curve: Curves.easeInOutCubic,
    );

    // Controller Whiteout: hitam/abu gelap → putih perlahan.
    _whiteoutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _whiteoutProgress = CurvedAnimation(
      parent: _whiteoutController,
      curve: Curves.easeInOut,
    );

    _siphonController.addListener(() {
      if (_phase == CelebrationPhase.scoreSiphon) {
        final currentTick = (_siphonProgress.value * 12).floor();
        if (currentTick != _lastHapticTick) {
          _lastHapticTick = currentTick;
          ref.read(hapticServiceProvider).selectionClick();
        }
      }
    });
  }

  Future<bool> _delay(Duration duration) {
    if (!mounted || _isSkipped) return Future.value(false);
    final completer = Completer<bool>();
    _activeTimer = Timer(duration, () {
      if (!completer.isCompleted) {
        completer.complete(mounted && !_isSkipped);
      }
    });
    return completer.future;
  }

  void _startOrchestration() async {
    if (!mounted) return;

    // FASE 0: State Dormant (3 Bintang Abu Muted Redup)
    setState(() => _phase = CelebrationPhase.dormant);
    final proceedDormant = await _delay(const Duration(milliseconds: 350));
    if (!proceedDormant) return;

    // Tentukan urutan slot yang menyala berdasarkan aturan user:
    // 1 bintang -> slot [1] (tengah)
    // 2 bintang -> slot [0, 2] (kiri, lalu kanan)
    // 3 bintang -> slot [0, 1, 2] (kiri, tengah, kanan)
    final List<int> slotsToIgnite = switch (widget.earnedStars) {
      1 => [1],
      2 => [0, 2],
      _ => [0, 1, 2],
    };

    // FASE 1: The Ignite (Bintang menyala satu per satu menjadi emas)
    setState(() => _phase = CelebrationPhase.ignite);
    for (final slot in slotsToIgnite) {
      if (!mounted || _isSkipped) return;
      setState(() {
        _ignitedSlots.add(slot);
      });
      _igniteControllers[slot].forward(from: 0.0);
      ref.read(sfxServiceProvider).play(SfxType.correct);
      ref.read(hapticServiceProvider).lightImpact();
      final waitNext = await _delay(const Duration(milliseconds: 240));
      if (!waitNext) return;
    }

    final waitBeforeFusion = await _delay(const Duration(milliseconds: 300));
    if (!waitBeforeFusion) return;

    // FASE 2: The Fusion & Shockwave (fanfare puncak di sini)
    setState(() => _phase = CelebrationPhase.fusion);
    if (widget.earnedStars >= 2) {
      // Bintang-bintang meluncur menyatu ke tengah
      await _fusionController.forward();
      if (!mounted || _isSkipped) return;
    }

    // Fanfare level-up tepat saat fusi rampung + shockwave mewarnai canvas.
    ref.read(sfxServiceProvider).play(SfxType.levelUp);
    ref.read(hapticServiceProvider).mediumImpact();
    setState(() => _shockwaveHold = true);
    _shockwaveController.forward(from: 0.0);
    final waitAfterShockwave = await _delay(const Duration(milliseconds: 320));
    if (!waitAfterShockwave) return;
    // Hold 200ms agar ring tidak pop hilang.
    final holdShockwave = await _delay(const Duration(milliseconds: 200));
    if (!holdShockwave) return;
    if (mounted) setState(() => _shockwaveHold = false);

    // FASE 3: Spin 3D Bintang Raksasa
    setState(() => _phase = CelebrationPhase.starSpin);
    await _spinController.forward();
    if (!mounted || _isSkipped) return;

    // FASE 4: Star Shatter / Burst Partikel!
    setState(() => _phase = CelebrationPhase.starBurst);
    ref.read(hapticServiceProvider).heavyImpact();
    _burstController.forward();
    final afterBurst = await _delay(const Duration(milliseconds: 350));
    if (!afterBurst) return;

    // FASE 5: Score Siphon & Rolling Tally
    setState(() => _phase = CelebrationPhase.scoreSiphon);
    await _siphonController.forward();
    if (!mounted || _isSkipped) return;

    // Jeda sejenak untuk membiarkan pemain melihat skor total akhir
    // di atas background hitam/abu gelap.
    final afterSiphon = await _delay(const Duration(milliseconds: 500));
    if (!afterSiphon) return;

    // FASE 6: Whiteout — layar perlahan menjadi putih sebelum result muncul.
    setState(() => _phase = CelebrationPhase.whiteout);
    await _whiteoutController.forward();
    if (!mounted || _isSkipped) return;

    // Tahan putih sejenak agar transisi terbaca bersih.
    final holdWhite = await _delay(const Duration(milliseconds: 250));
    if (!holdWhite) return;

    setState(() => _phase = CelebrationPhase.completed);
    widget.onComplete();
  }

  /// Mempercepat atau melompati selebrasi seketika (Skip)
  void skip() {
    if (_isSkipped) return;
    _isSkipped = true;
    _activeTimer?.cancel();
    _activeTimer = null;
    for (final c in _igniteControllers) {
      c.stop();
    }
    _fusionController.stop();
    _shockwaveController.stop();
    _spinController.stop();
    _burstController.stop();
    _siphonController.stop();
    _whiteoutController.stop();

    ref.read(hapticServiceProvider).lightImpact();
    widget.onSkip?.call();
    widget.onComplete();
  }

  @override
  void dispose() {
    _isSkipped = true;
    _activeTimer?.cancel();
    _activeTimer = null;
    for (final c in _igniteControllers) {
      c.dispose();
    }
    _fusionController.dispose();
    _shockwaveController.dispose();
    _spinController.dispose();
    _burstController.dispose();
    _siphonController.dispose();
    _whiteoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == CelebrationPhase.completed) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: skip,
      // Screen kick: seluruh overlay menyentak 2% tepat saat pecah.
      child: AnimatedBuilder(
        animation: _burstController,
        builder: (context, child) {
          final p = _burstProgress.value;
          final kick = (p > 0 && p < 0.6)
              ? 1.0 + 0.022 * math.sin(math.pi * (p / 0.6))
              : 1.0;
          return Transform.scale(scale: kick, child: child);
        },
        child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Overlay: fade-in gelap, lalu memutih perlahan
          // di fase whiteout sebelum result screen muncul.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _whiteoutController,
              builder: (context, _) {
                final w = _whiteoutProgress.value.clamp(0.0, 1.0);
                final bg = Color.lerp(
                  AppTheme.colorEspresso.withValues(alpha: 0.78),
                  Colors.white,
                  w,
                )!;
                return AnimatedOpacity(
                  opacity: _dimVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: Container(color: bg),
                );
              },
            ),
          ),

          // Gold wash saat fusion → burst: canvas ikut merayakan.
          // Alpha 0.22 (punchy) — sengaja kuat lalu lepas cepat.
          if (_phase == CelebrationPhase.fusion ||
              _phase == CelebrationPhase.starSpin ||
              _phase == CelebrationPhase.starBurst)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: widget.zoneAccent.withValues(alpha: 0.22),
                ),
              ),
            ),

          // Radial wipe: cakram zoneAccent mengembang dari tengah
          // bersamaan dengan shockwave ring — warna baru "menendang" masuk.
          AnimatedBuilder(
            animation: _shockwaveController,
            builder: (context, _) {
              final holding =
                  _shockwaveHold && _shockwaveController.value >= 1.0;
              if (_shockwaveController.value <= 0 ||
                  (_shockwaveController.value >= 1.0 && !holding)) {
                return const SizedBox.shrink();
              }
              final t = _shockwaveController.value;
              // easeOutExpo: meledak cepat di awal, melandai di ujung.
              final eased = t >= 1.0 ? 1.0 : 1 - math.pow(2, -10 * t);
              final wipeSize = 60.0 + eased * 1400.0;
              final wipeOpacity = holding ? 0.30 : 0.45 * (1 - t * 0.5);

              return IgnorePointer(
                child: Container(
                  width: wipeSize,
                  height: wipeSize,
                  decoration: BoxDecoration(
                    color: widget.zoneAccent.withValues(
                      alpha: wipeOpacity.clamp(0.0, 0.5),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),

          // Shockwave Ripple Ring (Cincin kejut mengembang keluar)
          AnimatedBuilder(
            animation: _shockwaveController,
            builder: (context, _) {
              final holding =
                  _shockwaveHold && _shockwaveController.value >= 1.0;
              if (_shockwaveController.value <= 0 ||
                  (_shockwaveController.value >= 1.0 && !holding)) {
                return const SizedBox.shrink();
              }
              final radius = _shockwaveRadius.value;
              final opacity =
                  holding ? 0.35 : _shockwaveOpacity.value;

              return CustomPaint(
                size: Size(radius * 2, radius * 2),
                painter: _ShockwavePainter(
                  radius: radius,
                  opacity: opacity,
                  color: widget.zoneAccent,
                ),
              );
            },
          ),

          // Impact flash: kedip putih 120ms saat bintang pecah.
          // Ini "tendangan" yang dibaca mata sebagai punch.
          AnimatedBuilder(
            animation: _burstController,
            builder: (context, _) {
              final p = _burstProgress.value;
              if (p <= 0 || p >= 0.35) return const SizedBox.shrink();
              final opacity = 0.55 * (1 - p / 0.35);
              return Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.white.withValues(alpha: opacity),
                  ),
                ),
              );
            },
          ),

          // Tombol Skip Elegan di Pojok Kanan Atas
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: skip,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.colorVanillaCard,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(
                        color: AppTheme.colorWoodDark,
                        width: AppTokens.borderWidthDefault,
                      ),
                      boxShadow: ChunkyShadow.container(AppTheme.colorWoodDark),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lewati',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppTheme.colorWoodDark,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.fast_forward_rounded,
                          size: 16,
                          color: AppTheme.colorWoodDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Render Tahapan Bintang & Partikel (memudar saat whiteout).
          AnimatedBuilder(
            animation: _whiteoutController,
            builder: (context, child) => Opacity(
              opacity: 1.0 - _whiteoutProgress.value.clamp(0.0, 1.0),
              child: child,
            ),
            child: Center(
            child: SizedBox(
              width: 340,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Fase Dormant, Ignite, & Fusi Bintang
                  if (_phase == CelebrationPhase.dormant ||
                      _phase == CelebrationPhase.ignite ||
                      _phase == CelebrationPhase.fusion)
                    _buildDormantIgniteAndFusionStars(),

                  // 2. Fase Putaran 3D Bintang Raksasa
                  if (_phase == CelebrationPhase.starSpin)
                    _buildSpinningBigStar(),

                  // 3. Fase Partikel Burst / Shatter
                  if (_phase == CelebrationPhase.starBurst ||
                      _phase == CelebrationPhase.scoreSiphon)
                    _buildBurstShards(),

                  // 4. Skor Pop & Tally Siphon
                  if (_phase == CelebrationPhase.starBurst ||
                      _phase == CelebrationPhase.scoreSiphon)
                    _buildScoreDisplay(),
                ],
              ),
            ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Render 3 slot bintang: dimulai dari dormant (abu muted) lalu menyala (emas) dan menyatu
  Widget _buildDormantIgniteAndFusionStars() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ..._igniteControllers,
        _fusionController,
      ]),
      builder: (context, _) {
        final fuseProgress = _fusionProgress.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Slot 0 (Kiri)
            _buildStarSlot(
              slotIndex: 0,
              baseX: -65.0,
              fuseProgress: fuseProgress,
              baseSize: 52,
            ),

            // Slot 1 (Tengah - lebih besar)
            _buildStarSlot(
              slotIndex: 1,
              baseX: 0.0,
              fuseProgress: fuseProgress,
              baseSize: 66,
            ),

            // Slot 2 (Kanan)
            _buildStarSlot(
              slotIndex: 2,
              baseX: 65.0,
              fuseProgress: fuseProgress,
              baseSize: 52,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStarSlot({
    required int slotIndex,
    required double baseX,
    required double fuseProgress,
    required double baseSize,
  }) {
    final isIgnited = _ignitedSlots.contains(slotIndex);

    // Bintang yang menyala meluncur ke tengah saat fase fusi
    double currentX = baseX;
    double scale = 1.0;
    double opacity = 1.0;

    if (isIgnited) {
      scale = _igniteScales[slotIndex].value;

      // Jika fase fusi aktif: bintang meluncur ke tengah
      if (_phase == CelebrationPhase.fusion) {
        currentX = baseX * (1.0 - fuseProgress);
        // Jika hanya 1 bintang (di tengah), membesar menjadi bintang utama
        if (widget.earnedStars == 1) {
          scale = 1.0 + (0.35 * fuseProgress);
        } else {
          // Bintang samping sedikit mengecil saat melebur ke tengah
          scale = (scale * (1.0 - fuseProgress * 0.2)).clamp(0.0, 1.4);
        }
      }
    } else {
      // Bintang yang tidak didapat: tetap abu-abu lalu memudar halus saat ignite dimulai
      if (_phase == CelebrationPhase.ignite ||
          _phase == CelebrationPhase.fusion) {
        opacity = 0.35;
      }
    }

    return Transform.translate(
      offset: Offset(currentX, 0),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: _buildStarGraphic(
            size: baseSize,
            isIgnited: isIgnited,
          ),
        ),
      ),
    );
  }

  /// Gambar bintang: Abu-abu muted jika dormant, Emas menyala jika ignited
  Widget _buildStarGraphic({
    required double size,
    required bool isIgnited,
  }) {
    if (!isIgnited) {
      // Bintang Dormant (Batu/Abu-abu Muted ala Alisa.mp4)
      return Icon(
        AppIcons.starFilled,
        size: size,
        color: const Color(0xFF635A55),
        shadows: const [
          Shadow(
            color: Color(0xFF2B2523),
            offset: Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      );
    }

    // Bintang Emas Menyala dengan Aura Bercahaya
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.colorHoney.withValues(alpha: 0.55),
            blurRadius: 18,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        AppIcons.starFilled,
        size: size,
        color: AppTheme.colorHoney,
        shadows: const [
          Shadow(
            color: AppTheme.colorWoodDark,
            offset: Offset(0, 3),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  /// Render Bintang Emas Raksasa yang berputar 3D
  Widget _buildSpinningBigStar() {
    return AnimatedBuilder(
      animation: _spinController,
      builder: (context, _) {
        final angle = _spinAngle.value;
        final scale = _spinScale.value;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(angle),
          child: Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.colorHoney.withValues(alpha: 0.60),
                    blurRadius: 38,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                AppIcons.starFilled,
                size: 96,
                color: AppTheme.colorHoney,
                shadows: [
                  Shadow(
                    color: AppTheme.colorWoodDark,
                    offset: Offset(0, 4),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Partikel shatter / burst ledakan bintang
  Widget _buildBurstShards() {
    return AnimatedBuilder(
      animation: _burstController,
      builder: (context, _) {
        final progress = _burstProgress.value;
        if (progress <= 0 || progress >= 1.0) {
          return const SizedBox.shrink();
        }

        return CustomPaint(
          size: const Size(340, 260),
          painter: _BurstPainter(
            progress: progress,
            shards: _shards,
          ),
        );
      },
    );
  }

  /// Render Angka Skor Sesi yang berkurang dan mentransfer ke Total Skor
  Widget _buildScoreDisplay() {
    return AnimatedBuilder(
      animation: Listenable.merge([_burstController, _siphonController]),
      builder: (context, _) {
        final burstVal = _burstProgress.value;
        final siphonVal = _siphonProgress.value;

        final remainingSessionScore =
            ((1.0 - siphonVal) * widget.sessionScore).round();
        final currentTotalScore =
            widget.initialTotalScore + (siphonVal * widget.sessionScore).round();

        final scale = burstVal.clamp(0.0, 1.0);

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.colorVanillaCard,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(
                color: AppTheme.colorWoodDark,
                width: AppTokens.borderWidthWood,
              ),
              boxShadow: ChunkyShadow.container(AppTheme.colorWoodDark),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SKOR DIPEROLEH',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.2,
                    color: AppTheme.colorTaupe,
                  ),
                ),
                const SizedBox(height: 4),
                // Skor Sesi (Berhitung Mundur)
                Text(
                  '+$remainingSessionScore',
                  style: AppTheme.mathNumberStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: remainingSessionScore > 0
                        ? AppTheme.colorHoney
                        : AppTheme.colorSage,
                  ),
                ),
                const Divider(
                  height: 18,
                  thickness: 1.5,
                  color: AppTheme.colorWoodDivider,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TOTAL AKUN: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppTheme.colorWoodDark,
                      ),
                    ),
                    Text(
                      '$currentTotalScore',
                      style: AppTheme.mathNumberStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.colorWoodDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// CustomPainter untuk menggambar gelombang cincin kejut radial (Shockwave Ring) ala Alisa.mp4
class _ShockwavePainter extends CustomPainter {
  _ShockwavePainter({
    required this.radius,
    required this.opacity,
    required this.color,
  });

  final double radius;
  final double opacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, 6.0 * opacity);

    canvas.drawCircle(center, radius, paint);

    // Cincin pudar luar sekunder
    if (radius > 40) {
      final secondaryPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius * 0.85, secondaryPaint);
    }
  }

  @override
  bool shouldRepaint(_ShockwavePainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.opacity != opacity;
}

/// CustomPainter untuk pecahan partikel bintang radial
class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.progress,
    required this.shards,
  });

  final double progress;
  final List<_StarShard> shards;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final shard in shards) {
      final distance = shard.speed * progress;
      final dx = center.dx + math.cos(shard.angle) * distance;
      final dy = center.dy +
          math.sin(shard.angle) * distance +
          (progress * progress * 60);

      final paint = Paint()
        ..color = shard.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(shard.rotationSpeed * progress);

      final halfSize = (shard.size * (1.0 - progress * 0.4)) / 2;
      if (shard.shape == 1) {
        canvas.drawCircle(Offset.zero, halfSize * 0.7, paint);
      } else if (shard.shape == 2) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: halfSize, height: halfSize),
          paint,
        );
      } else {
        final path = Path();
        path.moveTo(0, -halfSize);
        path.lineTo(halfSize, halfSize);
        path.lineTo(-halfSize, halfSize);
        path.close();

        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
