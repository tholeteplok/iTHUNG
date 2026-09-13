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
  });

  final Question question;
  final List<Distractor> distractors;
  final List<int> shuffledIndices;
  final ValueChanged<int> onAnswerSelected;
  final bool enabled;

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

    return ChunkyButton(
      enabled: widget.enabled && !_hasTapped,
      onPressed: () => _handleTap(slotIndex),
      backgroundColor: AppTheme.colorWoodPlank,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        '$displayValue',
        style: AppTheme.answerButtonStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppTheme.colorEspresso,
        ),
      ),
    );
  }
}
