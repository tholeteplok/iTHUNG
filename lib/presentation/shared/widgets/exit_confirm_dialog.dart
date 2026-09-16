import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import 'chunky_button.dart';
import 'chunky_card.dart';

/// Menampilkan dialog konfirmasi saat pemain ingin keluar dari sesi gameplay aktif atau aplikasi.
///
/// Mengacu pada prinsip Neobrutalisme dan psikologi UI:
/// - Mencegah kehilangan progres ronde/level yang tidak disengaja.
/// - Menggunakan tombol berikon 'X' merah untuk batal dan check mark hijau untuk konfirmasi keluar.
Future<bool> showExitConfirmDialog(
  BuildContext context, {
  String title = 'Keluar dari Sesi?',
  String message =
      'Progres ronde pada level yang sedang berjalan ini tidak akan disimpan.',
  String confirmLabel = 'Keluar',
  String cancelLabel = 'Batal',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ExitConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return result ?? false;
}

/// Widget dialog konfirmasi keluar bergaya Neobrutalism terpusat.
class ExitConfirmDialog extends StatelessWidget {
  const ExitConfirmDialog({
    super.key,
    this.title = 'Keluar dari Sesi?',
    this.message =
        'Progres ronde pada level yang sedang berjalan ini tidak akan disimpan.',
    this.confirmLabel = 'Keluar',
    this.cancelLabel = 'Batal',
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ChunkyCard(
        variant: ChunkyCardVariant.vanillaSoft,
        padding: const EdgeInsets.fromLTRB(26, 44, 26, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Judul Dialog
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.colorEspresso,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Pesan Penjelasan
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.colorTaupe,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Baris Tombol Aksi: 'X' Merah (Batal) & Check Mark Hijau (Keluar)
            Row(
              children: [
                // Tombol Batal: Icon 'X' Merah
                Expanded(
                  child: ChunkyButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    backgroundColor: AppTheme.colorDangerSoft,
                    borderColor: const Color(0xFFF0B8AC),
                    shadowColor: const Color(0xFFDE998B),
                    borderWidth: AppTokens.borderWidthDefault,
                    borderRadius: AppTokens.radiusButton,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.close_rounded,
                          color: AppTheme.colorDanger, // Merah tegas
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cancelLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.colorDanger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol Konfirmasi: Icon Check Mark Hijau
                Expanded(
                  child: ChunkyButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    backgroundColor: AppTheme.colorSuccessSoft,
                    borderColor: const Color(0xFFBDDFB5),
                    shadowColor: const Color(0xFFA1CF97),
                    borderWidth: AppTokens.borderWidthDefault,
                    borderRadius: AppTokens.radiusButton,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: AppTheme.colorSuccess, // Hijau tegas
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.colorSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
