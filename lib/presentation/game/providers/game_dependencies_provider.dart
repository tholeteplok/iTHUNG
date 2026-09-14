import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/hive_audio_settings_repository.dart';
import '../../../data/local/hive_challenge_score_repository.dart';
import '../../../data/local/hive_daily_challenge_repository.dart';
import '../../../data/local/hive_event_log.dart';
import '../../../domain/repositories/audio_settings_repository.dart';
import '../../../domain/repositories/challenge_score_repository.dart';
import '../../../data/local/hive_level_score_repository.dart';
import '../../../data/local/hive_mastery_repository.dart';
import '../../../data/local/hive_player_repository.dart';
import '../../../data/local/hive_session_repository.dart';
import '../../../data/remote/firebase_auth_repository.dart';
import '../../../data/remote/firebase_leaderboard_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/daily_challenge_repository.dart';
import '../../../domain/repositories/leaderboard_repository.dart';
import '../../../domain/repositories/level_score_repository.dart';
import '../../../domain/repositories/mastery_repository.dart';
import '../../../domain/repositories/player_repository.dart';
import '../../../domain/repositories/session_repository.dart';
import '../../../domain/services/dda_engine.dart';
import '../../../domain/services/distractor_generator.dart';
import '../../../domain/services/mastery_update_service.dart';
import '../../../domain/services/question_generator.dart';
import '../../../domain/services/scoring_service.dart';

// ── Repository Providers ──────────────────────────────────────────────────

final masteryRepositoryProvider = Provider<MasteryRepository>((ref) {
  return HiveMasteryRepository();
});

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return HivePlayerRepository();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return HiveSessionRepository();
});

final dailyChallengeRepositoryProvider = Provider<DailyChallengeRepository>((
  ref,
) {
  return HiveDailyChallengeRepository();
});

final levelScoreRepositoryProvider = Provider<LevelScoreRepository>((ref) {
  return HiveLevelScoreRepository();
});

final challengeScoreRepositoryProvider =
    Provider<ChallengeScoreRepository>((ref) {
  return HiveChallengeScoreRepository();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return FirebaseLeaderboardRepository();
});

final eventLogProvider = Provider<HiveEventLog>((ref) {
  return HiveEventLog();
});

final audioSettingsRepositoryProvider =
    Provider<AudioSettingsRepository>((ref) {
  return HiveAudioSettingsRepository();
});

// ── Domain Service Providers ──────────────────────────────────────────────

final questionGeneratorProvider = Provider<QuestionGenerator>((ref) {
  return const QuestionGenerator();
});

final distractorGeneratorProvider = Provider<DistractorGenerator>((ref) {
  return const DistractorGenerator();
});

final ddaEngineProvider = Provider<DdaEngine>((ref) {
  return const DdaEngine();
});

final scoringServiceProvider = Provider<ScoringService>((ref) {
  return const ScoringService();
});

final masteryUpdateServiceProvider = Provider<MasteryUpdateService>((ref) {
  return MasteryUpdateService(ref.watch(masteryRepositoryProvider));
});
