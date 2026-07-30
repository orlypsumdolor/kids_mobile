import 'package:flutter/material.dart';
import '../../domain/entities/child.dart';
import '../../core/theme/app_theme.dart';

class ChildSelectionCard extends StatelessWidget {
  final Child child;
  final bool isSelected;
  final VoidCallback onSelectionChanged;

  const ChildSelectionCard({
    super.key,
    required this.child,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final alreadyIn = child.currentlyCheckedIn;
    final badge = AppTheme.ageGroupBadge(child.ageGroup);
    final border = isSelected ? AppTheme.navy : AppTheme.hairline;
    final bg = isSelected ? const Color(0xFFF2F6FD) : AppTheme.surface;

    return Opacity(
      opacity: alreadyIn ? 0.55 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: InkWell(
          onTap: onSelectionChanged,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Container(
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: border, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.navy : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isSelected ? AppTheme.navy : const Color(0xFFC9D0DA),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        child.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badge.bg,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusPill),
                            ),
                            child: Text(
                              AppTheme.ageGroupLabel(child.ageGroup)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: badge.fg,
                              ),
                            ),
                          ),
                          Text(
                            '${child.ageInYears} yrs',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (alreadyIn)
                  const _FlagPill(
                    label: 'Already in',
                    bg: AppTheme.chipNeutralBg,
                    fg: AppTheme.textTertiary,
                    border: AppTheme.inputBorder,
                  )
                else if (child.hasNotes)
                  const _FlagPill(
                    label: 'Note',
                    bg: AppTheme.warningBg,
                    fg: AppTheme.warningText,
                    border: AppTheme.warningBorder,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlagPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color border;

  const _FlagPill({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
