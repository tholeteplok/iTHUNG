import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../profile/providers/account_status_provider.dart';
import 'chunky_button.dart';
import 'chunky_card.dart';

/// Pilihan aksi hasil interaksi dialog konfirmasi logout.
enum SignOutAction {
  /// Batal / tutup dialog.
  cancel,

  /// Lanjutkan keluar dari akun (dan bersihkan data lokal ke tamu).
  signOut,

  /// Khusus akun anonim: tautkan akun Google terlebih dahulu sebelum keluar.
  linkGoogle,
}

/// Menampilkan dialog konfirmasi keluar dari akun secara terpusat.
Future<SignOutAction?> showSignOutConfirmDialog(
  BuildContext context, {
  required AccountStatus accountStatus,
}) {
  return showDialog<SignOutAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) => SignOutConfirmDialog(accountStatus: accountStatus),
  );
}

/// Dialog konfirmasi keluar bergaya Neobrutalisme.
class SignOutConfirmDialog extends StatelessWidget {
  const SignOutConfirmDialog({
    super.key,
    required this.accountStatus,
  });

  final AccountStatus accountStatus;

  @override
  Widget build(BuildContext context) {
    final isAnonymous = accountStatus == AccountStatus.anonymous;

    final iconData = isAnonymous ? AppIcons.warning : AppIcons.logout;
    final iconColor = isAnonymous ? const Color(0xFFC07A15) : AppTheme.colorDanger;
    final iconBg = isAnonymous ? const Color(0xFFFFF3DB) : AppTheme.colorDangerSoft;
    final iconBorder = isAnonymous ? const Color(0xFFF1D19C) : const Color(0xFFF0B8AC);

    final title = isAnonymous ? 'Perhatian: Akun Anonim' : 'Keluar dari Akun?';
    final message = isAnonymous
        ? 'Kamu menggunakan akun anonim. Jika keluar tanpa menautkan akun Google, seluruh progres petualanganmu di cloud tidak dapat dipulihkan kembali.'
        : 'Progres bermainmu aman tersimpan di akun Google. Perangkat ini akan kembali ke mode Tamu bersih (Level 1). Kamu bisa masuk kembali kapan saja.';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: ChunkyCard(
          variant: ChunkyCardVariant.vanillaSoft,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header Lingkaran
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconBorder,
                    width: AppTokens.borderWidthDefault,
                  ),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),

              // Judul Dialog
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.colorEspresso,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Pesan Penjelasan Edukatif
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorTaupe,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Tombol-Tombol Aksi
              if (isAnonymous) ...[
                // Opsi Utama Akun Anonim: Tautkan Akun Google
                ChunkyButton(
                  key: const Key('btn_sign_out_link_google'),
                  onPressed: () => Navigator.of(context).pop(SignOutAction.linkGoogle),
                  backgroundColor: AppTheme.colorSage,
                  borderColor: const Color(0xFF43733A),
                  shadowColor: const Color(0xFF43733A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppIcons.profile, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Tautkan Akun Google',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Batal
                    Expanded(
                      child: ChunkyButton(
                        key: const Key('btn_sign_out_cancel'),
                        onPressed: () => Navigator.of(context).pop(SignOutAction.cancel),
                        backgroundColor: AppTheme.colorVanillaCard,
                        borderColor: AppTheme.darkBorder,
                        shadowColor: AppTheme.darkBorder,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: AppTheme.colorEspresso,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tetap Keluar
                    Expanded(
                      child: ChunkyButton(
                        key: const Key('btn_sign_out_confirm'),
                        onPressed: () => Navigator.of(context).pop(SignOutAction.signOut),
                        backgroundColor: AppTheme.colorDangerSoft,
                        borderColor: const Color(0xFFF0B8AC),
                        shadowColor: const Color(0xFFDE998B),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: const Text(
                          'Tetap Keluar',
                          style: TextStyle(
                            color: AppTheme.colorDanger,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Akun Terhubung (Google)
                Row(
                  children: [
                    // Batal
                    Expanded(
                      child: ChunkyButton(
                        key: const Key('btn_sign_out_cancel'),
                        onPressed: () => Navigator.of(context).pop(SignOutAction.cancel),
                        backgroundColor: AppTheme.colorVanillaCard,
                        borderColor: AppTheme.darkBorder,
                        shadowColor: AppTheme.darkBorder,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: AppTheme.colorEspresso,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Konfirmasi Keluar
                    Expanded(
                      child: ChunkyButton(
                        key: const Key('btn_sign_out_confirm'),
                        onPressed: () => Navigator.of(context).pop(SignOutAction.signOut),
                        backgroundColor: AppTheme.colorDangerSoft,
                        borderColor: const Color(0xFFF0B8AC),
                        shadowColor: const Color(0xFFDE998B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(AppIcons.logout, color: AppTheme.colorDanger, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Keluar',
                              style: TextStyle(
                                color: AppTheme.colorDanger,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
