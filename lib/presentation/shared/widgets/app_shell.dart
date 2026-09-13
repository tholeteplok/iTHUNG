import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../game/providers/level_band_theme_provider.dart';
import 'exit_confirm_dialog.dart';

/// Shell pembungkus aplikasi untuk navigasi via ShellRoute.
///
/// Mengacu pada `math-speed-game-navigation-spec.md` §5:
/// - Mengelola transisi warna kanvas latar belakang dinamis (±300ms) tanpa terputus
///   saat berpindah layar (Home ↔ Game).
/// - Menangani intersepsi tombol/gestur back sistem Android di tingkat Root Navigator
///   ketika berada pada root screen ('/'), sehingga Android OS OnBackInvokedCallback
///   selalu aktif sejak awal (sebelum masuk game screen).
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
    this.state,
  });

  final Widget child;
  final GoRouterState? state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(levelBandThemeProvider);
    final canvasColor =
        themeAsync.valueOrNull?.canvasColor ?? AppTheme.colorSandyCanvas;

    final location = state?.matchedLocation ??
        GoRouterState.of(context).matchedLocation;
    final isHome = location == '/';
    final isSecondaryTab = location == '/profile' ||
        location == '/leaderboard' ||
        location == '/settings' ||
        location == '/challenges' ||
        location == '/daily';

    return PopScope(
      canPop: !isHome && !isSecondaryTab,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (isHome) {
          final shouldExit = await showExitConfirmDialog(
            context,
            title: 'Keluar dari iTHUNG?',
            message: 'Apakah kamu yakin ingin menutup aplikasi iTHUNG?',
            confirmLabel: 'Keluar',
            cancelLabel: 'Batal',
          );
          if (shouldExit && context.mounted) {
            await SystemNavigator.pop();
          }
        } else if (isSecondaryTab) {
          context.go('/');
        }
      },
      child: NotificationListener<NavigationNotification>(
        onNotification: (notification) {
          // Ketika berada di HomeScreen atau tab sekunder, jangan biarkan notifikasi
          // canHandlePop: false dari Shell Navigator anak menimpa status milik Root Navigator.
          if ((isHome || isSecondaryTab) && !notification.canHandlePop) {
            return true; // Stop bubbling ke WidgetsApp
          }
          return false;
        },
        child: AnimatedContainer(
          duration: AppTokens.canvasColorTransition,
          curve: Curves.easeInOut,
          color: canvasColor,
          child: child,
        ),
      ),
    );
  }
}

