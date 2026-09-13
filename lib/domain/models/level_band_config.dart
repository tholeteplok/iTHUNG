/// Model konfigurasi Level Band (rentang level, warna tema hex, timer dasar, operasi).
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
/// File JSON `assets/level_bands.json` adalah satu-satunya sumber kebenaran.
library;

import 'question.dart';

/// Data konfigurasi satu level band.
///
/// Menyimpan rentang level, daftar operasi aritmatika yang diizinkan,
/// rentang digit, timer dasar (detik), dan kode warna hex kanvas/aksen.
class LevelBand {
  const LevelBand({
    required this.id,
    required this.levelStart,
    this.levelEnd,
    required this.operations,
    required this.digitRange,
    required this.timerBaseSec,
    required this.canvasColorHex,
    required this.canvasColorEndHex,
    required this.accentColorHex,
  });

  /// ID unik band (mis. 'onboarding', 'basic', 'intermediate', 'advanced', 'expert').
  final String id;

  /// Level awal dari band ini (inklusif).
  final int levelStart;

  /// Level akhir dari band ini (inklusif).
  /// Bernilai `null` untuk band tak berbatas (mis. Expert level 51+).
  final int? levelEnd;

  /// Daftar operasi matematika yang diperkenalkan/diizinkan pada band ini.
  final List<Operation> operations;

  /// Rentang digit soal (mis. '1-digit', '1-2-digit', '2-digit', '3-digit').
  final String digitRange;

  /// Waktu timer dasar dalam detik (mis. 8.0, 6.0, 4.5, 3.5, 3.0).
  final double timerBaseSec;

  /// Kode warna hex latar kanvas level awal band (mis. '#EAF3DE').
  final String canvasColorHex;

  /// Kode warna hex latar kanvas level akhir band (mis. '#DCEACB').
  final String canvasColorEndHex;

  /// Kode warna hex aksen utama tombol dan timer (mis. '#639922').
  final String accentColorHex;

  /// Memeriksa apakah suatu angka [level] berada di dalam cakupan band ini.
  bool containsLevel(int level) {
    if (level < levelStart) return false;
    if (levelEnd == null) return true;
    return level <= levelEnd!;
  }

  /// Menghitung posisi relatif level di dalam rentang band (0.0 sampai 1.0).
  ///
  /// Digunakan oleh layer presentasi untuk interpolasi warna kanvas dinamis.
  double progressInBand(int level) {
    if (level <= levelStart) return 0.0;
    if (levelEnd == null) return 0.5;
    if (level >= levelEnd!) return 1.0;
    final total = levelEnd! - levelStart;
    if (total <= 0) return 0.0;
    return (level - levelStart) / total;
  }

  /// Nama tampilan zona resmi bioma petualangan iTHUNG (tersentralisasi).
  String get displayName => switch (id) {
        'onboarding' => 'Fresh Sprout Meadow',
        'basic' => 'Golden Sun Canyon',
        'intermediate' => 'Coral Sunset Ridge',
        'advanced' => 'Twilight Forest',
        'expert' => 'Cosmic Mystic Peak',
        _ => id.isEmpty
            ? 'Zona'
            : '${id[0].toUpperCase()}${id.substring(1)}',
      };

  /// Label rentang level zona, mis. "Level 6–15" atau "Level 51+".
  String get rangeLabel => levelEnd == null
      ? 'Level $levelStart+'
      : 'Level $levelStart–$levelEnd';

  /// Total level dalam zona. `null` untuk zona tanpa batas (expert).
  int? get levelsTotal =>
      levelEnd == null ? null : (levelEnd! - levelStart + 1);

  /// Jumlah level zona yang sudah dilewati pemain pada [level] saat ini.
  int levelsCompleted(int level) {
    final total = levelsTotal;
    if (total == null) return 0;
    return (level - levelStart + 1).clamp(0, total);
  }

  /// Fraksi progres zona 0.0–1.0 berdasarkan level yang dilewati.
  /// Zona tanpa batas mengembalikan `null` (ditangani caller via fallback XP).
  double? progressFraction(int level) {
    final total = levelsTotal;
    if (total == null || total <= 0) return null;
    return (levelsCompleted(level) / total).clamp(0.0, 1.0);
  }

