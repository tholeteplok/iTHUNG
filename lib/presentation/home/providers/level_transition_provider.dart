import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data kelas representasi transisi pergerakan level maskot di peta.
class LevelTransitionState {
  const LevelTransitionState({
    required this.fromLevel,
    required this.toLevel,
    this.isZoneTransition = false,
  });

  final int fromLevel;
  final int toLevel;
  final bool isZoneTransition;
}

/// Notifier pengelola pergerakan transisi level aktif di peta.
class LevelTransitionNotifier extends StateNotifier<LevelTransitionState?> {
  LevelTransitionNotifier() : super(null);

  /// Memicu transisi lompatan maskot dari [fromLevel] ke [toLevel].
  void triggerTransition({
    required int fromLevel,
    required int toLevel,
    bool isZoneTransition = false,
  }) {
    if (fromLevel == toLevel) return;
    state = LevelTransitionState(
      fromLevel: fromLevel,
      toLevel: toLevel,
      isZoneTransition: isZoneTransition,
    );
  }

  /// Menghapus state transisi setelah animasi lompatan rampung.
  void clearTransition() {
    state = null;
  }
}

/// Provider global untuk memantau apakah ada antrean lompatan maskot di peta.
final levelTransitionProvider =
    StateNotifierProvider<LevelTransitionNotifier, LevelTransitionState?>((ref) {
  return LevelTransitionNotifier();
});
