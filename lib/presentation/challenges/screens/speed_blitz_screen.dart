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

/// Layar Gameplay Mode Speed Blitz.
///
/// Mekanisme:
/// - Waktu tunggal 60 detik (Single Master Clock).
/// - Tidak ada batasan waktu / timeout per soal.
/// - Soal terus berlanjut tanpa henti selama waktu 60 detik masih tersisa.
class SpeedBlitzScreen extends ConsumerStatefulWidget {
  const SpeedBlitzScreen({super.key});

  @override
  ConsumerState<SpeedBlitzScreen> createState() => _SpeedBlitzScreenState();
}

class _SpeedBlitzScreenState extends ConsumerState<SpeedBlitzScreen>
    with SingleTickerProviderStateMixin {
  static const int _kTotalDurationSeconds = 60;

  late final AnimationController _clockController;

  final List<bool> _answerResults = [];

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
  int? _lastTickedSecond;

  @override
  void initState() {
    super.initState();
    _clockController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _kTotalDurationSeconds),
    )
      ..addListener(_onClockTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _finishChallenge();
        }
      });

    _clockController.forward();
    _generateNextQuestion();
  }

  void _onClockTick() {
    if (!mounted || _isFinished) return;
    final remaining = _secondsRemaining;

    // Picu audio ketegangan di 10 detik terakhir (1x per detik)
    if (remaining <= 10 && remaining > 0 && remaining != _lastTickedSecond) {
      _lastTickedSecond = remaining;
      final sfx = ref.read(sfxServiceProvider);
      if (remaining <= 3) {
        sfx.play(SfxType.timerWarning);
      } else {
        sfx.play(SfxType.timerTick);
      }
    }
  }

  @override
  void dispose() {
    _clockController.removeListener(_onClockTick);
    _clockController.dispose();
    super.dispose();
  }

  int get _secondsRemaining {
    final remaining = ((1.0 - _clockController.value) * _kTotalDurationSeconds).ceil();
    return remaining.clamp(0, _kTotalDurationSeconds);
  }

  void _generateNextQuestion() {
    if (_isFinished) return;

    final profile = ref.read(playerProfileProvider).valueOrNull;
    final level = profile?.currentLevel ?? 1;

    final qGen = ref.read(questionGeneratorProvider);
    final dGen = ref.read(distractorGeneratorProvider);

    final question = qGen.generateForLevel(level);
    final distractors = dGen.generate(question, isEarlyLevel: level <= 5);

    setState(() {
      _currentQuestion = question;
      _currentDistractors = distractors;
      _isFeedback = false;
    });
  }

  void _handleAnswerSelected(int slotIndex) {
    if (_isFeedback || _isFinished || _currentDistractors == null) return;

    final isCorrect = _currentDistractors!.shuffledIndices[slotIndex] == 0;
    _answerResults.add(isCorrect);

    // Mainkan sound effect respons jawaban
    final sfx = ref.read(sfxServiceProvider);
    if (isCorrect) {
      sfx.play(SfxType.correct);
    } else {
      sfx.play(SfxType.wrong);
    }

    final profile = ref.read(playerProfileProvider).valueOrNull;
    final level = profile?.currentLevel ?? 1;
    final roundScore =
        isCorrect ? ScoringService.basePointsForLevel(level) : 0;

    setState(() {
      _isFeedback = true;
      _lastIsCorrect = isCorrect;
      _lastRoundScore = roundScore;
    });

    Timer(const Duration(milliseconds: 300), () {
      if (!mounted || _isFinished) return;
      _generateNextQuestion();
    });
  }

  Future<void> _finishChallenge() async {
    if (_isFinished) return;

    _clockController.removeListener(_onClockTick);

    setState(() {
      _isFinished = true;
    });

    final profile = ref.read(playerProfileProvider).valueOrNull;
    final config = ref.read(levelBandsConfigProvider).valueOrNull;
    final currentLevel = profile?.currentLevel ?? 1;
    final bandId = config?.bandForLevel(currentLevel).id ?? 'basic';
    final zoneConstant = kZoneConstants[bandId] ?? 1.2;

    final scoringService = ref.read(scoringServiceProvider);
    final challengeRepo = ref.read(challengeScoreRepositoryProvider);

    final computedScore =
        scoringService.computeBlitzScore(_answerResults, currentLevel);

    final recordRes = await challengeRepo.getRecord('blitz', bandId);
    final currentRecord =
        (recordRes is RepoSuccess<ChallengeScoreRecord?> && recordRes.value != null)
            ? recordRes.value!
            : ChallengeScoreRecord(mode: 'blitz', band: bandId);

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

          final correctCount = _answerResults.where((r) => r).length;
          await ref.read(leaderboardRepositoryProvider).submitChallengeScore(
                mode: 'blitz',
                band: bandId,
                score: attemptResult.record.bestScore,
                correctCount: correctCount,
                username: username,
                avatarId: freshProfile?.avatarId,
              );

          ref.invalidate(allTimeEntriesProvider);
          ref.invalidate(
              challengeEntriesProvider((mode: 'blitz', band: bandId)));
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
    final correctCount = _answerResults.where((r) => r).length;
    final totalAnswered = _answerResults.length;
    final accuracy = totalAnswered > 0
        ? ((correctCount / totalAnswered) * 100).round()
        : 0;

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
                          : AppAssets.icChallengeLightning,
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
                    'Waktu Habis!',
                    style: GoogleFonts.quicksand(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.colorEspresso,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Skor Akhir: $_finalScore Poin',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colorCoral,
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
                        _buildStatRow('Jawaban Benar', '$correctCount dari $totalAnswered soal'),
                        const Divider(height: 16, thickness: 0.5),
                        _buildStatRow('Akurasi', '$accuracy%'),
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
                            context.pushReplacement('/challenges/blitz');
                          },
                          backgroundColor: AppTheme.colorCoral,
                          borderColor: AppTheme.colorWoodDark,
                          shadowColor: AppTheme.colorWoodDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Main Lagi',
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
    final correctCount = _answerResults.where((r) => r).length;

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
                      title: 'Speed Blitz',
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

                  // HUD Master Bar: Countdown 60s & Soal Benar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedBuilder(
                      animation: _clockController,
                      builder: (context, _) {
                        final remaining = _secondsRemaining;
                        final isLowTime = remaining <= 10;
                        final progress = (1.0 - _clockController.value).clamp(0.0, 1.0);

                        return Container(
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer_rounded,
                                        color: isLowTime
                                            ? AppTheme.colorCoral
                                            : AppTheme.colorEspresso,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${remaining}s',
                                        style: AppTheme.statNumberStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: isLowTime
                                              ? AppTheme.colorCoral
                                              : AppTheme.colorEspresso,
                                        ),
                                      ),
                                    ],
                                  ),

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppTheme.colorSage,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$correctCount Benar',
                                        style: GoogleFonts.quicksand(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.colorEspresso,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Smooth 60-Second Master Progress Bar
                              Container(
                                height: 8,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.colorWoodMedium
                                      .withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isLowTime
                                          ? AppTheme.colorCoral
                                          : AppTheme.colorSage,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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