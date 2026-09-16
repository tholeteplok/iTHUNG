import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Overlay feedback animasi saat jawaban disubmit (benar/salah/timeout).
///
/// Tampil selama [AppTokens.feedbackDuration] (±400ms) untuk memberikan
/// kepuasan sensorik instan tanpa menahan ritme permainan.
class FeedbackOverlay extends StatelessWidget {
  const FeedbackOverlay({
    super.key,
    required this.isCorrect,
    required this.roundScore,
    this.isTimeout = false,
    this.streak = 0,
  });

  final bool isCorrect;
  final int roundScore;
  final bool isTimeout;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final iconColor = isCorrect ? AppTheme.colorSage : AppTheme.colorCoral;
    final icon = isCorrect
        ? AppIcons.answerCorrect
        : (isTimeout ? AppIcons.answerTimeout : AppIcons.answerWrong);
    final title = isCorrect
        ? (streak >= 3 ? 'Mantap! 🔥x$streak' : 'Benar!')
        : (isTimeout ? 'Waktu Habis!' : 'Ups, Salah!');

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.colorVanillaCard,
            borderRadius: BorderRadius.circular(AppTokens.radiusContainer),
            border: Border.all(color: iconColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.25),
                offset: const Offset(0, 6),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: iconColor),
                  if (isCorrect && roundScore > 0) ...[
                    const SizedBox(width: 12),
                    Text(
                      '+$roundScore',
                      style: AppTheme.statNumberStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorEspresso,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
