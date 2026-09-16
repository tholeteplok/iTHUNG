import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/sfx_service.dart';
import '../../../domain/models/distractor.dart';
import '../../../domain/models/question.dart';
import '../../../domain/models/round_result.dart';
import '../../../domain/models/session_result.dart';
import '../../settings/providers/settings_provider.dart';
import '../state/game_session_state.dart';
import 'game_dependencies_provider.dart';
import 'level_band_theme_provider.dart';

/// Parameter inisialisasi sesi permainan.
class GameSessionArgs {
  const GameSessionArgs({
    required this.level,
    this.mode = GameMode.normal,
    this.totalRounds = 10,
  });

  final int level;
  final GameMode mode;
  final int totalRounds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSessionArgs &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          mode == other.mode &&
          totalRounds == other.totalRounds;

  @override
  int get hashCode => Object.hash(level, mode, totalRounds);
}

/// Provider StateNotifier untuk state machine sesi gameplay aktif.
final gameSessionProvider = StateNotifierProvider.autoDispose
    .family<GameSessionNotifier, GameSessionState, GameSessionArgs>((
      ref,
      args,
    ) {
      return GameSessionNotifier(ref, args);
    });

/// Notifier pengatur alur permainan (ShowQuestion -> Active -> Feedback -> SessionEnded).
///
/// Terintegrasi dengan [WidgetsBindingObserver] untuk membekukan sisa waktu saat
/// aplikasi masuk background (§3.1 state management spec).
class GameSessionNotifier extends StateNotifier<GameSessionState>
    with WidgetsBindingObserver {
  GameSessionNotifier(this._ref, this.args)
    : super(
        ShowQuestionState(
          _ref.read(questionGeneratorProvider).generateForLevel(args.level),
        ),
      ) {
    WidgetsBinding.instance.addObserver(this);
    _sessionId =
        's_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4().substring(0, 4)}';
    _sessionStartedAt = DateTime.now();
    _startRound(isInitial: true);
  }

  final Ref _ref;
  final GameSessionArgs args;

  late final String _sessionId;
  late final DateTime _sessionStartedAt;

  Timer? _showQuestionTimer;
  Timer? _feedbackTimer;

  int _roundIndex = 0;
  int _streakCorrect = 0;
  int _confidenceScore = 0;

  final List<RoundResult> _completedRounds = [];
  final Set<String> _distinctFacts = {};
  int _factsMovedUp = 0;

  DateTime? _activeRoundStartTime;

  /// Daftar hasil ronde yang telah diselesaikan pada sesi ini.
  List<RoundResult> get completedRounds => List.unmodifiable(_completedRounds);

  /// Nomor ronde berjalan (1-based) untuk HUD game.
  int get currentRound => (_roundIndex + 1).clamp(1, args.totalRounds);

  /// Skor berjalan sesi untuk HUD game.
  int get runningScore =>
      _completedRounds.fold<int>(0, (sum, r) => sum + r.roundScore);

  /// Streak benar beruntun saat ini untuk HUD/feedback.
  int get currentStreak => _streakCorrect;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final current = this.state;
    if (state == AppLifecycleState.paused && current is ActiveState) {
      pause();
    } else if (state == AppLifecycleState.resumed && current is PausedState) {
      resume();
    }
  }

  /// Menjeda permainan (mis. saat app background atau dialog konfirmasi dibuka).
  void pause() {
    final current = state;
    if (current is ActiveState) {
      // Hitung sisa waktu yang tepat saat dipause
      final elapsed = _activeRoundStartTime != null
          ? DateTime.now().difference(_activeRoundStartTime!).inMilliseconds
          : 0;
      final remaining = (current.totalTimeMs - elapsed).clamp(
        0,
        current.totalTimeMs,
      );

      state = PausedState(current.copyWith(timeRemainingMs: remaining));
    }
  }

  /// Melanjutkan kembali permainan dari state pause dengan sisa waktu yang sama persis.
  void resume() {
    final current = state;
    if (current is PausedState) {
      final elapsedBeforePause =
          current.pausedFrom.totalTimeMs - current.pausedFrom.timeRemainingMs;
      _activeRoundStartTime =
          DateTime.now().subtract(Duration(milliseconds: elapsedBeforePause));
      state = current.pausedFrom;
    }
  }

  /// Memulai ronde baru: langsung aktifkan soal dan opsi jawaban secara serentak (0ms delay).
  void _startRound({bool isInitial = false}) {
    _showQuestionTimer?.cancel();
    _feedbackTimer?.cancel();

    final qGen = _ref.read(questionGeneratorProvider);
    final question = isInitial && state is ShowQuestionState
        ? (state as ShowQuestionState).question
        : qGen.generateForLevel(args.level);

    _activateRound(question);
  }

  /// Mengaktifkan timer ronde dan grid pilihan jawaban.
  void _activateRound(Question question) {
    final distractorGen = _ref.read(distractorGeneratorProvider);
    final dda = _ref.read(ddaEngineProvider);

    final distractorSet = distractorGen.generate(
      question,
      isEarlyLevel: args.level <= 5,
    );

    // Durasi timer dasar disesuaikan oleh DDA Layer 1 (§6.1)
    final bandsConfig = _ref.read(levelBandsConfigProvider).valueOrNull;
    final baseSec = bandsConfig?.bandForLevel(args.level).timerBaseSec ?? 6.0;
    final adjustedSec = dda.adjustTimerDuration(
      baseSec: baseSec,
      confidenceScore: _confidenceScore,
    );
    final totalMs = (adjustedSec * 1000).round();

    _activeRoundStartTime = DateTime.now();

    state = ActiveState(
      question: question,
      distractors: distractorSet.distractors,
      shuffledIndices: distractorSet.shuffledIndices,
      timeRemainingMs: totalMs,
      totalTimeMs: totalMs,
      streakCorrect: _streakCorrect,
      confidenceScore: _confidenceScore,
    );
  }

  /// Memproses jawaban yang dipilih pemain pada slot [selectedIndex] (0..3).
  void submitAnswer(int selectedIndex) {
    final current = state;
    if (current is! ActiveState) return;

    final responseTimeMs = _activeRoundStartTime != null
        ? DateTime.now().difference(_activeRoundStartTime!).inMilliseconds
        : 1500;

    // Slot 0 pada virtual array selalu jawaban benar
    final isCorrect = current.shuffledIndices[selectedIndex] == 0;
    final ErrorType? errorType = isCorrect
        ? null
        : (current.shuffledIndices[selectedIndex] - 1 <
                  current.distractors.length
              ? current
                    .distractors[current.shuffledIndices[selectedIndex] - 1]
                    .errorType
              : ErrorType.other);

    _processAnswerResult(
      current: current,
      isCorrect: isCorrect,
      selectedAnswer: selectedIndex,
      responseTimeMs: responseTimeMs,
      errorType: errorType,
    );
  }

  /// Memproses kejadian saat timer habis (timeout).
  void handleTimeout() {
    final current = state;
    if (current is! ActiveState) return;

    _processAnswerResult(
      current: current,
      isCorrect: false,
      selectedAnswer: null,
      responseTimeMs: current.totalTimeMs,
      errorType: null,
    );
  }

  void _processAnswerResult({
    required ActiveState current,
    required bool isCorrect,
    required int? selectedAnswer,
    required int responseTimeMs,
    required ErrorType? errorType,
  }) {
    final question = current.question;
    final scoring = _ref.read(scoringServiceProvider);
    final dda = _ref.read(ddaEngineProvider);
    final masteryService = _ref.read(masteryUpdateServiceProvider);

    // SFX feedback instan
    final sfx = _ref.read(sfxServiceProvider);
    if (isCorrect) {
      sfx.play(SfxType.correct);
    } else {
      sfx.play(SfxType.wrong);
    }

    // 1. Update streak & confidence score
    if (isCorrect) {
      _streakCorrect++;
    } else {
      _streakCorrect = 0;
    }

    _confidenceScore = dda.updateConfidenceScore(
      currentConfidenceScore: _confidenceScore,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      totalTimeMs: current.totalTimeMs,
    );

    // 2. Hitung skor ronde
    final timeLeftMs = (current.totalTimeMs - responseTimeMs).clamp(
      0,
      current.totalTimeMs,
    );
    final scoreResult = scoring.computeRoundScore(
      level: args.level,
      timeLeftMs: timeLeftMs,
      timeTotalMs: current.totalTimeMs,
      streakCorrect: _streakCorrect,
      isCorrect: isCorrect,
    );

    // 3. Catat ke Mastery Bank secara background
    _distinctFacts.add(question.factKey);
    masteryService
        .onAnswerSubmit(
          factKey: question.factKey,
          isCorrect: isCorrect,
          responseTimeMs: responseTimeMs,
          errorType: errorType,
        )
        .then((record) {
          if (record.box > 1 && isCorrect) {
            _factsMovedUp++;
          }
        });

    // 4. Rekam data ronde ini
    final int answerValue;
    if (selectedAnswer != null) {
      final virtualIdx = current.shuffledIndices[selectedAnswer];
      answerValue = virtualIdx == 0
          ? current.question.correctAnswer
          : current.distractors[virtualIdx - 1].value;
    } else {
      answerValue = -1; // timeout
    }

    _completedRounds.add(
      RoundResult(
        questionId: question.id,
        factKey: question.factKey,
        selectedAnswer: answerValue,
        isCorrect: isCorrect,
        errorType: errorType,
        responseTimeMs: responseTimeMs,
        timeTotalMs: current.totalTimeMs,
        roundScore: scoreResult.roundScore,
        scoreBreakdown: scoreResult.breakdown,
        timestamp: DateTime.now(),
      ),
    );

    // 5. Pindah ke Feedback state selama ±400ms
    state = FeedbackState(
      isCorrect: isCorrect,
      selectedAnswer: selectedAnswer,
      question: question,
      distractors: current.distractors,
      shuffledIndices: current.shuffledIndices,
      roundScore: scoreResult.roundScore,
    );

    _roundIndex++;

    _feedbackTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_roundIndex >= args.totalRounds) {
        _finishSession();
      } else {
        _startRound();
      }
    });
  }

  /// Mengakhiri sesi permainan dan menghitung hasil akhir.
  void _finishSession() {
    final scoring = _ref.read(scoringServiceProvider);
    final totalScore = _completedRounds.fold<int>(
      0,
      (sum, r) => sum + r.roundScore,
    );
    final correctCount = _completedRounds.where((r) => r.isCorrect).length;
    final accuracy = _completedRounds.isNotEmpty
        ? correctCount / _completedRounds.length
        : 0.0;
    final avgTime = _completedRounds.isNotEmpty
        ? _completedRounds.fold<int>(0, (sum, r) => sum + r.responseTimeMs) ~/
              _completedRounds.length
        : 0;

    final xpResult = scoring.computeSessionXp(
      distinctFactsPracticed: _distinctFacts.length,
      factsMovedUpABox: _factsMovedUp,
      sessionCompleted: true,
    );

    final sessionResult = SessionResult(
      sessionId: _sessionId,
      mode: args.mode,
      startedAt: _sessionStartedAt,
      endedAt: DateTime.now(),
      levelReached: args.level,
      rounds: _completedRounds,
      totalScore: totalScore,
      accuracy: accuracy,
      avgResponseTimeMs: avgTime,
      bestStreak: _streakCorrect,
      xpEarned: xpResult.totalXp,
      xpBreakdown: xpResult.breakdown,
    );

    // Simpan hasil sesi ke repository
    _ref.read(sessionRepositoryProvider).saveSession(sessionResult);

    state = SessionEndedState(sessionResult);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _showQuestionTimer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }
}
