import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import 'biome_props.dart';

/// CustomPainter untuk menggambar jalur setapak batu berliku (winding stone path)
/// dan kontur bukit neobrutalis di latar belakang peta petualangan.
class AdventureMapPainter extends CustomPainter {
  const AdventureMapPainter({
    required this.nodePositions,
    required this.biome,
    this.borderColor = AppTheme.darkBorder,
  });

  /// Daftar koordinat tengah setiap node level (dari indeks 0 sampai n).
  final List<Offset> nodePositions;

  /// Bioma aktif saat ini untuk menentukan warna batu jalan setapak.
  final IthungBiome biome;

  /// Warna border neobrutalis.
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    // 1. Tentukan warna jalan setapak berdasarkan bioma
    final (pathColor, stoneDashesColor) = _resolvePathColors(biome);

    // 2. Bangun kurva halus (Bézier Path) yang menyambungkan seluruh node
    final path = Path();
    path.moveTo(nodePositions.first.dx, nodePositions.first.dy);

    for (var i = 0; i < nodePositions.length - 1; i++) {
      final p0 = nodePositions[i];
      final p1 = nodePositions[i + 1];
      final midY = (p0.dy + p1.dy) / 2;

      // Cubic Bézier untuk kelokan yang organik dan mulus
      path.cubicTo(
        p0.dx,
        midY,
        p1.dx,
        midY,
        p1.dx,
        p1.dy,
      );
    }

    // 3. Gambar bayangan tebal jalur (chunky neobrutalist drop shadow)
    final shadowPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(0, 4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 4. Gambar border luar jalur
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);

    // 5. Gambar badan jalan setapak (isian)
    final fillPaint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, fillPaint);

    // 6. Gambar batu pijakan (stepping stones / dashed center trail)
    _drawSteppingStones(canvas, path, stoneDashesColor);
  }

  /// Menghitung warna isian jalan dan warna batu pijakan per bioma.
  (Color pathColor, Color stoneColor) _resolvePathColors(IthungBiome biome) {
    return switch (biome) {
      IthungBiome.meadow => (
        const Color(0xFFE2EED0), // Green cobblestone path
        const Color(0xFFB8D992),
      ),
      IthungBiome.canyon => (
        const Color(0xFFFBE4C3), // Sandstone trail
        const Color(0xFFE2B77B),
      ),
      IthungBiome.ridge => (
        const Color(0xFFF7D5CA), // Terracotta stone
        const Color(0xFFDE9682),
      ),
      IthungBiome.twilight => (
        const Color(0xFFECD2E4), // Twilight crystal dust path
        const Color(0xFFC798BC),
      ),
      IthungBiome.highland => (
        const Color(0xFFE4ECD9), // Alpine meadow path
        const Color(0xFFACC296),
      ),
      IthungBiome.frost => (
        const Color(0xFFDFF0F5), // Glacial frost path
        const Color(0xFF9ECBD8),
      ),
      IthungBiome.cosmic => (
        const Color(0xFFDCD7F9), // Obsidian glowing path
        const Color(0xFFABA1E8),
      ),
    };
  }

  /// Menggambar batu-batu pijakan di sepanjang jalur menggunakan PathMetrics.
  void _drawSteppingStones(Canvas canvas, Path path, Color stoneColor) {
    final stonePaint = Paint()
      ..color = stoneColor
      ..style = PaintingStyle.fill;

    final borderStonePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppTokens.borderWidthSubtle;

    for (final metric in path.computeMetrics()) {
      const stepDistance = 24.0;
      var distance = 12.0;

      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          final pos = tangent.position;
          // Gambar batu pijakan bulat neobrutalis
          canvas.drawCircle(pos, 3.5, stonePaint);
          canvas.drawCircle(pos, 3.5, borderStonePaint);
        }
        distance += stepDistance;
      }
    }
  }

  @override
  bool shouldRepaint(covariant AdventureMapPainter oldDelegate) =>
      oldDelegate.nodePositions != nodePositions ||
      oldDelegate.biome != biome ||
      oldDelegate.borderColor != borderColor;
}

