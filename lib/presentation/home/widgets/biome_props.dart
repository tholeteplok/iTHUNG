import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Jenis bioma dunia Mathmo yang merepresentasikan tingkat kematangan level band.
enum IthungBiome {
  meadow, // Band 1 (L1–5): Fresh Sprout Meadow
  canyon, // Band 2 (L6–15): Golden Sun Canyon
  ridge, // Band 3 (L16–30): Coral Sunset Ridge
  twilight, // Band 4 (L31–50): Berry Twilight Forest
  highland, // Band 5 (L51–75): Highland Wind
  frost, // Band 6 (L76–100): Frost Wind
  cosmic, // Band 7 (L101+): Cosmic Hyper Peak (Reserved)
}

/// Helper untuk menentukan bioma berdasarkan nomor level.
IthungBiome biomeForLevel(int level) {
  if (level <= 5) return IthungBiome.meadow;
  if (level <= 15) return IthungBiome.canyon;
  if (level <= 30) return IthungBiome.ridge;
  if (level <= 50) return IthungBiome.twilight;
  if (level <= 75) return IthungBiome.highland;
  if (level <= 100) return IthungBiome.frost;
  return IthungBiome.cosmic;
}

/// Factory widget yang menyajikan dekorasi lingkungan (props) yang relevan
/// dengan bioma dan posisi sisi jalur (kiri atau kanan).
class BiomePropsFactory extends StatelessWidget {
  const BiomePropsFactory({
    super.key,
    required this.level,
    required this.isLeftSide,
  });

  final int level;
  final bool isLeftSide;

  @override
  Widget build(BuildContext context) {
    final biome = biomeForLevel(level);
    final variantIndex = (level + (isLeftSide ? 0 : 2)) % 4;

    return switch (biome) {
      IthungBiome.meadow => switch (variantIndex) {
        0 => const MeadowPineTree(),
        1 => const MeadowBushWithFlowers(),
        2 => const MeadowRoundTree(),
        _ => const MeadowWoodenFence(),
      },
      IthungBiome.canyon => switch (variantIndex) {
        0 => const CanyonSaguaroCactus(),
        1 => const CanyonRockMesa(),
        2 => const CanyonPricklyPear(),
        _ => const CanyonTumbleweed(),
      },
      IthungBiome.ridge => switch (variantIndex) {
        0 => const RidgeLayeredRock(),
        1 => const RidgeAutumnShrub(),
        2 => const RidgeRockCairn(),
        _ => const RidgeLayeredRock(isSmall: true),
      },
      IthungBiome.twilight => switch (variantIndex) {
        0 => const TwilightMushroom(),
        1 => const TwilightMysticTree(),
        2 => const TwilightLantern(),
        _ => const TwilightMushroom(isDouble: true),
      },
      IthungBiome.highland => switch (variantIndex) {
        0 => const MeadowPineTree(),
        1 => const RidgeAutumnShrub(),
        2 => const MeadowRoundTree(),
        _ => const MeadowWoodenFence(),
      },
      IthungBiome.frost => switch (variantIndex) {
        0 => const CosmicCrystalObelisk(),
        1 => const CosmicRuneStone(),
        2 => const TwilightMysticTree(),
        _ => const CosmicCrystalObelisk(isAlternate: true),
      },
      IthungBiome.cosmic => switch (variantIndex) {
        0 => const CosmicCrystalObelisk(),
        1 => const CosmicRuneStone(),
        2 => const CosmicCloud(),
        _ => const CosmicCrystalObelisk(isAlternate: true),
      },
    };
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BAND 1: FRESH SPROUT MEADOW PROPS (L1-5)
// ══════════════════════════════════════════════════════════════════════════════

/// Pohon pinus bertingkat neobrutalis.
class MeadowPineTree extends StatelessWidget {
  const MeadowPineTree({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 48,
      child: CustomPaint(
        painter: _MeadowPinePainter(borderColor: AppTheme.darkBorder),
      ),
    );
  }
}

class _MeadowPinePainter extends CustomPainter {
  const _MeadowPinePainter({required this.borderColor});
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = borderColor
      ..strokeWidth = AppTokens.borderWidthDefault
      ..strokeJoin = StrokeJoin.round;

    // Batang pohon
    final trunkRect = Rect.fromLTWH(size.width * 0.38, size.height * 0.75, size.width * 0.24, size.height * 0.25);
    paintFill.color = const Color(0xFF8D6E63);
    canvas.drawRect(trunkRect, paintFill);
    canvas.drawRect(trunkRect, paintStroke);

    // Dedaunan tingkat bawah
    final pathBottom = Path()
      ..moveTo(size.width * 0.1, size.height * 0.75)
      ..lineTo(size.width * 0.9, size.height * 0.75)
      ..lineTo(size.width * 0.5, size.height * 0.45)
      ..close();
    paintFill.color = const Color(0xFF558B2F);
    canvas.drawPath(pathBottom, paintFill);
    canvas.drawPath(pathBottom, paintStroke);

    // Dedaunan tingkat atas
    final pathTop = Path()
      ..moveTo(size.width * 0.2, size.height * 0.48)
      ..lineTo(size.width * 0.8, size.height * 0.48)
      ..lineTo(size.width * 0.5, size.height * 0.1)
      ..close();
    paintFill.color = const Color(0xFF7CB342);
    canvas.drawPath(pathTop, paintFill);
    canvas.drawPath(pathTop, paintStroke);
  }

  @override
  bool shouldRepaint(covariant _MeadowPinePainter oldDelegate) => false;
}

/// Pohon rimbun bulat neobrutalis.
class MeadowRoundTree extends StatelessWidget {
  const MeadowRoundTree({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 46,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Batang
          Container(
            width: 10,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF8D6E63),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: AppTheme.darkBorder,
                width: AppTokens.borderWidthDefault,
              ),
            ),
          ),
          // Rimbun Daun
          Positioned(
            top: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF689F38),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: AppTokens.borderWidthDefault,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.darkBorder,
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9CCC65),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Semak berbunga daisy mungil.
class MeadowBushWithFlowers extends StatelessWidget {
  const MeadowBushWithFlowers({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF8BC34A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.darkBorder,
          width: AppTokens.borderWidthDefault,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.darkBorder,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _DaisyFlower(),
          _DaisyFlower(),
        ],
      ),
    );
  }
}

