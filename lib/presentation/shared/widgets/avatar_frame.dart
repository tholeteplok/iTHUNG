import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

class AvatarFrame extends StatelessWidget {
  const AvatarFrame({super.key, this.avatarAsset, this.initialLetter = 'P', this.size = 92, this.level, this.borderRadius = AppTokens.radiusAvatar});
  final String? avatarAsset;
  final String initialLetter;
  final double size;
  final int? level;
  final double borderRadius;
  double get innerRadius => borderRadius - 2;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.colorWoodPlank,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.colorWoodMedium, width: AppTokens.borderWidthWood),
        boxShadow: ChunkyShadow.wood(AppTheme.colorWoodDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: avatarAsset != null
            ? Image.asset(avatarAsset!, fit: BoxFit.cover)
            : Center(child: Text(initialLetter, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.colorEspresso))),
      ),
    );
  }
}