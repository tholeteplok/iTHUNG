import 'package:flutter/material.dart';

/// Sumber kebenaran tunggal untuk token visual non-warna (warna ditangani
/// `level_band_theme.dart` + `level_bands.json`).
///
/// Komponen UI TIDAK BOLEH menulis angka border/radius/shadow secara hardcode,
/// selalu lewat `AppTokens`.
class AppTokens {
  AppTokens._();

  // ── Border ───────────────────────────────────────────────────────
  static const double borderWidthDefault = 2.0;
  static const double borderWidthSubtle = 1.2; // untuk badge/pill kecil
  static const double borderWidthWood = 2.5; // untuk kontainer/plang kayu simetris

  // ── Radius ───────────────────────────────────────────────────────
  static const double radiusAvatar = 32.0; // container avatar profil (match curvature gambar)
  static const double radiusContainer = 28.0; // bingkai layar/kartu besar
  static const double radiusCard = 24.0; // kartu soal, kartu skor, stat card
  static const double radiusButton = 22.0; // tombol jawaban / aksi
  static const double radiusPill = 16.0; // badge streak/XP
  static const double radiusIcon = 12.0; // ikon section, tombol back kecil
  static const double radiusBar = 8.0; // progress bar / track tipis
  static const double radiusMini = 6.0; // tombol mini (edit username)

  // ── Rotasi elemen non-kritis (kesan playful hand-drawn) ───────────
  static const double rotationSubtleNegative = -0.035; // radian, ≈ -2°
  static const double rotationSubtlePositive = 0.035; // radian, ≈ +2°

  // ── Durasi mikro-interaksi ───────────────────────────────────────
  static const Duration feedbackDuration = Duration(milliseconds: 400);
  static const Duration questionShowDelay = Duration(milliseconds: 600);
  static const Duration canvasColorTransition = Duration(milliseconds: 300);
  static const Duration buttonPressDuration = Duration(milliseconds: 80);

  // ── Aksesibilitas ────────────────────────────────────────────────
  /// Batas atas `MediaQuery.textScaler` khusus untuk layar gameplay (soal + grid jawaban).
  static const double maxTextScaleGameplay = 1.3;

  /// Jarak minimum tap target (≥44px).
  static const double minTapTarget = 44.0;
}

/// Builder shadow "Cozy Tactile" (bottom depth 3D fisik & soft warm ambient).
class ChunkyShadow {
  ChunkyShadow._();

  /// Shadow default untuk kartu/kontainer besar (soft warm depth organik).
  static List<BoxShadow> container(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.15),
      offset: const Offset(0, 4),
      blurRadius: 8,
    ),
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.06),
      offset: const Offset(0, 2),
      blurRadius: 3,
    ),
  ];

  /// Shadow untuk kartu kertas putih (hanging paper sheet drop shadow).
  static List<BoxShadow> paper(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.14),
      offset: const Offset(0, 6),
      blurRadius: 10,
    ),
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.05),
      offset: const Offset(0, 2),
      blurRadius: 3,
    ),
  ];

  /// Shadow untuk plang/kontainer kayu (3D warm wood depth + ambient soft blur).
  static List<BoxShadow> wood(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.25),
      offset: const Offset(0, 4),
      blurRadius: 4,
    ),
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.10),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Shadow untuk tombol taktil 3D (bottom lip 3.5px fisik bernuansa kayu).
  static List<BoxShadow> button(Color shadowColor) => [
    BoxShadow(
      color: shadowColor,
      offset: const Offset(0, 3.5),
      blurRadius: 0,
    ),
  ];

  /// State tombol saat ditekan (shadow menghilang rata permukaan).
  static const List<BoxShadow> pressed = [];

  /// Path gambar kanvas latar belakang splash screen.
  static const String splashCanvasBackground = AppAssets.splashCanvasBackground;
}

/// Helper konversi derajat ke radian.
double degreesToRadians(double degrees) => degrees * (3.14159265359 / 180);

/// Sumber kebenaran tunggal untuk path aset visual aplikasi iTHUNG.
class AppAssets {
  AppAssets._();