class _DaisyFlower extends StatelessWidget {
  const _DaisyFlower();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.darkBorder,
          width: AppTokens.borderWidthSubtle,
        ),
      ),
      child: Center(
        child: Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            color: Color(0xFFFFD54F),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Pagar kayu pedesaan neobrutalis.
class MeadowWoodenFence extends StatelessWidget {
  const MeadowWoodenFence({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 26,
      child: Stack(
        children: [
          // Palang Horizontal
          Positioned(
            top: 10,
            left: 2,
            right: 2,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFD7CCC8),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: AppTokens.borderWidthDefault,
                ),
              ),
            ),
          ),
          // Dua Tiang Vertikal
          Positioned(
            left: 6,
            bottom: 0,
            child: Container(
              width: 7,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFBCAAA4),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: AppTokens.borderWidthDefault,
                ),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 0,
            child: Container(
              width: 7,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFBCAAA4),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: AppTokens.borderWidthDefault,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BAND 2: GOLDEN SUN CANYON PROPS (L6-15)
// ══════════════════════════════════════════════════════════════════════════════

/// Kaktus saguaro bercabang gurun.
class CanyonSaguaroCactus extends StatelessWidget {
  const CanyonSaguaroCactus({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 48,
      child: CustomPaint(
        painter: _CanyonSaguaroPainter(borderColor: AppTheme.darkBorder),
      ),
    );
  }
}

class _CanyonSaguaroPainter extends CustomPainter {
  const _CanyonSaguaroPainter({required this.borderColor});
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppTokens.borderWidthDefault
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Batang tengah
    final mainTrunk = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.38, 0, size.width * 0.24, size.height),
      const Radius.circular(6),
    );
    canvas.drawRRect(mainTrunk, paintFill);
    canvas.drawRRect(mainTrunk, paintStroke);

    // Cabang kiri
    final leftBranch = Path()
      ..moveTo(size.width * 0.38, size.height * 0.55)
      ..lineTo(size.width * 0.12, size.height * 0.55)
      ..lineTo(size.width * 0.12, size.height * 0.28);
    final branchPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(leftBranch, branchPaint);
    canvas.drawPath(leftBranch, paintStroke..strokeWidth = 8);
    canvas.drawPath(leftBranch, branchPaint); // re-fill to retain green body

    // Cabang kanan
    final rightBranch = Path()
      ..moveTo(size.width * 0.62, size.height * 0.45)
      ..lineTo(size.width * 0.88, size.height * 0.45)
      ..lineTo(size.width * 0.88, size.height * 0.22);
    canvas.drawPath(rightBranch, branchPaint);
    canvas.drawPath(rightBranch, paintStroke..strokeWidth = 8);
    canvas.drawPath(rightBranch, branchPaint);
  }

  @override
  bool shouldRepaint(covariant _CanyonSaguaroPainter oldDelegate) => false;
}

