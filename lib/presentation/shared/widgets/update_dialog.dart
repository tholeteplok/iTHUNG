import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/services/update_service.dart';
import '../providers/update_download_provider.dart';
import 'chunky_button.dart';
import 'chunky_card.dart';
import 'keystore_transition_dialog.dart';

/// Membuka dialog notifikasi pembaruan aplikasi bergaya Cozy Woodwork.
Future<void> showUpdateNotificationDialog({
  required BuildContext context,
  required AppUpdateInfo info,
  required VoidCallback onUpdate,
  VoidCallback? onLater,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => UpdateNotificationDialog(
      info: info,
      onUpdate: () {
        Navigator.pop(dialogContext);
        onUpdate();
      },
      onLater: () {
        Navigator.pop(dialogContext);
        onLater?.call();
      },
    ),
  );
}

/// Membuka dialog proses pengunduhan APK dan instalasi otomatis.
Future<void> showUpdateProgressDialog({
  required BuildContext context,
  required AppUpdateInfo info,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => UpdateProgressDialog(info: info),
  );
}

/// Membuka dialog prompt instalasi ketika unduhan selesai di latar belakang.
Future<void> showUpdateInstallPromptDialog({
  required BuildContext context,
  required AppUpdateInfo info,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => UpdateInstallPromptDialog(info: info),
  );
}

