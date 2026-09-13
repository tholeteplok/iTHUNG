import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Varian visual kartu terpusat untuk aplikasi iTHUNG.
enum ChunkyCardVariant {
  /// Kartu vanilla cream hangat untuk kontainer umum non-game.
  vanilla,

  /// Lembaran kertas putih bersih menggantung dengan klip/gantungan binder kayu di bagian atas (khusus soal gameplay).
  hangingPaper,

  /// Papan kayu hangat dengan bingkai kayu tegas dan tekstur plank (khusus UI non-game).
  wood,

  /// Papan kayu bertekstur alami dengan paku rivet di atas (menggunakan wood_board_square.png).
  woodBoard,
}

/// Kartu bergaya "Cozy Tactile" terpusat dengan dukungan varian kertas menggantung dan papan kayu.
///
/// Komponen ini tersentralisasi untuk semua kartu soal, kartu skor, dan kontainer dialog
/// di aplikasi iTHUNG, memastikan konsistensi visual penuh antar layar tanpa hardcoding.
class ChunkyCard extends StatelessWidget {
  const ChunkyCard({
    super.key,
    required this.child,
    this.variant = ChunkyCardVariant.vanilla,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.borderWidth,
    this.boxShadow,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.rotation = 0.0,
    this.width,
    this.height,
  });

  final Widget child;
  final ChunkyCardVariant variant;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? borderWidth;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;

  /// Rotasi sudut elemen dalam radian (mis. [AppTokens.rotationSubtleNegative]).
  final double rotation;

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(20);

    // Resolusi warna dan properti sesuai varian (Cozy Warm Stationery & Woodwork)
    final effectiveBg = backgroundColor ??
        switch (variant) {
          ChunkyCardVariant.hangingPaper => AppTheme.colorPaperWhite,
          ChunkyCardVariant.wood || ChunkyCardVariant.woodBoard =>
            AppTheme.colorWoodPlank,
          ChunkyCardVariant.vanilla => AppTheme.colorWoodPlank,
        };

    final effectiveBorderColor = borderColor ??
        switch (variant) {
          ChunkyCardVariant.hangingPaper => const Color(0xFFEADBCE),
          ChunkyCardVariant.wood || ChunkyCardVariant.woodBoard =>
            AppTheme.colorWoodMedium,
          ChunkyCardVariant.vanilla => AppTheme.colorWoodMedium,
        };

    final effectiveBorderRadius = borderRadius ?? AppTokens.radiusContainer;

    final effectiveBorderWidth = borderWidth ??
        switch (variant) {
          ChunkyCardVariant.wood || ChunkyCardVariant.woodBoard =>
            AppTokens.borderWidthWood,
          _ => AppTokens.borderWidthDefault,
        };

    final effectiveShadow = boxShadow ??
        switch (variant) {
          ChunkyCardVariant.hangingPaper =>
            ChunkyShadow.paper(AppTheme.colorWoodDark),
          ChunkyCardVariant.wood || ChunkyCardVariant.woodBoard =>
            ChunkyShadow.wood(AppTheme.colorWoodDark),
          ChunkyCardVariant.vanilla =>
            ChunkyShadow.container(AppTheme.colorWoodDark),
        };

    Widget cardBody = Container(
      width: width,
      height: height,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: effectiveBorderWidth,
        ),
        boxShadow: effectiveShadow,
      ),
      child: child,
    );

    // Jika varian hangingPaper, tambahkan aksen gantungan binder clips di bagian atas
    Widget resultWidget;
    if (variant == ChunkyCardVariant.hangingPaper) {
      resultWidget = Container(
        margin: margin,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            cardBody,
            // 2 Tab gantungan binder kulit/kayu di atas kartu
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHangerTab(),
                  _buildHangerTab(),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      resultWidget = Container(
        margin: margin,
        child: cardBody,
      );
    }

    if (rotation != 0.0) {
      resultWidget = Transform.rotate(angle: rotation, child: resultWidget);
    }

    return resultWidget;
  }

  /// Klip gantungan kalender memo / binder kayu-kulit di atas kartu kertas
  static Widget _buildHangerTab() {
    return Container(
      width: 16,
      height: 20,
      decoration: BoxDecoration(
        color: AppTheme.colorWoodMedium,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.colorWoodDark,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppTheme.colorWoodDark,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