/// Kaktus prickly pear berduri neobrutalis.
class CanyonPricklyPear extends StatelessWidget {
  const CanyonPricklyPear({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 40,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Daun bawah
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF66BB6A),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.darkBorder,
                width: AppTokens.borderWidthDefault,
              ),
            ),
          ),
          // Daun atas kanan
          Positioned(
            top: 4,
            right: 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF81C784),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: AppTokens.borderWidthDefault,
                ),
              ),
            ),
          ),
          // Bunga merah kecil di atas
          Positioned(
            top: 0,
            right: 8,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: AppTokens.borderWidthSubtle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Batuan tebing ngarai mesa gurun.
class CanyonRockMesa extends StatelessWidget {
  const CanyonRockMesa({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 30,
      child: CustomPaint(
        painter: _CanyonMesaPainter(borderColor: AppTheme.darkBorder),
      ),
    );
  }
}

class _CanyonMesaPainter extends CustomPainter {
  const _CanyonMesaPainter({required this.borderColor});
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppTokens.borderWidthDefault
      ..strokeJoin = StrokeJoin.round;

    // Lapis bawah
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.45, size.width, size.height * 0.55),
      const Radius.circular(5),
    );
    paintFill.color = const Color(0xFFD78E39);
    canvas.drawRRect(baseRect, paintFill);
    canvas.drawRRect(baseRect, paintStroke);

    // Lapis atas lebih sempit
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.1, size.width * 0.64, size.height * 0.45),
      const Radius.circular(4),
    );
    paintFill.color = const Color(0xFFF3AF5E);
    canvas.drawRRect(topRect, paintFill);
    canvas.drawRRect(topRect, paintStroke);
  }

  @override
  bool shouldRepaint(covariant _CanyonMesaPainter oldDelegate) => false;
}

/// Semak gurun kering tumbleweed.
class CanyonTumbleweed extends StatelessWidget {
  const CanyonTumbleweed({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFDEB887),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.darkBorder,
          width: AppTokens.borderWidthDefault,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.darkBorder,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFCD853F),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.darkBorder,
              width: AppTokens.borderWidthSubtle,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BAND 3: CORAL SUNSET RIDGE PROPS (L16-30)
// ══════════════════════════════════════════════════════════════════════════════

/// Tebing batu terakota berlapis.
class RidgeLayeredRock extends StatelessWidget {
  const RidgeLayeredRock({super.key, this.isSmall = false});
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final scale = isSmall ? 0.75 : 1.0;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 44,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFE06D53),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.darkBorder,
            width: AppTokens.borderWidthDefault,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.darkBorder,
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFF28E79),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ),
            const Spacer(),
            Container(
              height: 6,
              color: const Color(0xFFC04B30),
            ),
          ],
        ),
      ),
    );
  }
}

