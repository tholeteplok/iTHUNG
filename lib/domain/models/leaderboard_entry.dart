/// Model untuk baris entri papan peringkat (LeaderboardEntry).
///
/// Menampilkan username (bukan email), skor benar, waktu tie-breaker,
/// rekor streak (untuk marathon), dan flag penanda pemain aktif.
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.username,
    this.avatarId,
    required this.correctCount,
    required this.totalTimeMs,
    required this.isCurrentPlayer,
    this.totalScore,
    this.streak,
  });

  /// Posisi peringkat (1-based index).
  final int rank;

  /// Username pemain (minimal 4 karakter, non-email).
  final String username;

  /// ID preset avatar pemain (mis. 'avatar_0' .. 'avatar_8', atau null jika inisial).
  final String? avatarId;

  /// Jumlah jawaban benar (skor daily challenge atau mode speed).
  final int correctCount;

  /// Total waktu penyelesaian dalam milidetik (tie-breaker).
  final int totalTimeMs;

  /// Menandai apakah entri ini milik pemain yang sedang login.
  final bool isCurrentPlayer;

  /// Akumulasi total skor sepanjang masa (hanya terisi di mode all-time, null di mode daily).
  final int? totalScore;

  /// Panjang rekor streak berturut-turut (khusus mode marathon).
  final int? streak;

  /// Format waktu dalam detik (mis. "24.5s").
  String get formattedTime => '${(totalTimeMs / 1000).toStringAsFixed(1)}s';

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: ((json['rank'] ?? 0) as num).toInt(),
      username: (json['username'] ?? 'Pemain') as String,
      avatarId: (json['avatar_id'] ?? json['avatarId']) as String?,
      correctCount:
          ((json['correct_count'] ?? json['correctCount'] ?? 0) as num).toInt(),
      totalTimeMs:
          ((json['total_time_ms'] ?? json['totalTimeMs'] ?? 0) as num).toInt(),
      isCurrentPlayer: (json['is_current_player'] ?? false) as bool,
      totalScore: json['total_score'] != null
          ? ((json['total_score']) as num).toInt()
          : null,
      streak: json['streak'] != null
          ? ((json['streak']) as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'username': username,
    'avatar_id': avatarId,
    'correct_count': correctCount,
    'total_time_ms': totalTimeMs,
    'is_current_player': isCurrentPlayer,
    if (totalScore != null) 'total_score': totalScore,
    if (streak != null) 'streak': streak,
  };

  LeaderboardEntry copyWith({
    int? rank,
    String? username,
    String? avatarId,
    bool clearAvatar = false,
    int? correctCount,
    int? totalTimeMs,
    bool? isCurrentPlayer,
    int? totalScore,
    int? streak,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      username: username ?? this.username,
      avatarId: clearAvatar ? null : (avatarId ?? this.avatarId),
      correctCount: correctCount ?? this.correctCount,
      totalTimeMs: totalTimeMs ?? this.totalTimeMs,
      isCurrentPlayer: isCurrentPlayer ?? this.isCurrentPlayer,
      totalScore: totalScore ?? this.totalScore,
      streak: streak ?? this.streak,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry &&
          runtimeType == other.runtimeType &&
          rank == other.rank &&
          username == other.username &&
          avatarId == other.avatarId &&
          correctCount == other.correctCount &&
          totalTimeMs == other.totalTimeMs &&
          totalScore == other.totalScore &&
          streak == other.streak &&
          isCurrentPlayer == other.isCurrentPlayer;

  @override
  int get hashCode => Object.hash(
    rank,
    username,
    avatarId,
    correctCount,
    totalTimeMs,
    totalScore,
    streak,
    isCurrentPlayer,
  );

  @override
  String toString() =>
      'LeaderboardEntry(#$rank, @$username, avatar: $avatarId, score: $correctCount, allTime: $totalScore, streak: $streak, time: $formattedTime, me: $isCurrentPlayer)';
}