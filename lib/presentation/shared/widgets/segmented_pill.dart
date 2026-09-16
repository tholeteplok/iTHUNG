import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

class SegmentedPill extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.colorInnerCream,
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        border: Border.all(
          color: AppTheme.colorTranslucentBorder,
          width: AppTokens.borderWidthSubtle,
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.colorTabActive
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: selected
                      ? Border.all(
                          color: AppTheme.colorTranslucentBorderFocus,
                          width: AppTokens.borderWidthSubtle,
                        )
                      : null,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppTheme.colorWoodDark.withValues(alpha: 0.08),
                            offset: const Offset(0, 2),
                            blurRadius: 3,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i].toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: selected
                        ? AppTheme.colorEspresso
                        : AppTheme.colorTaupe,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}