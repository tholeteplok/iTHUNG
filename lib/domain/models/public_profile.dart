/// Domain model representasi profil publik pemain (view-only).
///
/// Tidak mengekspos informasi privat (email, token asuransi, internal DDA).
library;

class PublicProfile {
  const PublicProfile({
    required this.username,
    this.avatarId,
    required this.currentLevel,
    required this.totalScore,
    required this.totalXp,
    required this.longestStreak,
    this.factsMastered = 0,
    this.accuracy,
    this.createdAt,
  });

  /// Username pemain yang tampil di leaderboard.
  final String username;

  /// ID preset avatar pemain (mis. 'avatar_0' .. 'avatar_8', atau null jika inisial).
  final String? avatarId;

  /// Level permainan saat ini.
  final int currentLevel;

  /// Total akumulasi skor terbaik sepanjang masa.
  final int totalScore;

  /// Total akumulasi XP.
  final int totalXp;

  /// Rekor streak harian terpanjang.
  final int longestStreak;

  /// Jumlah fakta matematika yang telah dikuasai (jika tersinkronisasi).
  final int factsMastered;

  /// Rata-rata persentase akurasi pemain (0.0 - 100.0).
  final double? accuracy;

  /// Tanggal bergabung pertama kali.
  final DateTime? createdAt;

  /// Nama zona band berdasarkan level pemain.
  String get bandTitle {
    if (currentLevel <= 5) return 'Fresh Sprout Meadow (Zona 1)';
    if (currentLevel <= 15) return 'Golden Sun Canyon (Zona 2)';
    if (currentLevel <= 30) return 'Coral Sunset Ridge (Zona 3)';
    if (currentLevel <= 50) return 'Twilight Forest (Zona 4)';
    return 'Cosmic Mystic Peak (Zona 5)';
  }

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    final streakRaw = json['streak'];
    int streakVal = 0;
    if (streakRaw is Map) {
      streakVal = ((streakRaw['longest_streak'] ??
              streakRaw['longestStreak'] ??
              streakRaw['current_streak'] ??
              0) as num)
          .toInt();
    } else if (json['longest_streak'] != null) {
      streakVal = (json['longest_streak'] as num).toInt();
    }

    DateTime? parsedDate;
    final createdRaw = json['created_at'] ?? json['createdAt'];
    if (createdRaw != null) {
      parsedDate = DateTime.tryParse(createdRaw.toString());
    }

    double? parsedAccuracy;
    if (json['accuracy'] != null) {
      parsedAccuracy = (json['accuracy'] as num).toDouble();
    }

    return PublicProfile(
      username: (json['username'] ?? '') as String,
      avatarId: (json['avatar_id'] ?? json['avatarId']) as String?,
      currentLevel:
          ((json['current_level'] ?? json['currentLevel'] ?? 1) as num).toInt(),
      totalScore:
          ((json['total_score'] ?? json['totalScore'] ?? 0) as num).toInt(),
      totalXp: ((json['total_xp'] ?? json['totalXp'] ?? 0) as num).toInt(),
      longestStreak: streakVal,
      factsMastered:
          ((json['facts_mastered'] ?? json['factsMastered'] ?? 0) as num)
              .toInt(),
      accuracy: parsedAccuracy,
      createdAt: parsedDate,
    );
  }
}
