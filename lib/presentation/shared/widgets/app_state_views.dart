import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import 'chunky_button.dart';
import 'chunky_card.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message = 'Menyiapkan petualangan...'});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ChunkyCard(
        variant: ChunkyCardVariant.vanillaSoft,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 72,
            height: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusBar),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.2, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v == 1.0 ? null : v,
                  backgroundColor: AppTheme.colorInnerCream,
                  valueColor: const AlwaysStoppedAnimation(
                    AppTheme.colorHoney,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.colorEspresso,
            ),
          ),
        ]),
      ),
    );
  }
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ChunkyCard(
          variant: ChunkyCardVariant.vanillaSoft,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.colorDangerSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.colorCoral,
                  width: AppTokens.borderWidthSubtle,
                ),
              ),
              child: const Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 30,
                color: AppTheme.colorCoral,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ups, jalur terputus!',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.colorEspresso,
              ),
            ),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorTaupe,
                )),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ChunkyButton(
                  onPressed: onRetry,
                  backgroundColor: AppTheme.colorHoney,
                  child: Text('Coba Lagi',
                      style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.colorEspresso))),
            ],
          ]),
        ),
      ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({super.key, required this.message, this.icon = Icons.inbox_rounded});
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ChunkyCard(
          variant: ChunkyCardVariant.vanillaSoft,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.colorInnerCream,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.colorTranslucentBorder,
                  width: AppTokens.borderWidthSubtle,
                ),
              ),
              child: Icon(icon, size: 30, color: AppTheme.colorTaupe),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada jejak!',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.colorEspresso,
              ),
            ),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorTaupe,
                )),
          ]),
        ),
      ),
    );
  }
}