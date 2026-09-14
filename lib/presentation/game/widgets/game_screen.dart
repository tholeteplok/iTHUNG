import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/level_score_record.dart';
import '../../../domain/models/session_result.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../../domain/services/scoring_service.dart';
import '../../home/providers/level_stars_provider.dart';
import '../../home/providers/player_profile_provider.dart';
import '../../leaderboard/providers/leaderboard_provider.dart';
import '../../profile/providers/account_status_provider.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/exit_confirm_dialog.dart';
import '../providers/game_session_provider.dart';
import '../providers/level_band_theme_provider.dart';
import '../state/game_session_state.dart';
import '../../game/providers/game_dependencies_provider.dart';
import 'answer_grid.dart';
import 'countdown_progress_bar.dart';
import 'feedback_overlay.dart';
import 'question_display.dart';

/// Layar utama sesi permainan cepat (Speed Math Gameplay).
///
/// Menyatukan seluruh alur gameplay loop:
/// - Soal muncul (ShowQuestion) -> Timer & opsi aktif (Active) -> Jawaban (Feedback) -> Hasil (SessionEnded).
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    this.mode = GameMode.normal,
  });

  final int level;
  final GameMode mode;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final GameSessionArgs _args;

  @override
  void initState() {
    super.initState();
    _args = GameSessionArgs(level: widget.level, mode: widget.mode);
  }

  Future<bool> _handleWillPop() async {
    final notifier = ref.read(gameSessionProvider(_args).notifier);
    final state = ref.read(gameSessionProvider(_args));

    if (state is FeedbackState) {
      return false; // Jangan biarkan keluar di tengah animasi umpan balik
    }

    if (state is ActiveState || state is ShowQuestionState) {
      notifier.pause();
      final shouldExit = await showExitConfirmDialog(context);
      if (!shouldExit) {
        notifier.resume();
        return false;
      }
      return true;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(gameSessionProvider(_args));
    final themeAsync = ref.watch(levelBandThemeProvider);
    final profile = ref.watch(playerProfileProvider).valueOrNull;

    final canvasColor =
        themeAsync.valueOrNull?.canvasColor ?? AppTheme.fallbackCanvas;
    final accentColor =
        themeAsync.valueOrNull?.accentColor ?? AppTheme.fallbackAccent;

    // Dengarkan saat sesi selesai untuk navigasi otomatis ke /results
    ref.listen<GameSessionState>(gameSessionProvider(_args), (prev, next) {
      if (next is SessionEndedState) {
        final previousProfile = ref.read(playerProfileProvider).valueOrNull;
        final previousLevel = previousProfile?.currentLevel ?? 1;
        final previousStars =
            ref.read(levelStarsProvider).valueOrNull?[widget.level] ?? 0;

        // Simpan hasil sesi secara atomik (XP + kenaikan level)
        ref.read(playerProfileProvider.notifier).completeSession(
              playedLevel: widget.level,
              xpEarned: next.result.xpEarned,
              accuracy: next.result.accuracy,
            );

        // Perbarui bintang level secara instan di memori (0 ms delay)
        ref.read(levelStarsProvider.notifier).recordStars(
              level: widget.level,
              accuracy: next.result.accuracy,
            );

        // Catat rekor skor level & terapkan best-score delta, lalu dorong
        // total terbaru ke cloud agar tab Semua Waktu sinkron (max-safety).
        (() async {
          try {
            final deltaResult = await ref
                .read(playerProfileProvider.notifier)
                .recordLevelScore(
                  level: widget.level,
                  sessionScore: next.result.totalScore,
                  accuracy: next.result.accuracy,
                );

            if (context.mounted) {
              final enrichedResult = next.result.copyWith(
                scoreDelta: deltaResult.scoreDelta,
                previousBestScore: deltaResult.previousBestScore,
              );
              context.go('/results', extra: enrichedResult);
            }

            final accountState =
                ref.read(accountStatusProvider).valueOrNull;
            final username = accountState?.username;
            if (username == null || username.isEmpty) return;
            final latest =
                ref.read(playerProfileProvider).valueOrNull;
            if (latest == null) return;

            if (deltaResult.scoreDelta > 0) {
              // Injeksi update optimistik seketika ke papan peringkat all-time
              ref.read(allTimeEntriesProvider.notifier).addOptimisticScore(
                    username: username,
                    newTotalScore: latest.totalScore,
                    avatarId: latest.avatarId,
                  );
            }

            final isRecordBroken = deltaResult.scoreDelta > 0;
            final isFirstPlay = deltaResult.isFirstPlay;
            final didLevelUp = latest.currentLevel > previousLevel;
            final newStars = ScoringService.calculateStars(next.result.accuracy);
            final didEarnNewStars = newStars > previousStars;

            // Cost-Efficient Cloud Writes:
            // Hanya bakar kuota Firestore jika ada pencapaian prestasi baru yang signifikan
            // (pecah rekor skor, main pertama kali, naik level, atau tambah bintang).
            // Replay biasa yang tidak memecahkan rekor = 0 write ke Firestore.
            if (isRecordBroken || isFirstPlay || didLevelUp || didEarnNewStars) {
              // Ambil seluruh rekor level lokal untuk disinkronkan ke cloud
              final scoreRepo = ref.read(levelScoreRepositoryProvider);
              final recordsResult = await scoreRepo.getAllRecords();
              final Map<String, dynamic> levelRecordsPayload = {};
              if (recordsResult is RepoSuccess<Map<int, LevelScoreRecord>>) {
                for (final entry in recordsResult.value.entries) {
                  levelRecordsPayload[entry.key.toString()] = entry.value.toJson();
                }
              }

              // Sync progres lengkap (skor, level, xp, dan rekor per level) ke cloud profil pemain
              await ref.read(leaderboardRepositoryProvider).syncProfileProgress(
                    username: username,
                    avatarId: latest.avatarId,
                    totalScore: latest.totalScore,
                    currentLevel: latest.currentLevel,
                    totalXp: latest.totalXp,
                    levelRecords: levelRecordsPayload.isNotEmpty ? levelRecordsPayload : null,
                  );

              // Invalidate allTimeEntriesProvider agar daftar all-time selalu fresh saat dibuka
              ref.invalidate(allTimeEntriesProvider);
            }
          } catch (_) {
            // Jika terjadi kegagalan lokal tidak terduga, tetap navigasikan ke results
            if (context.mounted) {
              context.go('/results', extra: next.result);
            }
          }
        })();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handleWillPop();
        if (shouldPop && context.mounted) {
          context.go('/');
        }
      },
      child: MediaQuery(
        // Cap text scaling agar layout grid gameplay tidak patah pada text scaling OS ekstrem
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.of(
              context,
            ).textScaler.scale(1.0).clamp(1.0, AppTokens.maxTextScaleGameplay),
          ),
        ),
        child: Scaffold(
          backgroundColor: canvasColor,
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      // Header: Streak & XP
                      AppHeader(
                        streak: profile?.streak.currentStreak ?? 0,
                        xp: profile?.totalXp ?? 0,
                        onBackTap: () async {
                          final shouldPop = await _handleWillPop();
                          if (shouldPop && context.mounted) {
                            context.go('/');
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Countdown Progress Bar
                      _buildTimerBar(sessionState, accentColor),
                      const SizedBox(height: 24),

                      // Area Tampilan Soal
                      _buildQuestionArea(sessionState),
                      const SizedBox(height: 28),

                      // Grid Tombol Jawaban (2x2)
                      Expanded(child: _buildAnswerArea(sessionState)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Feedback Overlay saat submit jawaban
              if (sessionState is FeedbackState)
                FeedbackOverlay(
                  isCorrect: sessionState.isCorrect,
                  roundScore: sessionState.roundScore,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBar(GameSessionState state, Color accentColor) {
    if (state is ActiveState) {
      final initialProgress = state.totalTimeMs > 0
          ? (state.timeRemainingMs / state.totalTimeMs).clamp(0.0, 1.0)
          : 1.0;
      return CountdownProgressBar(
        key: ValueKey('${state.question.id}_${state.totalTimeMs}'),
        resetToken: state.question.id,
        duration: Duration(milliseconds: state.totalTimeMs),
        initialProgress: initialProgress,
        primaryColor: accentColor,
        onTimeout: () {
          ref.read(gameSessionProvider(_args).notifier).handleTimeout();
        },
      );
    }

    // Default placeholder bar saat ShowQuestion / Feedback
    return Container(
      width: double.infinity,
      height: 16.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusBar),
        border: Border.all(
          color: const Color(0xFF232B1E),
          width: AppTokens.borderWidthDefault,
        ),
      ),
    );
  }

  Widget _buildQuestionArea(GameSessionState state) {
    final question = switch (state) {
      ShowQuestionState(:final question) => question,
      ActiveState(:final question) => question,
      FeedbackState(:final question) => question,
      PausedState(:final pausedFrom) => pausedFrom.question,
      SessionEndedState() => null,
    };

    if (question == null) return const SizedBox.shrink();

    return QuestionDisplay(key: ValueKey(question.id), question: question);
  }

  Widget _buildAnswerArea(GameSessionState state) {
    if (state is ActiveState) {
      return AnswerGrid(
        key: ValueKey(state.question.id),
        question: state.question,
        distractors: state.distractors,
        shuffledIndices: state.shuffledIndices,
        enabled: true,
        onAnswerSelected: (index) {
          ref.read(gameSessionProvider(_args).notifier).submitAnswer(index);
        },
      );
    }

    if (state is FeedbackState) {
      return AnswerGrid(
        key: ValueKey(state.question.id),
        question: state.question,
        distractors: state.distractors,
        shuffledIndices: state.shuffledIndices,
        enabled: false,
        onAnswerSelected: (_) {},
      );
    }

    if (state is PausedState) {
      return AnswerGrid(
        key: ValueKey(state.pausedFrom.question.id),
        question: state.pausedFrom.question,
        distractors: state.pausedFrom.distractors,
        shuffledIndices: state.pausedFrom.shuffledIndices,
        enabled: false,
        onAnswerSelected: (_) {},
      );
    }

    return const SizedBox.shrink();
  }
}
