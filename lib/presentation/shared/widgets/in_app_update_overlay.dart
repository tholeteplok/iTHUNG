import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/update_download_provider.dart';
import 'floating_update_pill.dart';
import 'update_dialog.dart';

/// Overlay global di tingkat aplikasi yang mengelola:
/// 1. Tampilan FloatingUpdatePill saat unduhan diminimalkan atau siap pasang.
/// 2. Deteksi cerdas rute permainan (Game Mode):
///    - Di luar game mode: Otomatis memicu dialog pasang (Opsi 1).
///    - Di dalam game mode: Tetap pasif di floating pill agar tidak mengganggu pemain (Opsi 2).
class InAppUpdateOverlay extends ConsumerStatefulWidget {
  const InAppUpdateOverlay({
    super.key,
    required this.child,
    this.currentLocation,
    this.routerListenable,
    this.navigatorKey,
  });

  final Widget child;
  final String Function()? currentLocation;
  final Listenable? routerListenable;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  ConsumerState<InAppUpdateOverlay> createState() => _InAppUpdateOverlayState();
}

class _InAppUpdateOverlayState extends ConsumerState<InAppUpdateOverlay> {
  @override
  void initState() {
    super.initState();
    widget.routerListenable?.addListener(_onRouteChanged);
  }

  @override
  void didUpdateWidget(covariant InAppUpdateOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routerListenable != widget.routerListenable) {
      oldWidget.routerListenable?.removeListener(_onRouteChanged);
      widget.routerListenable?.addListener(_onRouteChanged);
    }
  }

  @override
  void dispose() {
    widget.routerListenable?.removeListener(_onRouteChanged);
    super.dispose();
  }

  /// Memeriksa apakah lokasi saat ini berada di dalam mode permainan aktif
  bool _isGameMode(String path) {
    return path.startsWith('/game') ||
        path == '/daily/play' ||
        path == '/challenges/blitz' ||
        path == '/challenges/marathon';
  }

  void _onRouteChanged() {
    final downloadState = ref.read(updateDownloadProvider);
    if (!downloadState.isCompleted || downloadState.hasAutoPrompted) return;

    final currentPath = widget.currentLocation?.call() ?? '';
    // Jika baru saja keluar dari Game Mode ke menu non-game, picu prompt
    if (!_isGameMode(currentPath) && downloadState.info != null) {
      _triggerInstallPrompt(downloadState);
    }
  }

  void _triggerInstallPrompt(UpdateDownloadState downloadState) {
    final navContext = widget.navigatorKey?.currentContext;
    if (navContext == null || !navContext.mounted) return;

    ref.read(updateDownloadProvider.notifier).markAutoPrompted();
    showUpdateInstallPromptDialog(
      context: navContext,
      info: downloadState.info!,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateDownloadState>(updateDownloadProvider, (prev, next) {
      // Jika unduhan baru saja selesai
      if (next.isCompleted && (prev == null || !prev.isCompleted)) {
        final currentPath = widget.currentLocation?.call() ?? '';
        // Opsi 1: Jika di luar game mode, langsung buka prompt instalasi
        if (!_isGameMode(currentPath) && !next.hasAutoPrompted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerInstallPrompt(next);
          });
        }
        // Opsi 2: Jika di dalam game mode, tahan dan biarkan floating pill pasif
      }
    });

    final downloadState = ref.watch(updateDownloadProvider);
    final shouldShowPill = downloadState.isMinimized &&
        (downloadState.hasActiveTask ||
            downloadState.status == UpdateDownloadStatus.error);

    return Stack(
      children: [
        widget.child,
        if (shouldShowPill)
          Positioned(
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            right: 16,
            child: const FloatingUpdatePill(),
          ),
      ],
    );
  }
}
