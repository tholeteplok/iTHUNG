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
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;
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

    // Animasi idle bounce lembut (vertikal)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -5.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

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
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Saat di-tap, langsung switch ke pose cheer gembira
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
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: child,
          );
        },
        child: GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Balon Ucapan (Speech Bubble)
              _buildSpeechBubble(context, currentText, clampedScale),

              const SizedBox(height: 2),

              // 2. Karakter 2D Sprite (3 Pose Bergantian - Skala +50%)
              SizedBox(
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

              // 3. Bayangan Pijakan Kaki Karakter (Ground Shadow - Skala +50%)
              Container(
                width: 57.0 * clampedScale,
                height: 10.0 * clampedScale,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.colorWoodDark.withValues(alpha: 0.28),
                      blurRadius: 5.0 * clampedScale,
                      offset: Offset(0, 2.0 * clampedScale),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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