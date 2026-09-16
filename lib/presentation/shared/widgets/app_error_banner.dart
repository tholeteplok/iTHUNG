import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Banner pesan kesalahan terpusat dengan gaya Cozy Neobrutalism.
///
/// Digunakan untuk menampilkan pesan kegagalan/error secara seragam,
/// jelas, dan ramah pengguna di seluruh dialog dan layar aplikasi.
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner({
    super.key,
    required this.message,
    this.icon = AppIcons.warning,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  final String message;
  final IconData icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.colorVanillaCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        border: Border.all(
          color: AppTheme.colorCoral,
          width: AppTokens.borderWidthSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colorCoral.withValues(alpha: 0.12),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.colorDangerSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.colorCoral,
                width: AppTokens.borderWidthSubtle,
              ),
            ),
            child: Icon(
              icon,
              color: AppTheme.colorCoral,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.quicksand(
                color: AppTheme.colorEspresso,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