/// Dialog panduan cadangan jika pemasangan otomatis Android terhalang izin atau batasan sistem
Future<void> showInstallFallbackDialog({
  required BuildContext context,
  required WidgetRef ref,
  required AppUpdateInfo info,
}) async {
  final downloadState = ref.read(updateDownloadProvider);
  final exportPath = downloadState.publicExportPath;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ChunkyCard(
          variant: ChunkyCardVariant.vanillaSoft,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.colorHoney.withValues(alpha: 0.18),
                  border: Border.all(
                    color: AppTheme.colorHoney.withValues(alpha: 0.40),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.folder_open_rounded,
                    color: AppTheme.colorWoodMedium,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Pasang dari Unduhan 📂',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorEspresso,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sistem Android memerlukan izin pemasangan aplikasi atau file APK dapat dibuka langsung dari folder Download perangkat Anda.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.colorTaupe,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (exportPath != null && exportPath.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.colorSandyCanvas,
                    borderRadius: BorderRadius.circular(AppTokens.radiusBar),
                    border: Border.all(
                      color: AppTheme.colorWoodLight.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 14, color: AppTheme.colorSage),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Tersimpan di folder Download',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.colorWoodDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ChunkyButton(
                onPressed: () async {
                  await ref
                      .read(updateDownloadProvider.notifier)
                      .openDownloadsFolder();
                },
                backgroundColor: AppTheme.colorSage,
                width: double.infinity,
                child: const Text(
                  'Buka Folder Unduhan 📂',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ChunkyButton(
                onPressed: () async {
                  await ref
                      .read(updateServiceProvider)
                      .openInstallPermissionSettings();
                },
                backgroundColor: AppTheme.colorHoney,
                width: double.infinity,
                child: const Text(
                  'Buka Izin Pengaturan ⚙️',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    color: AppTheme.colorTaupe,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

/// Memeriksa kecocokan sertifikat dan menjalankan instalasi atau transisi keystore
Future<void> handleAppInstall({
  required BuildContext context,
  required WidgetRef ref,
  required AppUpdateInfo info,
}) async {
  final result =
      await ref.read(updateDownloadProvider.notifier).triggerInstall();

  if (!context.mounted) return;

  if (result == InstallResult.keystoreMismatch) {
    Navigator.of(context, rootNavigator: true).pop();
    final downloadState = ref.read(updateDownloadProvider);
    final ver = info.latestVersion;
    final fileName = 'iTHUNG-v$ver.apk';
    await showKeystoreTransitionDialog(
      context: context,
      info: info,
      exportFileName: fileName,
      publicExportPath: downloadState.publicExportPath,
    );
  } else if (result == InstallResult.failed) {
    await showInstallFallbackDialog(
      context: context,
      ref: ref,
      info: info,
    );
  } else if (result == InstallResult.success) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

/// Dialog notifikasi rilis versi terbaru iTHUNG.
class UpdateNotificationDialog extends ConsumerWidget {
  const UpdateNotificationDialog({
    super.key,
    required this.info,
    required this.onUpdate,
    this.onLater,
  });

  final AppUpdateInfo info;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(updateDownloadProvider);
    final isAlreadySaved = downloadState.isCompleted &&
        downloadState.info?.latestVersion == info.latestVersion;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ChunkyCard(
          variant: ChunkyCardVariant.vanillaSoft,
          padding: const EdgeInsets.fromLTRB(22, 32, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Ikon Roket Bernyawa
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.colorSage.withValues(alpha: 0.18),
                  border: Border.all(
                    color: AppTheme.colorSage.withValues(alpha: 0.40),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    AppIcons.rocket,
                    color: AppTheme.colorSage,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Judul & Versi Baru
              Text(
                'Pembaruan Tersedia 🚀',
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorEspresso,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Versi ${info.latestVersion}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorTaupe,
                ),
              ),
              const SizedBox(height: 12),

              // Badges Info Ukuran & Arsitektur CPU
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  if (info.formattedSize.isNotEmpty)
                    _buildBadge(
                      icon: AppIcons.download,
                      label: info.formattedSize,
                      accentColor: AppTheme.colorSage,
                    ),
                  if (info.matchedAbi.isNotEmpty)
                    _buildBadge(
                      icon: AppIcons.cpu,
                      label: info.matchedAbi == 'universal'
                          ? 'Universal APK'
                          : info.matchedAbi,
                      accentColor: AppTheme.colorHoney,
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Catatan Rilis (Release Notes)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Catatan Rilis:',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.colorWoodDark,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _buildFriendlyReleaseNotes(info.releaseNotes),
              const SizedBox(height: 18),

              // Tombol Aksi Utama (Perbarui Sekarang / Pasang Tersimpan)
              ChunkyButton(
                onPressed: () async {
                  if (isAlreadySaved) {
                    await handleAppInstall(
                      context: context,
                      ref: ref,
                      info: info,
                    );
                  } else {
                    onUpdate();
                  }
                },
                backgroundColor: AppTheme.colorSage,
                width: double.infinity,
                child: Text(
                  isAlreadySaved
                      ? 'Pasang Pembaruan 🚀 (Tersimpan)'
                      : 'Perbarui Sekarang',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // Tombol Batal / Nanti Saja
              TextButton(
                onPressed: onLater,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Nanti Saja',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.colorTaupe,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: AppTokens.borderWidthSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accentColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.colorWoodDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendlyReleaseNotes(String rawNotes) {
    final service = UpdateService();
    final items = service.parseReleaseNotes(rawNotes);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.colorVanillaCard,
        borderRadius: BorderRadius.circular(AppTokens.radiusIcon),
        border: Border.all(
          color: AppTheme.colorWoodBorder.withValues(alpha: 0.6),
          width: AppTokens.borderWidthSubtle,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.5),
                    child: _buildPriorityDot(item.category),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.text,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorWoodDark,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPriorityDot(ReleaseCategory category) {
    final Color pastelColor;
    switch (category) {
      case ReleaseCategory.fix:
        pastelColor = AppTheme.colorPastelCoral;
      case ReleaseCategory.feat:
        pastelColor = AppTheme.colorPastelSage;
      case ReleaseCategory.perf:
        pastelColor = AppTheme.colorPastelHoney;
      case ReleaseCategory.ui:
        pastelColor = AppTheme.colorPastelSky;
      case ReleaseCategory.general:
        pastelColor = AppTheme.colorPastelClay;
    }

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: pastelColor.withValues(alpha: 0.32),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: pastelColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Dialog proses pengunduhan file APK dan instalasi otomatis.
class UpdateProgressDialog extends ConsumerStatefulWidget {
  const UpdateProgressDialog({super.key, required this.info});

  final AppUpdateInfo info;

  @override
  ConsumerState<UpdateProgressDialog> createState() =>
      _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends ConsumerState<UpdateProgressDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateDownloadProvider.notifier).maximize();
      ref.read(updateDownloadProvider.notifier).startDownload(widget.info);
    });
  }

  Future<void> _openFallbackUrl() async {
    final uri = Uri.parse(widget.info.htmlUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(updateDownloadProvider);
    final receivedBytes = downloadState.receivedBytes;
    final totalBytes = downloadState.totalBytes;
    final progress = downloadState.progress;
    final isDownloading = downloadState.isDownloading;
    final isCompleted = downloadState.isCompleted;
    final errorMessage = downloadState.errorMessage;
    final statusMessage = downloadState.statusMessage.isNotEmpty
        ? downloadState.statusMessage
        : 'Menghubungi server rilis...';

    final receivedMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final effectiveTotalBytes = totalBytes > 0
        ? totalBytes
        : (widget.info.downloadSizeBytes > 0
            ? widget.info.downloadSizeBytes
            : 0);
    final totalMb = effectiveTotalBytes > 0
        ? (effectiveTotalBytes / (1024 * 1024)).toStringAsFixed(1)
        : '?';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ChunkyCard(
          variant: ChunkyCardVariant.vanillaSoft,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan tombol minimize
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  Expanded(
                    child: Text(
                      isCompleted ? 'Unduhan Selesai' : 'Mengunduh iTHUNG',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.colorEspresso,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Minimalkan',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_fullscreen_rounded,
                      size: 20,
                      color: AppTheme.colorTaupe,
                    ),
                    onPressed: () {
                      ref.read(updateDownloadProvider.notifier).minimize();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                statusMessage,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorTaupe,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Tactical Progress Bar Berpola Kayu
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.colorWoodPlank,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(
                    color: AppTheme.colorWoodBorder,
                    width: AppTokens.borderWidthSubtle,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fillWidth =
                        constraints.maxWidth * progress.clamp(0.0, 1.0);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: fillWidth,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.colorSage
                              : AppTheme.colorHoney,
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusPill),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Detail Ukuran Byte
              Text(
                '$receivedMb MB / $totalMb MB',
                style: AppTheme.statNumberStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colorWoodDark,
                ),
              ),

              // Tombol Aksi saat Selesai
              if (isCompleted) ...[
                const SizedBox(height: 16),
                ChunkyButton(
                  onPressed: () async {
                    await handleAppInstall(
                      context: context,
                      ref: ref,
                      info: widget.info,
                    );
                  },
                  backgroundColor: AppTheme.colorSage,
                  width: double.infinity,
                  child: const Text(
                    'Pasang Sekarang 🚀',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () {
                    ref.read(updateDownloadProvider.notifier).minimize();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Simpan & Pasang Nanti',
                    style: TextStyle(
                      color: AppTheme.colorTaupe,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ]
              // Tombol Aksi saat Mengunduh (Bisa Minimalkan & Lanjut Main)
              else if (errorMessage == null) ...[
                const SizedBox(height: 16),
                ChunkyButton(
                  onPressed: () {
                    ref.read(updateDownloadProvider.notifier).minimize();
                    Navigator.pop(context);
                  },
                  backgroundColor: AppTheme.colorHoney,
                  width: double.infinity,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_downward_rounded,
                          size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Minimalkan & Lanjut Main',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Pesan Error jika Gagal / Terputus
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.colorDangerSoft,
                    borderRadius: BorderRadius.circular(AppTokens.radiusIcon),
                    border: Border.all(
                      color: AppTheme.colorCoral.withValues(alpha: 0.35),
                      width: AppTokens.borderWidthSubtle,
                    ),
                  ),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.colorCoral,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
                ChunkyButton(
                  key: const Key('btn_resume_download'),
                  onPressed: isDownloading
                      ? null
                      : () => ref
                          .read(updateDownloadProvider.notifier)
                          .startDownload(widget.info),
                  backgroundColor: AppTheme.colorSage,
                  width: double.infinity,
                  child: const Text(
                    'Lanjutkan Unduhan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _openFallbackUrl,
                      icon: const Icon(Icons.open_in_browser,
                          size: 15, color: AppTheme.colorTaupe),
                      label: const Text(
                        'Buka di Browser',
                        style: TextStyle(
                          color: AppTheme.colorTaupe,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          color: AppTheme.colorTaupe,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
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

/// Dialog konfirmasi instalasi ketika unduhan selesai di latar belakang.
class UpdateInstallPromptDialog extends ConsumerWidget {
  const UpdateInstallPromptDialog({super.key, required this.info});

  final AppUpdateInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ChunkyCard(
          variant: ChunkyCardVariant.vanillaSoft,
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.colorSage.withValues(alpha: 0.18),
                  border: Border.all(
                    color: AppTheme.colorSage.withValues(alpha: 0.40),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    AppIcons.rocket,
                    color: AppTheme.colorSage,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Pembaruan Siap Dipasang! 🚀',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorEspresso,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Versi ${info.latestVersion} telah selesai diunduh dan tersimpan di perangkat.',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorTaupe,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ChunkyButton(
                onPressed: () async {
                  await handleAppInstall(
                    context: context,
                    ref: ref,
                    info: info,
                  );
                },
                backgroundColor: AppTheme.colorSage,
                width: double.infinity,
                child: const Text(
                  'Pasang Sekarang',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Nanti Saja',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.colorTaupe,
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
