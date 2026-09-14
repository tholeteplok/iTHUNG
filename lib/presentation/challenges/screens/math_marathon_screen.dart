import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/zone_constants.dart';
import '../../../core/services/sfx_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/models/challenge_score_record.dart';
import '../../../domain/models/distractor.dart';
import '../../../domain/models/question.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../../domain/services/scoring_service.dart';
import '../../game/providers/game_dependencies_provider.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../game/widgets/answer_grid.dart';
import '../../game/widgets/countdown_progress_bar.dart';
import '../../game/widgets/feedback_overlay.dart';
import '../../game/widgets/question_display.dart';
import '../../home/providers/player_profile_provider.dart';
import '../../leaderboard/providers/leaderboard_provider.dart';
import '../../profile/providers/account_status_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import '../../shared/widgets/exit_confirm_dialog.dart';

/// Layar Gameplay Mode Math Marathon.
class MathMarathonScreen extends ConsumerStatefulWidget {
  const MathMarathonScreen({super.key});

  @override
  ConsumerState<MathMarathonScreen> createState() => _MathMarathonScreenState();
}

class _MathMarathonScreenState extends ConsumerState<MathMarathonScreen> {
  static const int _kQuestionTimeoutSeconds = 5;

  int _streak = 0;
  int _questionIndex = 0;
  int _currentEffectiveLevel = 1;

  Question? _currentQuestion;
  DistractorSet? _currentDistractors;

  bool _isFeedback = false;
  bool _lastIsCorrect = false;
  int _lastRoundScore = 0;
  bool _isFinished = false;

