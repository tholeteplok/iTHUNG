import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import 'badge_pill.dart';

/// Header persisten untuk GameScreen, HomeScreen, dan ShellRoute.
///
/// Kontrak tampilan:
/// - Home & Game: HUD penuh (pil streak kiri + pil XP kanan).
/// - Layar sekunder (leaderboard, pengaturan, daily, profil, dsb.):
///   hanya tombol back + judul — set `showStats: false`.
/// Saat stats dan actions disembunyikan, sisi kanan diberi spacer penyeimbang
/// agar judul tetap ter-center secara visual.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.streak = 0,
    this.xp = 0,
    this.showStats = true,
    this.leading,
    this.title,
    this.actions,
    this.onBackTap,
    this.backgroundColor = Colors.transparent,
  });

  final int streak;
  final int xp;

  /// Sembunyikan badge streak/XP di layar sekunder (leaderboard, profil, dsb).
  final bool showStats;
  final Widget? leading;
  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onBackTap;
  final Color backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sisi Kiri: Tombol Back (jika ada) atau Streak Pill
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onBackTap != null) ...[
                  GestureDetector(
                    onTap: onBackTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.colorVanillaCard,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.colorTranslucentBorder,
                          width: AppTokens.borderWidthSubtle,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.colorWoodDark.withValues(alpha: 0.08),
                            offset: const Offset(0, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        AppIcons.back,
                        size: 20,
                        color: AppTheme.colorEspresso,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ] else if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ],
                if (showStats)
                  BadgePill(
                    icon: AppIcons.streak,
                    value: '$streak',
                    iconColor: AppTheme.colorCoral,
                  ),
              ],
            ),

            // Judul Tengah (opsional) — font Catboo tersentral.
            if (title != null)
              Expanded(
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: AppTheme.headerTitleStyle(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Sisi Kanan: XP Pill & Actions (atau spacer penyeimbang judul)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showStats)
                  BadgePill(
                    icon: AppIcons.xp,
                    value: '$xp',
                    iconColor: AppTheme.colorHoney,
                  ),
                if (actions != null) ...[
                  const SizedBox(width: 8),
                  ...actions!,
                ],
                // Penyeimbang tombol back (40) + gap (8) agar judul center.
                if (!showStats && actions == null)
                  const SizedBox(width: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