/// Semak dedaunan musim gugur kemerahan.
class RidgeAutumnShrub extends StatelessWidget {
  const RidgeAutumnShrub({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFD85A30),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppTheme.darkBorder,
          width: AppTokens.borderWidthDefault,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.darkBorder,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: Color(0xFFFFA07A),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Batu cairn penunjuk arah jalur pendakian.
class RidgeRockCairn extends StatelessWidget {
  const RidgeRockCairn({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 38,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 12,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFD7CCC8),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.darkBorder,
                width: AppTokens.borderWidthSubtle,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Container(
            width: 18,
            height: 9,
            decoration: BoxDecoration(
              color: const Color(0xFFA1887F),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.darkBorder,
                width: AppTokens.borderWidthSubtle,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Container(
            width: 26,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF6D4C41),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: AppTheme.darkBorder,
                width: AppTokens.borderWidthDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BAND 4: BERRY TWILIGHT FOREST PROPS (L31-50)
// ══════════════════════════════════════════════════════════════════════════════

/// Jamur twilight berpendar neobrutalis.
class TwilightMushroom extends StatelessWidget {
  const TwilightMushroom({super.key, this.isDouble = false});
  final bool isDouble;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isDouble ? 42 : 32,
      height: 38,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Batang Jamur
          Container(
            width: 10,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.darkBorder,
                width: AppTokens.borderWidthDefault,
              ),
            ),
          ),
          // Payung Jamur
          Positioned(
            top: 2,
            child: Container(
              width: 30,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFD4537E),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: AppTokens.borderWidthDefault,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.darkBorder,
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MushroomDot(),
                  _MushroomDot(),
                ],
              ),
            ),
          ),
          if (isDouble)
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFE07A9E),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  border: Border.all(
                    color: AppTheme.darkBorder,
                    width: AppTokens.borderWidthSubtle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MushroomDot extends StatelessWidget {
  const _MushroomDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Pohon mistis ungu berry.
class TwilightMysticTree extends StatelessWidget {
  const TwilightMysticTree({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 48,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Batang Kayu Ungu Tua
          Container(
            width: 10,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF4A148C),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: AppTheme.darkBorder,
                width: AppTokens.borderWidthDefault,
              ),
            ),
          ),
          // Mahkota Daun Segitiga Melengkung
          Positioned(
            top: 2,
            child: Container(
              width: 36,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFAB47BC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: AppTokens.borderWidthDefault,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.darkBorder,
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCE93D8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lentera jalan kayu berpendar ungu-biru.
class TwilightLantern extends StatelessWidget {
  const TwilightLantern({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 40,
      child: Column(
        children: [
          // Rumah Lentera
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFE1BEE7),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.darkBorder,
                width: AppTokens.borderWidthDefault,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFBA68C8),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Tiang
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BAND 5: COSMIC HYPER PEAK PROPS (L51+)
// ══════════════════════════════════════════════════════════════════════════════

/// Obelisk kristal heksagonal prismatik kosmik.
class CosmicCrystalObelisk extends StatelessWidget {
  const CosmicCrystalObelisk({super.key, this.isAlternate = false});
  final bool isAlternate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 48,
      child: CustomPaint(
        painter: _CosmicCrystalPainter(
          borderColor: AppTheme.darkBorder,
          isAlternate: isAlternate,
        ),
      ),
    );
  }
}

class _CosmicCrystalPainter extends CustomPainter {
  const _CosmicCrystalPainter({
    required this.borderColor,
    required this.isAlternate,
  });

  final Color borderColor;
  final bool isAlternate;

  @override
  void paint(Canvas canvas, Size size) {
    final paintFillLeft = Paint()
      ..color = isAlternate ? const Color(0xFF7E57C2) : const Color(0xFF673AB7)
      ..style = PaintingStyle.fill;
    final paintFillRight = Paint()
      ..color = isAlternate ? const Color(0xFFB39DDB) : const Color(0xFF9575CD)
      ..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppTokens.borderWidthDefault
      ..strokeJoin = StrokeJoin.round;

    // Sisi kiri prisma kristal
    final pathLeft = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.15, size.height * 0.35)
      ..lineTo(size.width * 0.3, size.height)
      ..lineTo(size.width * 0.5, size.height)
      ..close();
    canvas.drawPath(pathLeft, paintFillLeft);
    canvas.drawPath(pathLeft, paintStroke);

    // Sisi kanan prisma kristal
    final pathRight = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.85, size.height * 0.35)
      ..lineTo(size.width * 0.7, size.height)
      ..lineTo(size.width * 0.5, size.height)
      ..close();
    canvas.drawPath(pathRight, paintFillRight);
    canvas.drawPath(pathRight, paintStroke);
  }

  @override
  bool shouldRepaint(covariant _CosmicCrystalPainter oldDelegate) => false;
}

/// Batu rune kuno berpendar kosmik.
class CosmicRuneStone extends StatelessWidget {
  const CosmicRuneStone({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF311B92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.darkBorder,
          width: AppTokens.borderWidthDefault,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF7C4DFF),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'π',
          style: TextStyle(
            color: Color(0xFFB388FF),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// Awan kosmik mengambang neobrutalis.
class CosmicCloud extends StatelessWidget {
  const CosmicCloud({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.darkBorder,
          width: AppTokens.borderWidthDefault,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.darkBorder,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '✦',
          style: TextStyle(
            color: Color(0xFF7E57C2),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
