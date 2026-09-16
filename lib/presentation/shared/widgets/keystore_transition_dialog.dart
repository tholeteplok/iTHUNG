import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/services/update_service.dart';
import 'chunky_button.dart';
import 'chunky_card.dart';

/// Membuka dialog panduan transisi ketika terdeteksi perbedaan sertifikat rilis (Keystore Mismatch).
Future<void> showKeystoreTransitionDialog({
  required BuildContext context,
  required AppUpdateInfo info,
  required String exportFileName,
  required String? publicExportPath,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => KeystoreTransitionDialog(
      info: info,
      exportFileName: exportFileName,
      publicExportPath: publicExportPath,
    ),
  );
}

class KeystoreTransitionDialog extends ConsumerWidget {
  const KeystoreTransitionDialog({
    super.key,
    required this.info,
    required this.exportFileName,
    this.publicExportPath,
  });

  final AppUpdateInfo info;
  final String exportFileName;
  final String? publicExportPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateService = ref.read(updateServiceProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ChunkyCard(
          variant: ChunkyCardVariant.vanillaSoft,
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Ikon Perisai Keamanan
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.colorHoney.withValues(alpha: 0.18),
                  border: Border.all(
                    color: AppTheme.colorHoney.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    AppIcons.shield,
                    color: AppTheme.colorHoney,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Judul & Versi
              Text(
                'Transisi Sistem Keamanan 🛡️',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorEspresso,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Pembaruan ke Versi ${info.latestVersion}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorTaupe,
                ),
              ),
              const SizedBox(height: 14),

              // Kotak Info Langkah Transisi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.colorVanillaCard,
                  borderRadius: BorderRadius.circular(AppTokens.radiusIcon),
                  border: Border.all(
                    color: AppTheme.colorWoodBorder.withValues(alpha: 0.6),
                    width: AppTokens.borderWidthSubtle,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepRow(
                      number: '1',
                      title: 'File Aman di Folder Download',
                      description:
                          'APK telah diamankan ke folder Download HP kamu agar tidak terhapus.',
                      isHighlight: true,
                    ),
                    const Divider(height: 14, thickness: 0.8),
                    _buildStepRow(
                      number: '2',
                      title: 'Aturan Keamanan Android',
                      description:
                          'Karena pembaruan sertifikat resmi, versi lama harus dicopot terlebih dahulu.',
                    ),
                    const Divider(height: 14, thickness: 0.8),
                    _buildStepRow(
                      number: '3',
                      title: 'Pasang dari Download',
                      description:
                          'Buka folder Download dan ketuk "$exportFileName" untuk memasang.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Tombol Utama: Copot Versi Lama & Buka Download
              ChunkyButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Buka folder download terlebih dahulu agar siap di latar belakang
                  await updateService.openDownloadsFolder();
                  // Pemicu dialog pencopotan aplikasi dari sistem Android
                  await updateService.promptUninstall();
                },
                backgroundColor: AppTheme.colorSage,
                width: double.infinity,
                child: const Text(
                  'Copot Lama & Buka Download',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // Tombol Cadangan: Buka Download Saja
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await updateService.openDownloadsFolder();
                    },
                    icon: const Icon(Icons.folder_open_rounded,
                        size: 16, color: AppTheme.colorTaupe),
                    label: const Text(
                      'Buka Folder Download',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorTaupe,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Nanti Saja',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorTaupe,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required String title,
    required String description,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHighlight
                ? AppTheme.colorSage
                : AppTheme.colorTaupe.withValues(alpha: 0.25),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isHighlight ? Colors.white : AppTheme.colorWoodDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isHighlight
                      ? AppTheme.colorSage
                      : AppTheme.colorEspresso,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorTaupe,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
