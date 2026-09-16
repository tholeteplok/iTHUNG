import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/update_download_provider.dart';
import 'update_dialog.dart';

/// Widget mengambang (*Floating Pill*) bergaya Cozy Woodwork yang muncul
/// ketika proses unduhan pembaruan diminimalkan atau berstatus siap pasang.
class FloatingUpdatePill extends ConsumerWidget {
  const FloatingUpdatePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(updateDownloadProvider);

    if (!downloadState.hasActiveTask &&
        downloadState.status != UpdateDownloadStatus.error) {
      return const SizedBox.shrink();
    }

    final isCompleted = downloadState.isCompleted;
    final isError = downloadState.status == UpdateDownloadStatus.error;
    final pct = (downloadState.progress * 100).toInt();

    final Color accentColor = isCompleted
        ? AppTheme.colorSage
        : (isError ? AppTheme.colorCoral : AppTheme.colorHoney);

    final String labelText = isCompleted
        ? 'Siap Pasang 🚀'
        : (isError ? 'Unduhan Dijeda' : 'Update $pct%');

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          if (isCompleted && downloadState.info != null) {
            handleAppInstall(
              context: context,
              ref: ref,
              info: downloadState.info!,
            );
          } else if (downloadState.info != null) {
            ref.read(updateDownloadProvider.notifier).maximize();
            showUpdateProgressDialog(
              context: context,
              info: downloadState.info!,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.colorWoodPlank,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(
              color: AppTheme.colorWoodBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.colorWoodDark.withValues(alpha: 0.22),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.50),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isCompleted
                        ? AppIcons.check
                        : (isError ? AppIcons.warning : AppIcons.download),
                    size: 15,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelText,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.colorEspresso,
                    ),
                  ),
                  if (!isCompleted && !isError) ...[
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 70,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        child: LinearProgressIndicator(
                          value: downloadState.progress > 0
                              ? downloadState.progress
                              : null,
                          backgroundColor:
                              AppTheme.colorWoodBorder.withValues(alpha: 0.4),
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      isCompleted ? 'Ketuk untuk pasang' : 'Ketuk untuk coba lagi',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.colorTaupe,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.colorTaupe,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
