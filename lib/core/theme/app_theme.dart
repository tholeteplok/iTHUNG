import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Konfigurasi tema global terpusat untuk aplikasi iTHUNG.
///
/// Keputusan tipografi:
/// - **Quicksand**: Font UI utama, headline, body, label (kesan playful & ramah)
/// - **JetBrains Mono**: Font angka matematika dan tabular numerals (sejajar & presisi)
class AppTheme {
  AppTheme._();

  // ── Palet Warna Terpusat (Cozy Warm Stationery & Woodwork) ────────
  /// Teks utama dan outline kontras ramah mata (menggantikan hitam pekat).
  static const Color colorEspresso = Color(0xFF3A2E2B);

  /// Teks sekunder, label, dan elemen pendukung.
  static const Color colorTaupe = Color(0xFF8F7E6D);

  /// Aksen primer brand (bintang, streak, tab aktif).
  static const Color colorHoney = Color(0xFFF6C443);

  /// Aksen kayu gelap (bayangan & aksen serat kayu).
  static const Color colorWoodDark = Color(0xFF633B1D);

  /// Aksen kayu hangat / gantungan binder kalender (saddle brown).
  static const Color colorWoodMedium = Color(0xFF9C663D);

  /// Aksen kayu muda / highlight kayu pine.
  static const Color colorWoodLight = Color(0xFFDDB988);

  /// Border kayu tegas untuk plang dan kontainer kayu.
  static const Color colorWoodBorder = Color(0xFF87532A);

  /// Warna isian permukaan papan kayu.
  static const Color colorWoodPlank = Color(0xFFF4E5CA);

  /// Permukaan kertas putih bersih khusus soal matematika.
  static const Color colorPaperWhite = Color(0xFFFFFFFF);

  /// Permukaan kartu vanilla cream hangat untuk UI non-game.
  static const Color colorVanillaCard = Color(0xFFFFFDF7);

  /// Latar belakang kanvas dasar hangat (warm oatmeal/sandy cream).
  static const Color colorSandyCanvas = Color(0xFFF4EBD0);

  /// Warna sukses / jawaban benar / forest sage green.
  static const Color colorSage = Color(0xFF5E9E52);

  /// Warna peringatan / wrong / terracotta coral.
  static const Color colorCoral = Color(0xFFE26D50);

  /// Border color default terpusat (menggunakan cokelat kayu hangat ramah mata).
  static const Color darkBorder = colorWoodMedium;

  /// Divider kayu halus untuk pemisah baris list tanpa kartu (cardless clean row).
  static const Color colorWoodDivider = Color(0x2E9C663D);

  // ── Token semantik tersentralisasi (hasil audit UI) ───────────────
  /// Permukaan kartu semi transparan untuk HUD game (Streak, XP, Sound, Callout Pin).
  static const Color colorTranslucentSurface = Color(0xD8FFFDF7);

  /// Border kayu medium semi transparan (~30% alpha) untuk kartu semi transparan tanpa bayangan.
  static const Color colorTranslucentBorder = Color(0x4D9C663D);

  /// Border kayu medium semi transparan (~50% alpha) untuk penegasan elemen semi transparan aktif.
  static const Color colorTranslucentBorderFocus = Color(0x809C663D);

  /// Border cream kartu vanilla / border kayu terpusat.
  static const Color colorCardBorder = colorWoodMedium;

  /// Hijau sukses tegas (menggantikan literal 0xFF2E7D32).
  static const Color colorSuccess = Color(0xFF2E7D32);

  /// Latar hijau lembut (menggantikan literal 0xFFE8F5E9).
  static const Color colorSuccessSoft = Color(0xFFE8F5E9);

  /// Merah bahaya tegas (menggantikan literal 0xFFD32F2F).
  static const Color colorDanger = Color(0xFFD32F2F);

  /// Latar merah lembut (menggantikan literal 0xFFFFF2EE).
  static const Color colorDangerSoft = Color(0xFFFFF2EE);

  /// Fallback kanvas saat theme provider belum siap.
  static const Color fallbackCanvas = Color(0xFFEAF3DE);

  /// Fallback aksen saat theme provider belum siap.
  static const Color fallbackAccent = Color(0xFF639922);

  /// Badge status tamu / anonim / info.
  static const Color badgeGuestBg = Color(0xFFF3EDD9);
  static const Color badgeInfoBg = Color(0xFFE5F1F8);
  static const Color badgeInfoFg = Color(0xFF2C6D9E);

