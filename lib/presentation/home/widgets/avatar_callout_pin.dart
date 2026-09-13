import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Balon ucapan mengambang di atas level aktif dengan avatar pemain dan teks "Mulai di Sini!".
///
/// Dilengkapi animasi *idle bounce* vertikal halus untuk menarik perhatian pemain
/// tanpa mengganggu keterbacaan peta.
class AvatarCalloutPin extends StatefulWidget {
  const AvatarCalloutPin({
    super.key,
    this.avatarLetter = 'i',
    this.avatarId,
    this.label = 'Mulai di Sini!',
    this.accentColor = const Color(0xFF639922),
    this.onTap,
  });

  final String avatarLetter;
  final String? avatarId;
  final String label;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  State<AvatarCalloutPin> createState() => _AvatarCalloutPinState();
}

class _AvatarCalloutPinState extends State<AvatarCalloutPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Balon Utama (Kartu Semi Transparan Tanpa Bayangan)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.colorTranslucentSurface,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(
                  color: AppTheme.colorTranslucentBorder,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mini Avatar Circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.colorTranslucentBorderFocus,
                        width: AppTokens.borderWidthSubtle,
                      ),
                    ),
                    child: AppAssets.avatarPath(widget.avatarId) != null
                        ? ClipOval(
                            child: Image.asset(
                              AppAssets.avatarPath(widget.avatarId)!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Text(
                              widget.avatarLetter,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  // Teks Label
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily:
                            Theme.of(context).textTheme.bodyMedium?.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.colorEspresso,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Segitiga Ekor Pin (Downward triangle)
            CustomPaint(
              size: const Size(14, 7),
              painter: const _PinTailPainter(
                fillColor: AppTheme.colorTranslucentSurface,
                borderColor: AppTheme.colorTranslucentBorder,
                strokeWidth: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter untuk segitiga penunjuk arah bawah pin.
class _PinTailPainter extends CustomPainter {
  const _PinTailPainter({
    required this.fillColor,
    required this.borderColor,
    required this.strokeWidth,
  });

  final Color fillColor;
  final Color borderColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Gambar garis kiri dan kanan segitiga (tanpa garis atas karena bersatu dengan balon)
    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
