import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/settings/providers/settings_provider.dart';

/// Layanan terpusat untuk getaran haptic feedback pada perangkat.
///
/// Memastikan setiap getaran haptic menghormati pengaturan [AudioSettings.hapticEnabled].
class HapticService {
  const HapticService({required bool Function() isEnabled})
      : _isEnabled = isEnabled;

  final bool Function() _isEnabled;

  /// Memeriksa apakah haptic diaktifkan oleh pengguna.
  bool get isEnabled => _isEnabled();

  /// Getaran ringan (misal untuk detak angka skor atau tap tombol ringan).
  Future<void> lightImpact() async {
    if (!isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Getaran sedang (misal untuk fusi bintang atau popup kartu).
  Future<void> mediumImpact() async {
    if (!isEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Getaran berat (misal untuk ledakan/shatter bintang emas).
  Future<void> heavyImpact() async {
    if (!isEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Klik seleksi mikro (misal untuk rolling counter yang cepat).
  Future<void> selectionClick() async {
    if (!isEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Pola getar pendek (vibrate).
  Future<void> vibrate() async {
    if (!isEnabled) return;
    await HapticFeedback.vibrate();
  }
}

/// Provider instance [HapticService] yang terhubung secara reaktif dengan [audioSettingsProvider].
final hapticServiceProvider = Provider<HapticService>((ref) {
  return HapticService(
    isEnabled: () => ref.read(audioSettingsProvider).hapticEnabled,
  );
});