  // ── Token Warna Pastel Priority Dot (Catatan Rilis Ramah) ─────────
  /// Pastel Coral untuk Perbaikan Masalah Penting (Bugfix, koneksi, auth).
  static const Color colorPastelCoral = Color(0xFFF29994);

  /// Pastel Sage untuk Fitur & Konten Baru.
  static const Color colorPastelSage = Color(0xFF94C9A9);

  /// Pastel Honey untuk Peningkatan Performa (kecepatan, hemat daya).
  static const Color colorPastelHoney = Color(0xFFF6D075);

  /// Pastel Sky untuk Penyempurnaan Tampilan & UX (visual, tata letak).
  static const Color colorPastelSky = Color(0xFF92BFDD);

  /// Pastel Clay untuk Peningkatan Kenyamanan & Kestabilan Umum.
  static const Color colorPastelClay = Color(0xFFC8B8AB);

  // ── Warna Balok Podium (Harmonis dengan Badge Lingkaran Peringkat) ──
  /// Balok Podium 1: Emas lembut matching badge rank 1 (#FFD54F).
  static const Color colorPodiumGold = Color(0xFFFFE28A);

  /// Balok Podium 2: Perak lembut matching badge rank 2 (#E0E0E0).
  static const Color colorPodiumSilver = Color(0xFFE6E9EC);

  /// Balok Podium 3: Perunggu peach lembut matching badge rank 3 (#FFCCBC).
  static const Color colorPodiumBronze = Color(0xFFFFD5C8);

  /// Menghasilkan [ThemeData] utama aplikasi.
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.quicksandTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colorSandyCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorHoney,
        primary: colorHoney,
        secondary: colorWoodMedium,
        tertiary: colorCoral,
        surface: colorSandyCanvas,
      ),
      textTheme: baseTextTheme.copyWith(
        // Headline & Title memakai Quicksand bold warna Espresso
        displayLarge: GoogleFonts.quicksand(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: colorEspresso,
        ),
        displayMedium: GoogleFonts.quicksand(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: colorEspresso,
        ),
        titleLarge: GoogleFonts.quicksand(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorEspresso,
        ),
        titleMedium: GoogleFonts.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorEspresso,
        ),
        bodyLarge: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorEspresso,
        ),
        bodyMedium: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorEspresso,
        ),
      ),
    );
  }

  /// TextStyle khusus untuk angka soal aritmatika dan opsi jawaban di gameplay.
  ///
  /// Menggunakan font [JetBrainsMono] lokal yang di-bundle di assets
  /// agar glif matematika (seperti ×, ÷, −, +) dan tabular numerals selalu konsisten,
  /// 100% offline, dan bebas dari substitusi/fallback OEM Android font.
  static TextStyle mathNumberStyle({
    double fontSize = 38,
    FontWeight fontWeight = FontWeight.w800,
    Color color = colorEspresso,
  }) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.5,
    );
  }

  /// TextStyle untuk timer & angka statistik ringkas.
  static TextStyle statNumberStyle({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color color = colorEspresso,
  }) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// TextStyle untuk tombol jawaban grid 2x2.
  static TextStyle answerButtonStyle({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w700,
    Color color = colorEspresso,
  }) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Family font brand "iTHUNG" tersentralisasi (Coffee Spark).
  static const String brandFontFamily = 'CoffeeSpark';

  /// TextStyle khusus untuk nama brand aplikasi "iTHUNG" menggunakan font kustom Coffee Spark.
  static TextStyle brandTitleStyle({
    double fontSize = 62,
    Color color = colorHoney,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: brandFontFamily,
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// TextStyle outline stroke untuk nama brand aplikasi "iTHUNG".
  static TextStyle brandOutlineStyle({
    double fontSize = 66,
    double strokeWidth = 5.2,
    Color color = colorWoodDark,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: brandFontFamily,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = color,
    );
  }

  /// Family font judul AppBar/Header tersentralisasi (Catboo).
  static const String headerFontFamily = 'Catboo';

  /// TextStyle judul AppBar/Header — dipakai [AppHeader] dan semua
  /// header manual agar konsisten (font Catboo, tanpa hardcode di widget).
  static TextStyle headerTitleStyle({
    double fontSize = 19,
    FontWeight fontWeight = FontWeight.w800,
    Color color = colorWoodMedium,
  }) {
    return TextStyle(
      fontFamily: headerFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0,
    );
  }
}