  int _finalScore = 0;
  int _previousBestScore = 0;
  int _scoreDelta = 0;
  bool _isNewRecord = false;
  String _gameOverReason = '';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(playerProfileProvider).valueOrNull;
    _currentEffectiveLevel = profile?.currentLevel ?? 1;
    _generateNextQuestion();
  }

  void _generateNextQuestion() {
    final qGen = ref.read(questionGeneratorProvider);
    final dGen = ref.read(distractorGeneratorProvider);

    final question = qGen.generateForLevel(_currentEffectiveLevel);
    final distractors =
        dGen.generate(question, isEarlyLevel: _currentEffectiveLevel <= 5);

    setState(() {
      _currentQuestion = question;
      _currentDistractors = distractors;
      _isFeedback = false;
      _questionIndex++;
    });
  }

  void _handleAnswerSelected(int slotIndex) {
    if (_isFeedback || _isFinished || _currentDistractors == null) return;

    final isCorrect = _currentDistractors!.shuffledIndices[slotIndex] == 0;
    final sfx = ref.read(sfxServiceProvider);

    if (isCorrect) {
      sfx.play(SfxType.correct);
      _streak++;

      if (_streak % 5 == 0 && _currentEffectiveLevel < 60) {
        _currentEffectiveLevel++;
      }

      final basePoints =
          ScoringService.basePointsForLevel(_currentEffectiveLevel);
      final streakBonus = (_streak * 2).clamp(0, 40);
      final roundScore = basePoints + streakBonus;

      setState(() {
        _isFeedback = true;
        _lastIsCorrect = true;
        _lastRoundScore = roundScore;
      });

      Timer(const Duration(milliseconds: 380), () {
        if (!mounted || _isFinished) return;
        _generateNextQuestion();
      });
    } else {
      sfx.play(SfxType.wrong);
      _gameOverReason = 'Jawaban Kurang Tepat';
      setState(() {
        _isFeedback = true;
        _lastIsCorrect = false;
        _lastRoundScore = 0;
      });

      Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _finishChallenge();
      });
    }
  }

  void _handleQuestionTimeout() {
    if (_isFeedback || _isFinished) return;

    ref.read(sfxServiceProvider).play(SfxType.wrong);
    _gameOverReason = 'Kehabisan Waktu';
    setState(() {
      _isFeedback = true;
      _lastIsCorrect = false;
      _lastRoundScore = 0;
    });

    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _finishChallenge();
    });
  }

  Future<void> _finishChallenge() async {
    if (_isFinished) return;

    setState(() {
      _isFinished = true;
    });

    final profile = ref.read(playerProfileProvider).valueOrNull;
    final config = ref.read(levelBandsConfigProvider).valueOrNull;
    final startLevel = profile?.currentLevel ?? 1;
    final bandId = config?.bandForLevel(startLevel).id ?? 'basic';
    final zoneConstant = kZoneConstants[bandId] ?? 1.2;

    final scoringService = ref.read(scoringServiceProvider);
    final challengeRepo = ref.read(challengeScoreRepositoryProvider);

    final computedScore =
        scoringService.computeMarathonScore(_streak, startLevel);

    final recordRes = await challengeRepo.getRecord('marathon', bandId);
    final currentRecord =
        (recordRes is RepoSuccess<ChallengeScoreRecord?> && recordRes.value != null)
            ? recordRes.value!
            : ChallengeScoreRecord(mode: 'marathon', band: bandId);

    _previousBestScore = currentRecord.bestScore;
    _finalScore = computedScore;
    _isNewRecord = computedScore > currentRecord.bestScore;

    final delta = scoringService.computeChallengeReplayDelta(
      currentRecord: currentRecord,
      newChallengeScore: computedScore,
      zoneConstant: zoneConstant,
    );
    _scoreDelta = delta;

    final attemptResult = currentRecord.applyAttempt(computedScore);
    await challengeRepo.saveRecord(attemptResult.record);

    if (delta > 0) {
      await ref.read(playerProfileProvider.notifier).addScore(delta);

      try {
        final authRepo = ref.read(authRepositoryProvider);
        final accountState = ref.read(accountStatusProvider).valueOrNull;
        final isAuthed =
            (accountState?.hasVerifiedSession ?? false) || authRepo.isLoggedIn;
        final username = accountState?.username ?? profile?.username;

        if (isAuthed && username != null && username.trim().length >= 4) {
          final allChallengeRes = await challengeRepo.getAllRecords();
          final Map<String, dynamic> challengePayload = {};
          if (allChallengeRes
              is RepoSuccess<Map<String, ChallengeScoreRecord>>) {
            for (final entry in allChallengeRes.value.entries) {
              challengePayload[entry.key] = entry.value.toJson();
            }
          }

          final freshProfile =
              ref.read(playerProfileProvider).valueOrNull ?? profile;

          await ref.read(leaderboardRepositoryProvider).syncProfileProgress(
                username: username,
                avatarId: freshProfile?.avatarId,
                totalScore: freshProfile?.totalScore ?? 0,
                currentLevel: freshProfile?.currentLevel ?? 1,
                totalXp: freshProfile?.totalXp ?? 0,
                challengeRecords:
                    challengePayload.isNotEmpty ? challengePayload : null,
              );

          await ref.read(leaderboardRepositoryProvider).submitChallengeScore(
                mode: 'marathon',
                band: bandId,
                score: attemptResult.record.bestScore,
                streak: _streak,
                username: username,
                avatarId: freshProfile?.avatarId,
              );

          ref.invalidate(allTimeEntriesProvider);
          ref.invalidate(
              challengeEntriesProvider((mode: 'marathon', band: bandId)));
        }
      } catch (_) {
        // Abaikan error jaringan
      }
    }

    if (mounted) {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    if (_isNewRecord) {
      ref.read(sfxServiceProvider).play(SfxType.levelUp);
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ChunkyCard(
              variant: ChunkyCardVariant.woodBoard,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.colorWoodPlank,
                      border: Border.all(
                        color: AppTheme.colorWoodMedium,
                        width: AppTokens.borderWidthWood,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.colorWoodDark.withValues(alpha: 0.25),
                          offset: const Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      _isNewRecord
                          ? AppAssets.icChallengeCrown
                          : AppAssets.icChallengeTrophy,
                      width: 46,
                      height: 46,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isNewRecord) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.colorSage.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusMini),
                        border: Border.all(color: AppTheme.colorSage),
                      ),
                      child: Text(
                        'REKOR BARU!',
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.colorSage,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  Text(
                    'Game Over!',
                    style: GoogleFonts.quicksand(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.colorEspresso,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _gameOverReason,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.colorCoral,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Skor Akhir: $_finalScore Poin',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colorEspresso,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.colorVanillaCard.withValues(alpha: 0.8),
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusContainer),
                      border: Border.all(
                        color: AppTheme.colorWoodMedium.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow('Streak Bertahan', '$_streak Soal Berturut'),
                        const Divider(height: 16, thickness: 0.5),
                        _buildStatRow(
                          'Rekor Sebelumnya',
                          '$_previousBestScore Poin',
                        ),
                        if (_scoreDelta > 0) ...[
                          const Divider(height: 16, thickness: 0.5),
                          _buildStatRow(
                            'Bonus Profil',
                            '+$_scoreDelta Poin All-Time',
                            highlightColor: AppTheme.colorSage,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ChunkyButton(
                          onPressed: () {
                            Navigator.of(dialogCtx).pop();
                            context.go('/challenges');
                          },
                          backgroundColor: AppTheme.colorWoodPlank,
                          borderColor: AppTheme.colorWoodMedium,
                          shadowColor: AppTheme.colorWoodDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Pusat Tantangan',
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.colorEspresso,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChunkyButton(
                          onPressed: () {
                            Navigator.of(dialogCtx).pop();
                            context.pushReplacement('/challenges/marathon');
                          },
                          backgroundColor: AppTheme.colorSage,
                          borderColor: AppTheme.colorWoodDark,
                          shadowColor: AppTheme.colorWoodDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Coba Lagi',
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildStatRow(
    String label,
    String value, {
    Color? highlightColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.colorTaupe,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: highlightColor ?? AppTheme.colorEspresso,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && !_isFinished) {
          final shouldExit = await showExitConfirmDialog(context);
          if (shouldExit && context.mounted) {
            context.go('/challenges');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.colorSandyCanvas,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.highPassCanvasBackground,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: AppHeader(
                      title: 'Math Marathon',
                      showStats: false,
                      onBackTap: () async {
                        if (!_isFinished) {
                          final shouldExit = await showExitConfirmDialog(context);
                          if (shouldExit && context.mounted) {
                            context.go('/challenges');
                          }
                        } else {
                          context.go('/challenges');
                        }
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.colorWoodPlank,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusCard),
                        border: Border.all(
                          color: AppTheme.colorWoodMedium,
                          width: AppTokens.borderWidthDefault,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.colorWoodDark.withValues(alpha: 0.25),
                            offset: const Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: AppTheme.colorCoral,
                                size: 24,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Streak: $_streak',
                                style: GoogleFonts.quicksand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.colorEspresso,
                                ),
                              ),
                            ],
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.colorSage.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.radiusMini),
                              border: Border.all(
                                color: AppTheme.colorSage,
                                width: AppTokens.borderWidthSubtle,
                              ),
                            ),
                            child: Text(
                              'Lv. $_currentEffectiveLevel',
                              style: GoogleFonts.quicksand(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.colorSage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_currentQuestion != null && !_isFinished)
                            CountdownProgressBar(
                              duration: const Duration(
                                seconds: _kQuestionTimeoutSeconds,
                              ),
                              onTimeout: _handleQuestionTimeout,
                              resetToken: _questionIndex,
                              height: 12,
                            ),
                          const SizedBox(height: 16),

                          if (_currentQuestion != null)
                            QuestionDisplay(question: _currentQuestion!),
                          const SizedBox(height: 24),

                          if (_currentQuestion != null &&
                              _currentDistractors != null)
                            AnswerGrid(
                              question: _currentQuestion!,
                              distractors: _currentDistractors!.distractors,
                              shuffledIndices:
                                  _currentDistractors!.shuffledIndices,
                              onAnswerSelected: _handleAnswerSelected,
                              enabled: !_isFeedback && !_isFinished,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isFeedback)
              Positioned.fill(
                child: FeedbackOverlay(
                  isCorrect: _lastIsCorrect,
                  roundScore: _lastRoundScore,
                ),
              ),
          ],
        ),
      ),
    );
  }
}