import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Spanduk pita petualang (*Adventure Ribbon Banner*) untuk menampilkan zona aktif.
///
/// Mengadopsi estetika pita peta penjelajah tanpa tombol panah navigasi,
/// dirancang untuk navigasi berbasis gesture swipe.
class AdventureRibbonBanner extends StatelessWidget {
  const AdventureRibbonBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        painter: const _RibbonBannerPainter(),
        child: Container(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Baris Judul & Ikon Bioma
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headerTitleStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.colorEspresso,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Subtitle Zona & Level
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorTaupe,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter untuk menggambar sayap pita petualang di sisi kiri dan kanan banner utama.
class _RibbonBannerPainter extends CustomPainter {
  const _RibbonBannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    const double wingW = 16.0; // Lebar sayap ekor pita
    const double foldH = 6.0; // Tinggi lipatan bawah pita
    const double notchD = 6.0; // Kedalaman takik ekor burung pita

    final paintBg = Paint()
      ..color = AppTheme.colorTranslucentSurface
      ..style = PaintingStyle.fill;

    final paintBorder = Paint()
      ..color = AppTheme.colorTranslucentBorderFocus
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFold = Paint()
      ..color = AppTheme.colorWoodMedium.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // 1. Gambar sayap kiri (Left Ribbon Wing with fishtail notch)
    final leftWingPath = Path()
      ..moveTo(4, foldH)
      ..lineTo(wingW, foldH)
      ..lineTo(wingW, h - foldH)
      ..lineTo(4, h - foldH)
      ..lineTo(4 + notchD, (h - foldH + foldH) / 2)
      ..close();

    canvas.drawPath(leftWingPath, paintBg);
    canvas.drawPath(leftWingPath, paintBorder);

    // Lipatan bayangan kiri (fold triangle)
    final leftFoldPath = Path()
      ..moveTo(wingW, h - foldH)
      ..lineTo(wingW + 4, h - foldH)
      ..lineTo(wingW, h)
      ..close();
    canvas.drawPath(leftFoldPath, paintFold);

    // 2. Gambar sayap kanan (Right Ribbon Wing with fishtail notch)
    final rightWingPath = Path()
      ..moveTo(w - 4, foldH)
      ..lineTo(w - wingW, foldH)
      ..lineTo(w - wingW, h - foldH)
      ..lineTo(w - 4, h - foldH)
      ..lineTo(w - 4 - notchD, (h - foldH + foldH) / 2)
      ..close();

    canvas.drawPath(rightWingPath, paintBg);
    canvas.drawPath(rightWingPath, paintBorder);

    // Lipatan bayangan kanan (fold triangle)
    final rightFoldPath = Path()
      ..moveTo(w - wingW, h - foldH)
      ..lineTo(w - wingW - 4, h - foldH)
      ..lineTo(w - wingW, h)
      ..close();
    canvas.drawPath(rightFoldPath, paintFold);

    // 3. Gambar badan tengah pita (Main Center Ribbon Plaque)
    final centerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(wingW - 2, 0, w - 2 * (wingW - 2), h - 2),
      const Radius.circular(AppTokens.radiusIcon),
    );

    canvas.drawRRect(centerRect, paintBg);
    canvas.drawRRect(centerRect, paintBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
