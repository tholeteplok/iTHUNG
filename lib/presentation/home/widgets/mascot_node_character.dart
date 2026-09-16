import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Karakter Maskot 2D Full-body yang berdiri di atas level aktif pada peta petualangan.
///
/// Fitur:
/// - Siklus 3 pose statis: Idle (santai), Think (berpikir), Cheer (gembira).
/// - Pergantian pose otomatis secara berkala dengan transisi fade & scale halus.
/// - Balon ucapan (speech bubble) dinamis bertema Cozy Woodwork yang menyemangati pemain.
/// - Animasi idle bounce (napas/mengapung lembut).
/// - Tap interaktif untuk memulai petualangan level aktif.
/// - Dioptimalkan dengan `RepaintBoundary` agar tidak merepaint kanvas latar belakang peta.
class MascotNodeCharacter extends StatefulWidget {
  const MascotNodeCharacter({
    super.key,
    required this.level,
    this.scale = 1.0,
    this.onTap,
    this.customSpeech,
    this.avatarId,
    this.avatarLetter = 'i',
  });

  /// Nomor level aktif saat ini.
  final int level;

  /// Faktor skala perspektif lereng gunung (0.78 - 1.25).
  final double scale;

  /// Aksi saat karakter atau balon ucapan di-tap.
  final VoidCallback? onTap;

  /// Teks balon ucapan khusus (opsional).
  final String? customSpeech;

  /// ID Avatar yang dipilih pemain.
  final String? avatarId;

  /// Inisial huruf profil.
  final String avatarLetter;

  @override
  State<MascotNodeCharacter> createState() => _MascotNodeCharacterState();
}

class _MascotNodeCharacterState extends State<MascotNodeCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _squashXAnimation;
  late final Animation<double> _stretchYAnimation;
  late final Animation<double> _swayAnimation;
  late final Animation<double> _shadowScaleAnimation;
  late final Animation<double> _shadowOpacityAnimation;

  late final AnimationController _popController;
  late final Animation<double> _popScaleAnimation;
  Timer? _poseTimer;

  int _currentPoseIndex = 0;
  int _speechIndex = 0;

  static const List<String> _speechPhrases = [
    'Siap berpetualang?',
    'Ayo taklukkan level ini!',
    'Fokus & teliti ya!',
    'Yuk, kita pecahkan!',
    'Kamu pasti bisa!',
  ];

  @override
  void initState() {
    super.initState();

    // 1. Siklus Napas & Mengapung Halus Organik (2400ms Cubic - 60/120 FPS Buttery Smooth)
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    final breathCurve = CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOutCubic,
    );

    // Translasi vertikal lembut (mengapung santai tanpa sentakan)
    _floatAnimation = Tween<double>(begin: 0.0, end: -5.0).animate(breathCurve);

    // Squash & Stretch mikro: deformasi volumetrik elastis alami
    _squashXAnimation =
        Tween<double>(begin: 1.015, end: 0.988).animate(breathCurve);
    _stretchYAnimation =
        Tween<double>(begin: 0.988, end: 1.018).animate(breathCurve);

    // Kemiringan mikro (tilt/sway) organik sangat halus saat bernapas (±1 derajat)
    _swayAnimation =
        Tween<double>(begin: -0.018, end: 0.018).animate(breathCurve);

    // Bayangan lantai bereaksi dinamis terhadap elevasi
    _shadowScaleAnimation =
        Tween<double>(begin: 1.0, end: 0.88).animate(breathCurve);
    _shadowOpacityAnimation =
        Tween<double>(begin: 0.24, end: 0.15).animate(breathCurve);

    // 2. Kontroler Tactile Pop saat di-tap (Spring bounce)
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _popScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.97)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.97, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
    ]).animate(_popController);

    // Siklus pergantian pose setiap 3.5 detik
    _poseTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted) return;
      setState(() {
        _currentPoseIndex = (_currentPoseIndex + 1) % AppAssets.characterAvatar7Poses.length;
        _speechIndex = (_speechIndex + 1) % _speechPhrases.length;
      });
    });
  }

  @override
  void dispose() {
    _poseTimer?.cancel();
    _breathController.dispose();
    _popController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Saat di-tap, langsung switch ke pose cheer gembira & trigger pop bounce
    _popController.forward(from: 0.0);
    setState(() {
      _currentPoseIndex = 2; // Cheer pose
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final clampedScale = widget.scale.clamp(0.80, 1.25);
    final characterHeight = 114.0 * clampedScale;
    final currentSprite = AppAssets.characterAvatar7Poses[_currentPoseIndex];
    final currentText = widget.customSpeech ?? _speechPhrases[_speechIndex];

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathController, _popController]),
        builder: (context, child) {
          final totalScale = _popScaleAnimation.value;
          return GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Balon Ucapan (Speech Bubble) dengan elevasi teredam
                Transform.translate(
                  offset: Offset(0, _floatAnimation.value * 0.45),
                  child: _buildSpeechBubble(context, currentText, clampedScale),
                ),

                const SizedBox(height: 2),

                // 2. Karakter 2D Sprite (Squash & Stretch + Floating + Subtle Tilt + Tap Pop)
                Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: Transform.rotate(
                    angle: _swayAnimation.value,
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scaleX: _squashXAnimation.value * totalScale,
                      scaleY: _stretchYAnimation.value * totalScale,
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: characterHeight,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            currentSprite,
                            key: ValueKey<String>(currentSprite),
                            height: characterHeight,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Bayangan Pijakan Kaki Karakter (Ground Shadow) - Reaktif terhadap Elevasi & Tap
                Transform.scale(
                  scaleX: _shadowScaleAnimation.value * (1.0 + (totalScale - 1.0) * 0.5),
                  scaleY: _shadowScaleAnimation.value,
                  child: Container(
                    width: 57.0 * clampedScale,
                    height: 10.0 * clampedScale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.colorWoodDark.withValues(
                            alpha: _shadowOpacityAnimation.value,
                          ),
                          blurRadius: (5.0 * clampedScale) / _shadowScaleAnimation.value,
                          offset: Offset(0, 2.0 * clampedScale),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Membangun Balon Ucapan dengan ekor penunjuk ke arah kepala karakter.
  Widget _buildSpeechBubble(
    BuildContext context,
    String text,
    double scale,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: (16.0 * scale).clamp(12.0, 22.0),
            vertical: (7.5 * scale).clamp(6.0, 12.0),
          ),
          decoration: BoxDecoration(
            color: AppTheme.colorTranslucentSurface,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(
              color: AppTheme.colorTranslucentBorder,
              width: 1.5,
            ),
            boxShadow: ChunkyShadow.container(AppTheme.colorWoodDark),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon kecil pensil/buku atau bintang math
              Icon(
                Icons.auto_awesome_rounded,
                size: (15.0 * scale).clamp(13.0, 18.0),
                color: AppTheme.colorHoney,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    text,
                    key: ValueKey<String>(text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                      fontSize: (14.0 * scale).clamp(12.0, 16.0),
                      fontWeight: FontWeight.w800,
                      color: AppTheme.colorEspresso,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Ekor balon ucapan
        CustomPaint(
          size: Size(12 * scale, 6 * scale),
          painter: const _BubbleTailPainter(
            fillColor: AppTheme.colorTranslucentSurface,
            borderColor: AppTheme.colorTranslucentBorder,
            strokeWidth: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Painter segitiga kecil untuk ekor balon ucapan.
class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({
    required this.fillColor,
    required this.borderColor,
    this.strokeWidth = 1.5,
  });

  final Color fillColor;
  final Color borderColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, fillPaint);

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.strokeWidth != strokeWidth;
}