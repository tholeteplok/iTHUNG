import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';

/// Dock navigasi melayang langsung di bawah layar HomeScreen.
///
/// Menggunakan 4 icon kustom langsung melayang di atas peta (tanpa container luar
/// dan tanpa teks label):
/// 1. Profil (`/profile`)
/// 2. Papan Peringkat (`/leaderboard`)
/// 3. Tantangan Harian (`/daily`)
/// 4. Pengaturan (`/settings`)
class FloatingBottomDock extends StatelessWidget {
  const FloatingBottomDock({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _DockItem(
              assetPath: AppAssets.icProfile,
              label: 'Profil',
              onTap: () => context.go('/profile'),
            ),
            _DockItem(
              assetPath: AppAssets.icLead,
              label: 'Peringkat',
              onTap: () => context.go('/leaderboard'),
            ),
            _DockItem(
              assetPath: AppAssets.icDaily,
              label: 'Tantangan',
              onTap: () => context.go('/challenges'),
            ),
            _DockItem(
              assetPath: AppAssets.icSettings,
              label: 'Pengaturan',
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item navigasi langsung berupa icon dengan feedback ketukan taktil.
class _DockItem extends StatefulWidget {
  const _DockItem({
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final VoidCallback onTap;

  @override
  State<_DockItem> createState() => _DockItemState();
}

class _DockItemState extends State<_DockItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      child: Tooltip(
        message: widget.label,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _isPressed ? 0.88 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                widget.assetPath,
                width: 46,
                height: 46,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
