import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/distractor.dart';
import '../../../domain/models/question.dart';
import '../../shared/widgets/chunky_button.dart';

/// Grid pilihan jawaban 2×2 dengan tombol bergaya chunky.
///
/// Mengacu pada:
/// - `math-speed-game-core-gameplay-spec.md` §3.5 (posisi diacak via shuffledIndices)
/// - `math-speed-game-error-handling-spec.md` §4 (debounce tap ganda cepat)
class AnswerGrid extends StatefulWidget {
  const AnswerGrid({
    super.key,
    required this.question,
    required this.distractors,
    required this.shuffledIndices,
    required this.onAnswerSelected,
    this.enabled = true,
    this.selectedSlot,
    this.correctSlot,
    this.showResult = false,
  });

  final Question question;
  final List<Distractor> distractors;
  final List<int> shuffledIndices;
  final ValueChanged<int> onAnswerSelected;
  final bool enabled;
  final int? selectedSlot;
  final int? correctSlot;
  final bool showResult;

  @override
  State<AnswerGrid> createState() => _AnswerGridState();
}

class _AnswerGridState extends State<AnswerGrid> {
  bool _hasTapped = false;

  @override
  void didUpdateWidget(covariant AnswerGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _hasTapped = false; // Reset debounce untuk ronde baru
    }
  }

  void _handleTap(int slotIndex) {
    if (_hasTapped || !widget.enabled) return;
    setState(() => _hasTapped = true);
    widget.onAnswerSelected(slotIndex);
  }

  @override
  Widget build(BuildContext context) {
    // Virtual array: [correct_answer, ...distractors.map((d) => d.value)]
    final values = [
      widget.question.correctAnswer,
      ...widget.distractors.map((d) => d.value),
    ];

    return Column(
      children: [
        // Baris 1: Opsi 0 dan Opsi 1
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildChoiceButton(0, values)),
              const SizedBox(width: 14),
              Expanded(child: _buildChoiceButton(1, values)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Baris 2: Opsi 2 dan Opsi 3
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildChoiceButton(2, values)),
              const SizedBox(width: 14),
              Expanded(child: _buildChoiceButton(3, values)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton(int slotIndex, List<int> values) {
    if (slotIndex >= widget.shuffledIndices.length) {
      return const SizedBox.shrink();
    }

    final valueIndex = widget.shuffledIndices[slotIndex];
    final displayValue = valueIndex < values.length ? values[valueIndex] : 0;

    final isCorrectSlot =
        widget.showResult && widget.correctSlot == slotIndex;
    final isWrongSlot = widget.showResult &&
        widget.selectedSlot == slotIndex &&
        widget.correctSlot != slotIndex;

    final bg = isCorrectSlot
        ? AppTheme.colorSage
        : isWrongSlot
            ? AppTheme.colorCoral
            : AppTheme.colorVanillaCard;
    final fg = (isCorrectSlot || isWrongSlot)
        ? Colors.white
        : AppTheme.colorEspresso;

    final button = ChunkyButton(
      enabled: widget.enabled && !_hasTapped,
      onPressed: () => _handleTap(slotIndex),
      backgroundColor: bg,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        '$displayValue',
        style: AppTheme.answerButtonStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );

    // Stagger entry 50ms per slot ala game.
    final staggered = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: Duration(milliseconds: 180 + slotIndex * 50),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: button,
    );

    if (!isWrongSlot) return staggered;

    // Shake untuk jawaban salah.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      builder: (context, t, child) {
        final dx = (t < 1.0) ? 8 * (1 - t) * sin(t * 18.84) : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: staggered,
    );
  }
}
