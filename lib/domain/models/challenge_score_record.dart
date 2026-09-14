/// Model untuk rekor skor terbaik pemain per mode tantangan dan level band.
///
/// File ini adalah Pure Dart dan tidak bergantung pada Flutter atau Riverpod.
class ChallengeScoreRecord {
  const ChallengeScoreRecord({
    required this.mode,
    required this.band,
    this.bestScore = 0,
    this.attempts = 0,
    this.updatedAt,
  });

  /// Mode tantangan (mis. 'blitz', 'marathon').
  final String mode;

  /// ID band saat tantangan dimainkan (mis. 'onboarding', 'basic', 'intermediate', 'advanced', 'expert').
  final String band;

  /// Skor tertinggi yang pernah diraih pada mode dan band ini.
  final int bestScore;

  /// Jumlah total percobaan yang pernah dilakukan pada mode dan band ini.
  final int attempts;

  /// Timestamp kapan rekor terakhir diperbarui.
  final DateTime? updatedAt;

  factory ChallengeScoreRecord.initial(String mode, String band) =>
      ChallengeScoreRecord(
        mode: mode,
        band: band,
        bestScore: 0,
        attempts: 0,
      );

  /// Terapkan hasil attempt baru â€” mengembalikan record baru dan delta skor jika memecahkan rekor.
  ({ChallengeScoreRecord record, int delta}) applyAttempt(int newScore) {
    final delta = (newScore - bestScore) > 0 ? newScore - bestScore : 0;
    return (
      record: ChallengeScoreRecord(
        mode: mode,
        band: band,
        bestScore: newScore > bestScore ? newScore : bestScore,
        attempts: attempts + 1,
        updatedAt: DateTime.now(),
      ),
      delta: delta,
    );
  }

  factory ChallengeScoreRecord.fromJson(Map<String, dynamic> json) {
    return ChallengeScoreRecord(
      mode: json['mode'] as String,
      band: json['band'] as String,
      bestScore: ((json['best_score'] ?? json['bestScore'] ?? 0) as num).toInt(),
      attempts: ((json['attempts'] ?? 0) as num).toInt(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'band': band,
    'best_score': bestScore,
    'attempts': attempts,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  ChallengeScoreRecord copyWith({
    String? mode,
    String? band,
    int? bestScore,
    int? attempts,
    DateTime? updatedAt,
  }) {
    return ChallengeScoreRecord(
      mode: mode ?? this.mode,
      band: band ?? this.band,
      bestScore: bestScore ?? this.bestScore,
      attempts: attempts ?? this.attempts,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeScoreRecord &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          band == other.band &&
          bestScore == other.bestScore &&
          attempts == other.attempts;

  @override
  int get hashCode => Object.hash(mode, band, bestScore, attempts);

  @override
  String toString() =>
      'ChallengeScoreRecord(mode: $mode, band: $band, best: $bestScore, attempts: $attempts)';
}