  /// Membuat [LevelBand] dari Map JSON.
  factory LevelBand.fromJson(Map<String, dynamic> json) {
    int start;
    int? end;

    if (json.containsKey('level_range')) {
      final range = json['level_range'] as List<dynamic>;
      start = (range[0] as num).toInt();
      end = (range[1] as num?)?.toInt();
    } else {
      start = ((json['level_start'] ?? json['levelStart'] ?? 1) as num).toInt();
      end = (json['level_end'] ?? json['levelEnd']) as int?;
    }

    final operationsRaw = (json['operations'] as List<dynamic>?) ?? <dynamic>[];
    final operationsList = operationsRaw
        .map((e) => Operation.fromJson(e as String))
        .toList();

    return LevelBand(
      id: json['id'] as String,
      levelStart: start,
      levelEnd: end,
      operations: operationsList,
      digitRange:
          (json['digit_range'] ?? json['digitRange'] ?? '1-digit') as String,
      timerBaseSec:
          ((json['timer_base_sec'] ?? json['timerBaseSec'] ?? 6.0) as num)
              .toDouble(),
      canvasColorHex:
          (json['canvas_color'] ??
                  json['canvas_color_hex'] ??
                  json['canvasColorHex'])
              as String,
      canvasColorEndHex:
          (json['canvas_color_end'] ??
                  json['canvas_color_end_hex'] ??
                  json['canvasColorEndHex'] ??
                  json['canvas_color'] ??
                  json['canvas_color_hex'])
              as String,
      accentColorHex:
          (json['accent_color'] ??
                  json['accent_color_hex'] ??
                  json['accentColorHex'])
              as String,
    );
  }

  /// Serialisasi ke Map JSON yang identik dengan format `assets/level_bands.json`.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level_range': [levelStart, levelEnd],
      'operations': operations.map((op) => op.toJson()).toList(),
      'digit_range': digitRange,
      'timer_base_sec': timerBaseSec,
      'canvas_color': canvasColorHex,
      'canvas_color_end': canvasColorEndHex,
      'accent_color': accentColorHex,
    };
  }

  /// Membuat salinan objek dengan field yang dimodifikasi.
  LevelBand copyWith({
    String? id,
    int? levelStart,
    int? levelEnd,
    List<Operation>? operations,
    String? digitRange,
    double? timerBaseSec,
    String? canvasColorHex,
    String? canvasColorEndHex,
    String? accentColorHex,
  }) {
    return LevelBand(
      id: id ?? this.id,
      levelStart: levelStart ?? this.levelStart,
      levelEnd: levelEnd ?? this.levelEnd,
      operations: operations ?? this.operations,
      digitRange: digitRange ?? this.digitRange,
      timerBaseSec: timerBaseSec ?? this.timerBaseSec,
      canvasColorHex: canvasColorHex ?? this.canvasColorHex,
      canvasColorEndHex: canvasColorEndHex ?? this.canvasColorEndHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LevelBand || runtimeType != other.runtimeType) return false;

    if (id != other.id ||
        levelStart != other.levelStart ||
        levelEnd != other.levelEnd ||
        digitRange != other.digitRange ||
        timerBaseSec != other.timerBaseSec ||
        canvasColorHex != other.canvasColorHex ||
        canvasColorEndHex != other.canvasColorEndHex ||
        accentColorHex != other.accentColorHex ||
        operations.length != other.operations.length) {
      return false;
    }

    for (var i = 0; i < operations.length; i++) {
      if (operations[i] != other.operations[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    levelStart,
    levelEnd,
    Object.hashAll(operations),
    digitRange,
    timerBaseSec,
    canvasColorHex,
    canvasColorEndHex,
    accentColorHex,
  );

  @override
  String toString() =>
      'LevelBand(id: $id, range: [$levelStart, $levelEnd], timer: ${timerBaseSec}s)';
}

/// Wadah seluruh koleksi [LevelBand] hasil parse dari `assets/level_bands.json`.
class LevelBandsConfig {
  const LevelBandsConfig(this.bands);

  /// Daftar semua band yang terkonfigurasi secara berurutan.
  final List<LevelBand> bands;

  /// Factory untuk membuat [LevelBandsConfig] dari Map JSON.
  factory LevelBandsConfig.fromJson(Map<String, dynamic> json) {
    final list = (json['bands'] as List<dynamic>)
        .map((e) => LevelBand.fromJson(e as Map<String, dynamic>))
        .toList();
    return LevelBandsConfig(list);
  }

  /// Helper statis untuk mem-parse Map JSON.
  static LevelBandsConfig parse(Map<String, dynamic> json) =>
      LevelBandsConfig.fromJson(json);

  /// Mencari [LevelBand] yang menaungi [level] tertentu.
  ///
  /// Mengembalikan band terakhir (mis. Expert) sebagai fallback jika di luar rentang.
  LevelBand bandForLevel(int level) {
    for (final band in bands) {
      if (band.containsLevel(level)) {
        return band;
      }
    }
    return bands.last;
  }

  /// Mencari [LevelBand] berdasarkan [id]-nya.
  LevelBand? bandById(String id) {
    for (final band in bands) {
      if (band.id == id) {
        return band;
      }
    }
    return null;
  }

  /// Serialisasi ke Map JSON.
  Map<String, dynamic> toJson() {
    return {'bands': bands.map((b) => b.toJson()).toList()};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LevelBandsConfig || runtimeType != other.runtimeType) {
      return false;
    }

    if (bands.length != other.bands.length) return false;
    for (var i = 0; i < bands.length; i++) {
      if (bands[i] != other.bands[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hashAll(bands);

  @override
  String toString() => 'LevelBandsConfig(bands: ${bands.length})';
}