  // Custom Navigation Icons
  static const String icProfile = 'assets/icon/ic_profile.png';
  static const String icLead = 'assets/icon/ic_lead.png';
  static const String icDaily = 'assets/icon/ic_daily.png';
  static const String icSettings = 'assets/icon/ic_settings.png';
  static const String appLauncher = 'assets/icon/app_launcher.png';

  // Preset Avatars (assets/images/avatar/avatar_0.png .. avatar_8.png)
  static const List<String> avatarPresets = [
    'assets/images/avatar/avatar_0.png',
    'assets/images/avatar/avatar_1.png',
    'assets/images/avatar/avatar_2.png',
    'assets/images/avatar/avatar_3.png',
    'assets/images/avatar/avatar_4.png',
    'assets/images/avatar/avatar_5.png',
    'assets/images/avatar/avatar_6.png',
    'assets/images/avatar/avatar_7.png',
    'assets/images/avatar/avatar_8.png',
  ];

  /// Mengembalikan path aset avatar berdasarkan ID (misal: 'avatar_0' -> 'assets/images/avatar/avatar_0.png').
  /// Mengembalikan null jika [avatarId] kosong atau null.
  static String? avatarPath(String? avatarId) {
    if (avatarId == null || avatarId.isEmpty) return null;
    final match = avatarPresets.where((p) => p.contains(avatarId)).firstOrNull;
    return match ?? avatarId;
  }

  /// Pose Karakter 2D Full-body Avatar 7 (Burung Cendekia)
  static const String characterAvatar7Idle = 'assets/images/characters/avatar_7_idle.png';
  static const String characterAvatar7Think = 'assets/images/characters/avatar_7_think.png';
  static const String characterAvatar7Cheer = 'assets/images/characters/avatar_7_cheer.png';

  /// Daftar pose siklus animasi Avatar 7
  static const List<String> characterAvatar7Poses = [
    characterAvatar7Idle,
    characterAvatar7Think,
    characterAvatar7Cheer,
  ];

  // Legacy (dijaga agar backward-compatible bila ada referensi lama)
  static const String woodTokenLocked = 'assets/images/wood_token_locked.png';
  static const String woodTokenChecked = 'assets/images/wood_token_checked.png';
  static const String woodTokenPlay = 'assets/images/wood_token_play.png';
  static const String woodBoardSquare = 'assets/images/wood_board_square.png';
  static const String woodSignHanging = 'assets/images/wood_sign_hanging.png';

  // Background Canvases
  static const String splashCanvasBackground = 'assets/images/hill_canvas.png';
  static const String highPassCanvasBackground = 'assets/images/highPass_canvas.png';

  // Challenge 3D Icons
  static const String icChallengeGift = 'assets/images/challenges/ic_gift.png';
  static const String icChestClose = 'assets/images/challenges/ic_chest_close.png';
  static const String icChestOpen = 'assets/images/challenges/ic_chest_open.png';
  static const String icChallengeCoins = 'assets/images/challenges/ic_coins.png';
  static const String icChallengeTrophy = 'assets/images/challenges/ic_trophy.png';
  static const String icChallengeCrown = 'assets/images/challenges/ic_crown.png';
  static const String icChallengeDiamond = 'assets/images/challenges/ic_diamond.png';
  static const String icChallengePlay = 'assets/images/challenges/ic_play.png';
  static const String icChallengePause = 'assets/images/challenges/ic_pause.png';
  static const String icChallengeSpeed = 'assets/images/challenges/ic_speed.png';
  static const String icChallengeSettings = 'assets/images/challenges/ic_settings.png';
  static const String icChallengeBack = 'assets/images/challenges/ic_back.png';
  static const String icChallengeReplay = 'assets/images/challenges/ic_replay.png';
  static const String icChallengeHome = 'assets/images/challenges/ic_home.png';
  static const String icChallengeHeart = 'assets/images/challenges/ic_heart.png';
  static const String icChallengeLightning = 'assets/images/challenges/ic_lightning.png';
  static const String icChallengeStar = 'assets/images/challenges/ic_star.png';
  static const String icChallengeShop = 'assets/images/challenges/ic_shop.png';
}