/// CustomPainter untuk me-render segmen jalan setapak individual pada setiap baris ListView.
///
/// Menyambung dari baris bawah ([prevOffset]) ke tengah baris saat ini ([currentOffset])
/// dan terus ke baris atas ([nextOffset]) secara mulus tanpa batas keliman.
class WindingPathSegmentPainter extends CustomPainter {
  const WindingPathSegmentPainter({
    required this.currentOffset,
    required this.prevOffset,
    required this.nextOffset,
    required this.hasPrev,
    required this.hasNext,
    required this.biome,
    this.borderColor = AppTheme.darkBorder,
  });

  final double currentOffset;
  final double prevOffset;
  final double nextOffset;
  final bool hasPrev;
  final bool hasNext;
  final IthungBiome biome;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width / 2;
    final currentPos = Offset(midX + currentOffset, size.height / 2);

    final (pathColor, stoneDashesColor) = _resolvePathColors(biome);
    final path = Path();

    if (hasPrev) {
      final prevPos = Offset(midX + (prevOffset + currentOffset) / 2, size.height);
      path.moveTo(prevPos.dx, prevPos.dy);
      path.cubicTo(
        prevPos.dx,
        (prevPos.dy + currentPos.dy) / 2,
        currentPos.dx,
        (prevPos.dy + currentPos.dy) / 2,
        currentPos.dx,
        currentPos.dy,
      );
    } else {
      path.moveTo(currentPos.dx, currentPos.dy);
    }

    if (hasNext) {
      final nextPos = Offset(midX + (currentOffset + nextOffset) / 2, 0);
      path.cubicTo(
        currentPos.dx,
        (currentPos.dy + nextPos.dy) / 2,
        nextPos.dx,
        (currentPos.dy + nextPos.dy) / 2,
        nextPos.dx,
        nextPos.dy,
      );
    }

    // Shadow
    final shadowPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(0, 3.5);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);

    // Fill
    final fillPaint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, fillPaint);

    // Stepping stones
    final stonePaint = Paint()
      ..color = stoneDashesColor
      ..style = PaintingStyle.fill;
    final borderStonePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppTokens.borderWidthSubtle;

    for (final metric in path.computeMetrics()) {
      const stepDistance = 24.0;
      var distance = 10.0;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          final pos = tangent.position;
          canvas.drawCircle(pos, 3.5, stonePaint);
          canvas.drawCircle(pos, 3.5, borderStonePaint);
        }
        distance += stepDistance;
      }
    }
  }

  (Color pathColor, Color stoneColor) _resolvePathColors(IthungBiome biome) {
    return switch (biome) {
      IthungBiome.meadow => (
        const Color(0xFFE2EED0),
        const Color(0xFFB8D992),
      ),
      IthungBiome.canyon => (
        const Color(0xFFFBE4C3),
        const Color(0xFFE2B77B),
      ),
      IthungBiome.ridge => (
        const Color(0xFFF7D5CA),
        const Color(0xFFDE9682),
      ),
      IthungBiome.twilight => (
        const Color(0xFFECD2E4),
        const Color(0xFFC798BC),
      ),
      IthungBiome.highland => (
        const Color(0xFFE4ECD9),
        const Color(0xFFACC296),
      ),
      IthungBiome.frost => (
        const Color(0xFFDFF0F5),
        const Color(0xFF9ECBD8),
      ),
      IthungBiome.cosmic => (
        const Color(0xFFDCD7F9),
        const Color(0xFFABA1E8),
      ),
    };
  }

  @override
  bool shouldRepaint(covariant WindingPathSegmentPainter oldDelegate) =>
      oldDelegate.currentOffset != currentOffset ||
      oldDelegate.prevOffset != prevOffset ||
      oldDelegate.nextOffset != nextOffset ||
      oldDelegate.hasPrev != hasPrev ||
      oldDelegate.hasNext != hasNext ||
      oldDelegate.biome != biome ||
      oldDelegate.borderColor != borderColor;
}

