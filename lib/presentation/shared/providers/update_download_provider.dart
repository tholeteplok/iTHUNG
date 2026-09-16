import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/update_service.dart';

enum UpdateDownloadStatus {
  idle,
  downloading,
  paused,
  completed,
  error,
}

enum InstallResult {
  success,
  keystoreMismatch,
  failed,
}

class UpdateDownloadState {
  final UpdateDownloadStatus status;
  final AppUpdateInfo? info;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final String? downloadedFilePath;
  final bool isMinimized;
  final bool hasAutoPrompted;
  final bool isSignatureMismatch;
  final String? publicExportPath;
  final String? errorMessage;
  final String statusMessage;

  const UpdateDownloadState({
    this.status = UpdateDownloadStatus.idle,
    this.info,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.downloadedFilePath,
    this.isMinimized = false,
    this.hasAutoPrompted = false,
    this.isSignatureMismatch = false,
    this.publicExportPath,
    this.errorMessage,
    this.statusMessage = '',
  });

  bool get isDownloading => status == UpdateDownloadStatus.downloading;
  bool get isCompleted => status == UpdateDownloadStatus.completed;
  bool get hasActiveTask =>
      status == UpdateDownloadStatus.downloading ||
      status == UpdateDownloadStatus.paused ||
      status == UpdateDownloadStatus.completed;

