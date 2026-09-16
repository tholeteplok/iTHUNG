import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';

/// Dialog selebrasi saat pemain berhasil menuntaskan level puncak suatu zona
/// dan membuka zona petualangan baru di peta.
class ZoneUnlockedDialog extends ConsumerStatefulWidget {
  const ZoneUnlockedDialog({
    super.key,
    required this.zoneName,
    required this.zoneIcon,
    required this.zoneLevelRange,
    required this.onContinue,
  });

  final String zoneName;
  final String zoneIcon;
  final String zoneLevelRange;
  final VoidCallback onContinue;

  @override
  ConsumerState<ZoneUnlockedDialog> createState() =>
      _ZoneUnlockedDialogState();
}

class _ZoneUnlockedDialogState extends ConsumerState<ZoneUnlockedDialog> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
      // Anchor haptic tunggal sebagai kelanjutan siphon.
      ref.read(hapticServiceProvider).mediumImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedScale(
        scale: _visible ? 1.0 : 0.9,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: ChunkyCard(
        variant: ChunkyCardVariant.vanillaSoft,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Banner Pita "ZONA BARU TERBUKA!"
            AnimatedSlide(
              offset: _visible ? Offset.zero : const Offset(0, -0.3),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.colorHoney,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(
                  color: AppTheme.colorWoodDark,
                  width: AppTokens.borderWidthWood,
                ),
                boxShadow: ChunkyShadow.container(AppTheme.colorWoodDark),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    AppIcons.starFilled,
                    color: AppTheme.colorWoodDark,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ZONA BARU TERBUKA!',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.0,
                      color: AppTheme.colorWoodDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    AppIcons.starFilled,
                    color: AppTheme.colorWoodDark,
                    size: 18,
                  ),
                ],
              ),
              ),
            ),
            const SizedBox(height: 20),

            // Ikon Zona Besar dengan Aura (pop stagger)
            AnimatedScale(
              scale: _visible ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.colorVanillaCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.colorWoodDark,
                  width: AppTokens.borderWidthWood,
                ),
                boxShadow: ChunkyShadow.container(AppTheme.colorWoodDark),
              ),
              child: Center(
                child: Text(
                  widget.zoneIcon,
                  style: const TextStyle(fontSize: 46),
                ),
              ),
              ),
            ),
            const SizedBox(height: 16),

            // Nama Zona Baru
            Text(
              widget.zoneName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.colorEspresso,
                  ),
            ),
            const SizedBox(height: 6),

            // Rentang Level
            Text(
              widget.zoneLevelRange,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.colorTaupe,
                  ),
            ),
            const SizedBox(height: 16),

            Text(
              'Luar biasa! Jalur petualangan baru telah terbuka di peta. Teruslah berpetualang dan kumpulkan semua bintang!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.colorEspresso,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),

            // Tombol Menuju Zona Baru (stagger 100ms)
            AnimatedSlide(
              offset: _visible ? Offset.zero : const Offset(0, 0.3),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              child: ChunkyButton(
              onPressed: widget.onContinue,
              backgroundColor: AppTheme.colorSage,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jelajahi Sekarang',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}
