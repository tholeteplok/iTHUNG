import 'package:flutter/widgets.dart' show IconData;
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

/// Sumber kebenaran tunggal untuk semua ikon di aplikasi.
///
/// Widget TIDAK BOLEH memanggil `TablerIcons.xxx` secara langsung — selalu melalui
/// `AppIcons.xxx` agar konsisten dan mudah di-maintain.
class AppIcons {
  AppIcons._();

  // ── Game Play Screen ────────────────────────────────────────────

  /// Badge streak harian di header gameplay.
  static const IconData streak = TablerIcons.flame;

  /// Badge XP/poin akun di header gameplay.
  static const IconData xp = TablerIcons.star;

  // ── Home / Peta Level Screen ────────────────────────────────────

  /// Badge streak di header home.
  static const IconData homeStreak = TablerIcons.flame;

  /// Badge XP di header home.
  static const IconData homeXp = TablerIcons.star;

  /// Node level yang sedang aktif — tombol "lanjut main".
  static const IconData levelActive = TablerIcons.playerPlay;

  /// Node level yang sudah diselesaikan (checkmark hijau).
  static const IconData levelCompleted = TablerIcons.check;

  /// Node level yang masih terkunci.
  static const IconData levelLocked = TablerIcons.lock;

  // ── Session Results Screen ──────────────────────────────────────

  /// Banner "streak harian dipertahankan" di layar hasil sesi.
  static const IconData streakMaintained = TablerIcons.flame;

  // ── Feedback Overlay ────────────────────────────────────────────

  /// Overlay saat jawaban benar.
  static const IconData answerCorrect = TablerIcons.circleCheck;

  /// Overlay saat jawaban salah atau timeout.
  static const IconData answerWrong = TablerIcons.circleX;

  // ── Tambahan Menu & Profil ──────────────────────────────────────

  /// Ikon avatar profil.
  static const IconData profile = TablerIcons.user;

  /// Ikon akurasi di kartu statistik.
  static const IconData accuracyStat = TablerIcons.target;

  /// Ikon waktu respon di kartu statistik.
  static const IconData timeStat = TablerIcons.clock;

  /// Ikon kalender / daily challenge.
  static const IconData calendar = TablerIcons.calendarEvent;

  /// Ikon papan peringkat / piala.
  static const IconData trophy = TablerIcons.trophy;

  /// Ikon mahkota juara 1.
  static const IconData crown = TablerIcons.crown;

  /// Ikon pengaturan.
  static const IconData settings = TablerIcons.settings;

  /// Ikon kembali.
  static const IconData back = TablerIcons.arrowLeft;

  /// Ikon cloud sync.
  static const IconData cloudSync = TablerIcons.cloudUpload;

  /// Ikon perisai keamanan.
  static const IconData shield = TablerIcons.shieldCheck;

  /// Ikon tanda centang.
  static const IconData check = TablerIcons.check;

  /// Ikon bintang.
  static const IconData star = TablerIcons.star;

  /// Ikon timer / waktu.
  static const IconData timer = TablerIcons.clock;

  /// Ikon lidah api streak.
  static const IconData streakFlame = TablerIcons.flame;

  // ── Adventure Map & Milestones ──────────────────────────────────

  /// Ikon peti harta karun milestone.
  static const IconData chest = TablerIcons.gift;

  /// Bintang terisi (skor riil completed level).
  static const IconData starFilled = TablerIcons.starFilled;

  /// Bintang kosong.
  static const IconData starEmpty = TablerIcons.star;

  /// Sparkle efek reward.
  static const IconData sparkles = TablerIcons.sparkles;

  /// Ikon peringatan / error banner.
  static const IconData warning = TablerIcons.alertCircle;

  /// Ikon edit / pensil.
  static const IconData edit = TablerIcons.pencil;

  // ── Session Results Action Buttons ──────────────────────────────

  /// Ikon beranda pada ResultsScreen.
  static const IconData home = TablerIcons.home;

  /// Ikon ulangi / replay level pada ResultsScreen.
  static const IconData replay = TablerIcons.rotate;

  /// Ikon level berikutnya pada ResultsScreen.
  static const IconData nextLevel = TablerIcons.arrowRight;

  // ── In-App Updater ──────────────────────────────────────────────

  /// Ikon roket / pembaruan tersedia.
  static const IconData rocket = TablerIcons.rocket;

  /// Ikon unduh pembaruan.
  static const IconData download = TablerIcons.cloudDownload;

  /// Ikon prosesor / arsitektur ABI.
  static const IconData cpu = TablerIcons.cpu;

  /// Ikon segarkan / periksa pembaruan.
  static const IconData refresh = TablerIcons.refresh;

  /// Ikon keluar akun / logout.
  static const IconData logout = TablerIcons.logout;
}