  UpdateDownloadState copyWith({
    UpdateDownloadStatus? status,
    AppUpdateInfo? info,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? downloadedFilePath,
    bool? isMinimized,
    bool? hasAutoPrompted,
    bool? isSignatureMismatch,
    String? publicExportPath,
    String? errorMessage,
    String? statusMessage,
  }) {
    return UpdateDownloadState(
      status: status ?? this.status,
      info: info ?? this.info,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      isMinimized: isMinimized ?? this.isMinimized,
      hasAutoPrompted: hasAutoPrompted ?? this.hasAutoPrompted,
      isSignatureMismatch: isSignatureMismatch ?? this.isSignatureMismatch,
      publicExportPath: publicExportPath ?? this.publicExportPath,
      errorMessage: errorMessage,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

final updateDownloadProvider =
    StateNotifierProvider<UpdateDownloadController, UpdateDownloadState>((ref) {
  final updateService = ref.watch(updateServiceProvider);
  return UpdateDownloadController(updateService);
});

class UpdateDownloadController extends StateNotifier<UpdateDownloadState> {
  UpdateDownloadController(this._updateService)
      : super(const UpdateDownloadState());

  final UpdateService _updateService;
  int _lastUiUpdateTime = 0;

  /// Memulai atau melanjutkan proses unduhan APK pembaruan
  Future<void> startDownload(AppUpdateInfo updateInfo) async {
    if (state.isDownloading) return;

    final targetVersion = updateInfo.latestVersion;
    final expectedBytes = updateInfo.downloadSizeBytes;

    // Cek apakah file sudah 100% tersimpan sebelumnya
    final isAlreadyComplete = await _updateService.isApkFullyDownloaded(
      targetVersion,
      expectedBytes,
    );

    if (isAlreadyComplete) {
      final file = await _updateService.getUpdateFile(targetVersion);
      state = state.copyWith(
        status: UpdateDownloadStatus.completed,
        info: updateInfo,
        progress: 1.0,
        receivedBytes: expectedBytes > 0 ? expectedBytes : await file.length(),
        totalBytes: expectedBytes > 0 ? expectedBytes : await file.length(),
        downloadedFilePath: file.path,
        statusMessage: 'Pembaruan siap dipasang',
        errorMessage: null,
      );
      return;
    }

    // Periksa byte yang sudah tersimpan untuk resume
    final existingBytes =
        await _updateService.getDownloadedApkBytes(targetVersion);

    state = state.copyWith(
      status: UpdateDownloadStatus.downloading,
      info: updateInfo,
      receivedBytes: existingBytes,
      totalBytes: expectedBytes,
      progress: expectedBytes > 0
          ? (existingBytes / expectedBytes).clamp(0.0, 1.0)
          : 0.0,
      statusMessage: existingBytes > 0
          ? 'Melanjutkan unduhan...'
          : 'Mengunduh pembaruan...',
      errorMessage: null,
    );

    try {
      final file = await _updateService.downloadApk(
        downloadUrl: updateInfo.downloadUrl,
        version: targetVersion,
        expectedTotalBytes: expectedBytes,
        onProgress: (prog, received, total) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final currentRec = math.max(state.receivedBytes, received);
          final currentTotal = total > 0 ? total : state.totalBytes;
          final currentProg = prog > 0 ? math.max(state.progress, prog) : state.progress;

          // Throttle state update ~60ms
          if ((now - _lastUiUpdateTime > 60) || prog >= 1.0) {
            _lastUiUpdateTime = now;
            final pct = (currentProg * 100).toInt();
            state = state.copyWith(
              receivedBytes: currentRec,
              totalBytes: currentTotal,
              progress: currentProg,
              statusMessage: currentProg >= 1.0
                  ? 'Pembaruan siap dipasang'
                  : 'Mengunduh $pct%...',
            );
          }
        },
      );

      state = state.copyWith(
        status: UpdateDownloadStatus.completed,
        progress: 1.0,
        downloadedFilePath: file.path,
        statusMessage: 'Pembaruan siap dipasang',
        errorMessage: null,
      );
    } catch (e) {
      final errText = e.toString().replaceFirst('Exception: ', '').trim();
      state = state.copyWith(
        status: UpdateDownloadStatus.error,
        errorMessage: errText,
        statusMessage: 'Unduhan dijeda',
      );
    }
  }

  /// Meminimalkan dialog ke floating pill tanpa memutus proses unduh
  void minimize() {
    state = state.copyWith(isMinimized: true);
  }

  /// Membuka kembali dialog penuh dari floating pill
  void maximize() {
    state = state.copyWith(isMinimized: false);
  }

  /// Menandai bahwa prompt instalasi telah ditampilkan ke pengguna
  void markAutoPrompted() {
    state = state.copyWith(hasAutoPrompted: true);
  }

  /// Mereset flag auto prompt jika diperlukan
  void resetAutoPrompt() {
    state = state.copyWith(hasAutoPrompted: false);
  }

  /// Memeriksa kecocokan tanda tangan (signature), melakukan auto-export ke publik jika mismatch,
  /// dan membuka dialog transisi atau langsung menjalankan installer.
  Future<InstallResult> triggerInstall() async {
    final path = state.downloadedFilePath;
    if (path == null) return InstallResult.failed;
    final file = File(path);
    if (!await file.exists()) return InstallResult.failed;

    // 1. Periksa apakah signature cocok dengan aplikasi yang sedang berjalan
    final isMatch = await _updateService.checkSignatureMatch(path);

    if (!isMatch) {
      // Terdeteksi perbedaan keystore!
      final ver = state.info?.latestVersion ?? 'update';
      final fileName = 'iTHUNG-v$ver.apk';
      final publicPath =
          await _updateService.exportToPublicDownloads(path, fileName);

      state = state.copyWith(
        isSignatureMismatch: true,
        publicExportPath: publicPath,
      );

      return InstallResult.keystoreMismatch;
    }

    // Signature cocok (normal update), jalankan installer standar
    final success = await _updateService.installApk(path);
    return success ? InstallResult.success : InstallResult.failed;
  }

  /// Membuka installer sistem Android untuk memasang file APK yang telah diunduh
  Future<bool> installApk() async {
    final result = await triggerInstall();
    return result == InstallResult.success;
  }

  /// Membatalkan atau mereset unduhan
  void dismiss() {
    state = const UpdateDownloadState();
  }
}
