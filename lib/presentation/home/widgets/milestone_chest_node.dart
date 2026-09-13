import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/sfx_service.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../settings/providers/settings_provider.dart';
import '../../shared/widgets/chunky_button.dart';

/// Node interaktif Peti Harta Karun Milestone di setiap kelipatan 5 level (L5, 10, 15, dst.).
class MilestoneChestNode extends ConsumerWidget {
  const MilestoneChestNode({
    super.key,
    required this.level,
    required this.isUnlocked,
    this.accentColor = const Color(0xFFBA7517),
    this.xpReward = 250,
  });

  final int level;
  final bool isUnlocked;
  final Color accentColor;
  final int xpReward;

  void _showRewardDialog(BuildContext context, WidgetRef ref) {
    if (isUnlocked) {
      try {
        ref.read(sfxServiceProvider).play(SfxType.chestOpen);
      } catch (_) {
        // Abaikan jika dipanggil di luar ProviderScope (mis. isolated widget test)
      }
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => MilestoneRewardDialog(
        level: level,
        isUnlocked: isUnlocked,
        accentColor: accentColor,
        xpReward: xpReward,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chestAsset =
        isUnlocked ? AppAssets.icChestOpen : AppAssets.icChestClose;

    final chestImage = Image.asset(
      chestAsset,
      width: 52,
      height: 52,
      fit: BoxFit.contain,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showRewardDialog(context, ref),
      child: Transform.rotate(
        angle: AppTokens.rotationSubtleNegative,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              chestImage,
              if (isUnlocked)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.darkBorder,
                        width: AppTokens.borderWidthSubtle,
                      ),
                    ),
                    child: const Icon(
                      AppIcons.sparkles,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog chunky neobrutalis untuk menampilkan hadiah peti milestone.
class MilestoneRewardDialog extends StatelessWidget {
  const MilestoneRewardDialog({
    super.key,
    required this.level,
    required this.isUnlocked,
    required this.accentColor,
    required this.xpReward,
  });

  final int level;
  final bool isUnlocked;
  final Color accentColor;
  final int xpReward;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFDF5),
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(
            color: AppTheme.darkBorder,
            width: AppTokens.borderWidthDefault,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.darkBorder,
              offset: Offset(0, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chest 3D Icon Polos Dinamis (Tertutup jika belum, Terbuka jika sudah dilewati)
            Image.asset(
              isUnlocked ? AppAssets.icChestOpen : AppAssets.icChestClose,
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Peti Harta Milestone!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.darkBorder,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUnlocked
                  ? 'Selamat! Kamu telah mencapai Level $level dan membuka peti harta ini!'
                  : 'Selesaikan tantangan hingga Level $level untuk mengklaim hadiah peti ini.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 20),
            // XP Reward Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(
                  color: AppTheme.darkBorder,
                  width: AppTokens.borderWidthSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    AppIcons.xp,
                    color: Color(0xFFBA7517),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+$xpReward Bonus XP',
                    style: AppTheme.statNumberStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkBorder,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action Button
            ChunkyButton(
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: isUnlocked ? accentColor : const Color(0xFF4A6572),
              borderColor: AppTheme.darkBorder,
              child: Text(
                isUnlocked ? 'Luar Biasa!' : 'Mengerti',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
